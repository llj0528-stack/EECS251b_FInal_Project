`timescale 1ns/1ps

module ffe_golden_model_tb;

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
    // VPD dump
    // =========================================================
    initial begin
        $vcdplusfile("ffe.vpd");
        $vcdpluson(0, ffe_golden_model_tb);
    end

    // =========================================================
    // Trace dump
    // =========================================================
    integer finput;
    integer fdut;
    integer input_cycle;
    integer output_cycle;

    initial begin
        finput = $fopen("input_trace.txt", "w");
        fdut   = $fopen("dut_trace.txt", "w");
        input_cycle  = 0;
        output_cycle = 0;

        if (finput == 0) begin
            $display("ERROR: failed to open input_trace.txt");
            $finish;
        end
        if (fdut == 0) begin
            $display("ERROR: failed to open dut_trace.txt");
            $finish;
        end
    end

    // =========================================================
    // Clock generation
    // =========================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PER/2) clk = ~clk;
    end

    // =========================================================
    // Coefficient storage
    // =========================================================
    reg signed [COEF_W-1:0] tb_coef [0:TAPS-1];

    task pack_coeff_bus;
        integer idx;
        begin
            coeff_bus = {(TAPS*COEF_W){1'b0}};
            for (idx = 0; idx < TAPS; idx = idx + 1) begin
                coeff_bus[idx*COEF_W +: COEF_W] = tb_coef[idx][COEF_W-1:0];
            end
        end
    endtask

    task init_coeff;
        begin
            tb_coef[0] =  8'sd8;
            tb_coef[1] = -8'sd3;
            tb_coef[2] =  8'sd2;
            tb_coef[3] =  8'sd1;
            tb_coef[4] = -8'sd1;
            tb_coef[5] =  8'sd2;
            tb_coef[6] = -8'sd2;
            tb_coef[7] =  8'sd1;
        end
    endtask

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
    // Dump INPUT trace at posedge
    // This is exactly when DUT samples inputs.
    // =========================================================
    always @(posedge clk) begin
        if (rst_n === 1'b1) begin
            input_cycle = input_cycle + 1;

            $fwrite(finput, "%0d %0d %0d %0d %0d %0d %0d %0d %0h\n",
                input_cycle, rst_n, en, din_valid, din0, din1, din2, din3, coeff_bus);
        end
    end

    // =========================================================
    // Dump DUT trace at negedge
    // By negedge, outputs from posedge NBA have settled.
    // =========================================================
    always @(negedge clk) begin
        if (rst_n === 1'b1) begin
            output_cycle = output_cycle + 1;

            $fwrite(fdut, "%0d %0d %0d %0d %0d %0d\n",
                output_cycle, dout_valid, dout0, dout1, dout2, dout3);
        end
    end

    // =========================================================
    // Stimulus
    // =========================================================
    initial begin
        rst_n     = 1'b0;
        en        = 1'b0;
        din0      = {DIN_W{1'b0}};
        din1      = {DIN_W{1'b0}};
        din2      = {DIN_W{1'b0}};
        din3      = {DIN_W{1'b0}};
        din_valid = 1'b0;
        coeff_bus = {(TAPS*COEF_W){1'b0}};

        init_coeff();
        pack_coeff_bus();

        // Reset
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        en    = 1'b1;

        // Valid samples
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

        // Bubbles
        apply_bubble();
        apply_bubble();
        apply_bubble();
        apply_bubble();

        // Drain pipeline
        repeat (8) @(posedge clk);

        $fclose(finput);
        $fclose(fdut);

        $finish;
    end

endmodule