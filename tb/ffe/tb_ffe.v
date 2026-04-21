`timescale 1ns/1ps

module tb_ffe;

    // =========================================================
    // Parameters
    // =========================================================
    parameter integer DIN_W   = 10;
    parameter integer COEF_W  = 8;
    parameter integer TAPS    = 8;
    parameter integer PROD_W  = DIN_W + COEF_W;
    parameter integer ACC_W   = PROD_W + $clog2(TAPS);
    parameter integer DOUT_W  = ACC_W;

    parameter integer CLK_PER = 10;

    // =========================================================
    // DUT signals
    // =========================================================
    reg                             clk;
    reg                             rst_n;
    reg                             en;

    reg  signed [DIN_W-1:0]         din0;
    reg  signed [DIN_W-1:0]         din1;
    reg  signed [DIN_W-1:0]         din2;
    reg  signed [DIN_W-1:0]         din3;
    reg                             din_valid;

    reg         [TAPS*COEF_W-1:0]   coeff_bus;

    wire signed [DOUT_W-1:0]        dout0;
    wire signed [DOUT_W-1:0]        dout1;
    wire signed [DOUT_W-1:0]        dout2;
    wire signed [DOUT_W-1:0]        dout3;
    wire                            dout_valid;

    // =========================================================
    // DUT
    // =========================================================
    FFE #(
        .DIN_W  (DIN_W),
        .COEF_W (COEF_W),
        .TAPS   (TAPS),
        .PROD_W (PROD_W),
        .ACC_W  (ACC_W),
        .DOUT_W (DOUT_W)
    ) u_ffe (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (en),
        .din0       (din0),
        .din1       (din1),
        .din2       (din2),
        .din3       (din3),
        .din_valid  (din_valid),
        .coeff_bus  (coeff_bus),
        .dout0      (dout0),
        .dout1      (dout1),
        .dout2      (dout2),
        .dout3      (dout3),
        .dout_valid (dout_valid)
    );

    // =========================================================
    // Clock generation
    // =========================================================
    initial
    begin
        clk = 1'b0;
        forever #(CLK_PER/2) clk = ~clk;
    end

    // =========================================================
    // Testbench storage
    // =========================================================
    reg signed [DIN_W-1:0] tb_coef     [0:TAPS-1];

    reg signed [DIN_W-1:0] hist0       [0:TAPS-2];
    reg signed [DIN_W-1:0] hist1       [0:TAPS-2];
    reg signed [DIN_W-1:0] hist2       [0:TAPS-2];
    reg signed [DIN_W-1:0] hist3       [0:TAPS-2];

    reg signed [ACC_W-1:0] golden0_now;
    reg signed [ACC_W-1:0] golden1_now;
    reg signed [ACC_W-1:0] golden2_now;
    reg signed [ACC_W-1:0] golden3_now;

    reg signed [ACC_W-1:0] golden0_d1;
    reg signed [ACC_W-1:0] golden1_d1;
    reg signed [ACC_W-1:0] golden2_d1;
    reg signed [ACC_W-1:0] golden3_d1;

    reg signed [ACC_W-1:0] golden0_d2;
    reg signed [ACC_W-1:0] golden1_d2;
    reg signed [ACC_W-1:0] golden2_d2;
    reg signed [ACC_W-1:0] golden3_d2;

    reg                    golden_valid_d1;
    reg                    golden_valid_d2;

    integer i;
    integer error_cnt;

    // =========================================================
    // Pack coefficient bus
    // coeff_bus[i*COEF_W +: COEF_W] = tb_coef[i]
    // =========================================================
    task pack_coeff_bus;
        integer idx;
        begin
            coeff_bus = {(TAPS*COEF_W){1'b0}};
            for (idx = 0; idx < TAPS; idx = idx + 1)
            begin
                coeff_bus[idx*COEF_W +: COEF_W] = tb_coef[idx][COEF_W-1:0];
            end
        end
    endtask

    // =========================================================
    // Initialize coefficient values
    // NOTE:
    // Keep coefficients small enough to fit in COEF_W
    // =========================================================
    task init_coeff;
        begin
            tb_coef[0] =  8;
            tb_coef[1] = -3;
            tb_coef[2] =  2;
            tb_coef[3] =  1;
            tb_coef[4] = -1;
            tb_coef[5] =  2;
            tb_coef[6] = -2;
            tb_coef[7] =  1;
        end
    endtask

    // =========================================================
    // Initialize history buffers
    // =========================================================
    task init_history;
        integer idx;
        begin
            if (TAPS > 1)
            begin
                for (idx = 0; idx < TAPS-1; idx = idx + 1)
                begin
                    hist0[idx] = {DIN_W{1'b0}};
                    hist1[idx] = {DIN_W{1'b0}};
                    hist2[idx] = {DIN_W{1'b0}};
                    hist3[idx] = {DIN_W{1'b0}};
                end
            end
        end
    endtask

    // =========================================================
    // Apply one valid input sample
    // =========================================================
    task apply_input(
        input signed [DIN_W-1:0] in0,
        input signed [DIN_W-1:0] in1,
        input signed [DIN_W-1:0] in2,
        input signed [DIN_W-1:0] in3
    );
        begin
            @(negedge clk);
            din0      = in0;
            din1      = in1;
            din2      = in2;
            din3      = in3;
            din_valid = 1'b1;
        end
    endtask

    // =========================================================
    // Insert one bubble (din_valid = 0)
    // =========================================================
    task apply_bubble;
        begin
            @(negedge clk);
            din0      = {DIN_W{1'b0}};
            din1      = {DIN_W{1'b0}};
            din2      = {DIN_W{1'b0}};
            din3      = {DIN_W{1'b0}};
            din_valid = 1'b0;
        end
    endtask

    // =========================================================
    // Golden model
    // Same FIR equation as DUT:
    // y[n] = c0*x[n] + c1*x[n-1] + ... + c(TAPS-1)*x[n-(TAPS-1)]
    // =========================================================
    always @(*)
    begin
        golden0_now = {ACC_W{1'b0}};
        golden1_now = {ACC_W{1'b0}};
        golden2_now = {ACC_W{1'b0}};
        golden3_now = {ACC_W{1'b0}};

        golden0_now = golden0_now + din0 * tb_coef[0];
        golden1_now = golden1_now + din1 * tb_coef[0];
        golden2_now = golden2_now + din2 * tb_coef[0];
        golden3_now = golden3_now + din3 * tb_coef[0];

        for (i = 1; i < TAPS; i = i + 1)
        begin
            golden0_now = golden0_now + hist0[i-1] * tb_coef[i];
            golden1_now = golden1_now + hist1[i-1] * tb_coef[i];
            golden2_now = golden2_now + hist2[i-1] * tb_coef[i];
            golden3_now = golden3_now + hist3[i-1] * tb_coef[i];
        end
    end

    // =========================================================
    // Golden model pipeline and history update
    // DUT latency = 2 cycles
    // =========================================================
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            golden0_d1     <= {ACC_W{1'b0}};
            golden1_d1     <= {ACC_W{1'b0}};
            golden2_d1     <= {ACC_W{1'b0}};
            golden3_d1     <= {ACC_W{1'b0}};
            golden0_d2     <= {ACC_W{1'b0}};
            golden1_d2     <= {ACC_W{1'b0}};
            golden2_d2     <= {ACC_W{1'b0}};
            golden3_d2     <= {ACC_W{1'b0}};
            golden_valid_d1 <= 1'b0;
            golden_valid_d2 <= 1'b0;
        end
        else if (en)
        begin
            golden_valid_d1 <= din_valid;
            golden_valid_d2 <= golden_valid_d1;

            if (din_valid)
            begin
                golden0_d1 <= golden0_now;
                golden1_d1 <= golden1_now;
                golden2_d1 <= golden2_now;
                golden3_d1 <= golden3_now;

                if (TAPS > 1)
                begin
                    for (i = TAPS-2; i > 0; i = i - 1)
                    begin
                        hist0[i] <= hist0[i-1];
                        hist1[i] <= hist1[i-1];
                        hist2[i] <= hist2[i-1];
                        hist3[i] <= hist3[i-1];
                    end

                    hist0[0] <= din0;
                    hist1[0] <= din1;
                    hist2[0] <= din2;
                    hist3[0] <= din3;
                end
            end

            golden0_d2 <= golden0_d1;
            golden1_d2 <= golden1_d1;
            golden2_d2 <= golden2_d1;
            golden3_d2 <= golden3_d1;
        end
    end

    // =========================================================
    // Output checker
    // =========================================================
    always @(posedge clk)
    begin
        if (rst_n && en && dout_valid)
        begin
            if (!golden_valid_d2)
            begin
                $display("[%0t] ERROR: dout_valid asserted but golden_valid_d2 is 0", $time);
                error_cnt = error_cnt + 1;
            end

            if (dout0 !== golden0_d2[DOUT_W-1:0])
            begin
                $display("[%0t] ERROR: dout0 mismatch, got=%0d expected=%0d", $time, dout0, golden0_d2[DOUT_W-1:0]);
                error_cnt = error_cnt + 1;
            end

            if (dout1 !== golden1_d2[DOUT_W-1:0])
            begin
                $display("[%0t] ERROR: dout1 mismatch, got=%0d expected=%0d", $time, dout1, golden1_d2[DOUT_W-1:0]);
                error_cnt = error_cnt + 1;
            end

            if (dout2 !== golden2_d2[DOUT_W-1:0])
            begin
                $display("[%0t] ERROR: dout2 mismatch, got=%0d expected=%0d", $time, dout2, golden2_d2[DOUT_W-1:0]);
                error_cnt = error_cnt + 1;
            end

            if (dout3 !== golden3_d2[DOUT_W-1:0])
            begin
                $display("[%0t] ERROR: dout3 mismatch, got=%0d expected=%0d", $time, dout3, golden3_d2[DOUT_W-1:0]);
                error_cnt = error_cnt + 1;
            end

            if ((dout0 === golden0_d2[DOUT_W-1:0]) &&
                (dout1 === golden1_d2[DOUT_W-1:0]) &&
                (dout2 === golden2_d2[DOUT_W-1:0]) &&
                (dout3 === golden3_d2[DOUT_W-1:0]))
            begin
                $display("[%0t] PASS: dout = {%0d, %0d, %0d, %0d}",
                         $time, dout0, dout1, dout2, dout3);
            end
        end
    end

    // =========================================================
    // Stimulus
    // =========================================================
    initial
    begin
        clk       = 1'b0;
        rst_n     = 1'b0;
        en        = 1'b0;
        din0      = {DIN_W{1'b0}};
        din1      = {DIN_W{1'b0}};
        din2      = {DIN_W{1'b0}};
        din3      = {DIN_W{1'b0}};
        din_valid = 1'b0;
        coeff_bus = {(TAPS*COEF_W){1'b0}};
        error_cnt = 0;

        init_coeff();
        pack_coeff_bus();
        init_history();

        // ---------------------------------------------
        // Reset
        // ---------------------------------------------
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        en    = 1'b1;

        // ---------------------------------------------
        // Apply valid samples
        // ---------------------------------------------
        apply_input(10'sd1,   10'sd2,   10'sd3,   10'sd4  );
        apply_input(10'sd5,   10'sd6,   10'sd7,   10'sd8  );
        apply_input(10'sd9,   10'sd10,  10'sd11,  10'sd12 );
        apply_input(10'sd13,  10'sd14,  10'sd15,  10'sd16 );
        apply_input(-10'sd2,  10'sd3,  -10'sd4,   10'sd5  );
        apply_input(10'sd20, -10'sd1,   10'sd6,  -10'sd3  );
        apply_input(10'sd7,   10'sd0,  -10'sd8,   10'sd9  );
        apply_input(-10'sd5, -10'sd6,   10'sd4,   10'sd3  );
        apply_input(10'sd12,  10'sd11,  10'sd10,  10'sd9  );
        apply_input(10'sd0,   10'sd1,   10'sd0,   10'sd1  );

        // ---------------------------------------------
        // Bubbles
        // ---------------------------------------------
        apply_bubble();
        apply_bubble();
        apply_bubble();
        apply_bubble();

        // ---------------------------------------------
        // Summary
        // ---------------------------------------------
        if (error_cnt == 0)
            $display("========================================");
        if (error_cnt == 0)
            $display("TEST PASSED");
        if (error_cnt == 0)
            $display("========================================");

        if (error_cnt != 0)
            $display("========================================");
        if (error_cnt != 0)
            $display("TEST FAILED, error_cnt = %0d", error_cnt);
        if (error_cnt != 0)
            $display("========================================");

        $finish;
    end

endmodule