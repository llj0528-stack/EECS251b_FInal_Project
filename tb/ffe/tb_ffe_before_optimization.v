`timescale 1ns/1ps

module tb_FFE;

    // Parameters
    localparam integer DIN_W  = 10;
    localparam integer COEF_W = 8;
    localparam integer TAPS   = 4;
    localparam integer ACC_W  = DIN_W + COEF_W + $clog2(TAPS);
    localparam integer DOUT_W = ACC_W;

    // DUT signals
    reg                            clk;
    reg                            rst_n;
    reg                            en;

    reg  signed [DIN_W-1:0]        din0;
    reg  signed [DIN_W-1:0]        din1;
    reg  signed [DIN_W-1:0]        din2;
    reg  signed [DIN_W-1:0]        din3;
    reg                            din_valid;

    reg  [TAPS*COEF_W-1:0]         coeff_bus;

    wire signed [DOUT_W-1:0]       dout0;
    wire signed [DOUT_W-1:0]       dout1;
    wire signed [DOUT_W-1:0]       dout2;
    wire signed [DOUT_W-1:0]       dout3;
    wire                           dout_valid;

    // DUT
    FFE #(
        .DIN_W (DIN_W),
        .COEF_W(COEF_W),
        .TAPS  (TAPS),
        .ACC_W (ACC_W),
        .DOUT_W(DOUT_W)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (en),
        .din0      (din0),
        .din1      (din1),
        .din2      (din2),
        .din3      (din3),
        .din_valid (din_valid),
        .coeff_bus (coeff_bus),
        .dout0     (dout0),
        .dout1     (dout1),
        .dout2     (dout2),
        .dout3     (dout3),
        .dout_valid(dout_valid)
    );

    // Clock signal: 100MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // VPD dump for VCS/DVE
    initial begin
        $vcdpluson;
    end

    // Helper task: drive one 4-lane sample
    task send_sample(
        input signed [DIN_W-1:0] s0,
        input signed [DIN_W-1:0] s1,
        input signed [DIN_W-1:0] s2,
        input signed [DIN_W-1:0] s3
    );
    begin
        @(negedge clk);
        din0      = s0;
        din1      = s1;
        din2      = s2;
        din3      = s3;
        din_valid = 1'b1;
    end
    endtask

    // Helper task: insert idle cycle
    task send_idle;
    begin
        @(negedge clk);
        din0      = {DIN_W{1'b0}};
        din1      = {DIN_W{1'b0}};
        din2      = {DIN_W{1'b0}};
        din3      = {DIN_W{1'b0}};
        din_valid = 1'b0;
    end
    endtask

    // Stimulus
    initial begin
        // Init
        rst_n     = 1'b0;
        en        = 1'b0;
        din0      = {DIN_W{1'b0}};
        din1      = {DIN_W{1'b0}};
        din2      = {DIN_W{1'b0}};
        din3      = {DIN_W{1'b0}};
        din_valid = 1'b0;
        coeff_bus = {TAPS*COEF_W{1'b0}};

        // Set all coefficients = 1
        // tap0 = 1, tap1 = 1, tap2 = 1, tap3 = 1
        coeff_bus[(1*COEF_W)-1 : 0*COEF_W] = $signed(8'd1);
        coeff_bus[(2*COEF_W)-1 : 1*COEF_W] = $signed(8'd1);
        coeff_bus[(3*COEF_W)-1 : 2*COEF_W] = $signed(8'd1);
        coeff_bus[(4*COEF_W)-1 : 3*COEF_W] = $signed(8'd1);

        // Hold reset a few cycles
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        en    = 1'b1;

        // Send a few samples
        // Lane0: 1,2,3,4,...
        // Lane1: 10,20,30,40,...
        // Lane2: -1,-2,-3,-4,...
        // Lane3: 5,0,5,0,...
        send_sample(10'sd1,   10'sd10,  -10'sd1,  10'sd5);
        send_sample(10'sd2,   10'sd20,  -10'sd2,  10'sd0);
        send_sample(10'sd3,   10'sd30,  -10'sd3,  10'sd5);
        send_sample(10'sd4,   10'sd40,  -10'sd4,  10'sd0);
        send_sample(10'sd5,   10'sd50,  -10'sd5,  10'sd5);
        send_sample(10'sd6,   10'sd60,  -10'sd6,  10'sd0);

        // Idle a few cycles
        send_idle;
        send_idle;
        send_idle;

        // Disable block
        @(negedge clk);
        en = 1'b0;
        din_valid = 1'b0;

        repeat (3) @(negedge clk);

        $finish;
    end

    // Monitor
    initial begin
        $display(" time | rst_n en din_valid || din0 din1 din2 din3 || dout_valid || dout0 dout1 dout2 dout3");
        $display("------------------------------------------------------------------------------------------------");
        forever begin
            @(posedge clk);
            $display("%5t |   %0b    %0b     %0b    || %4d %4d %4d %4d ||     %0b      || %5d %5d %5d %5d",
                     $time, rst_n, en, din_valid,
                     din0, din1, din2, din3,
                     dout_valid,
                     dout0, dout1, dout2, dout3);
        end
    end

endmodule