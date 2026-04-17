module FFE #(
    parameter integer DIN_W   = 10,  // input sample width
    parameter integer COEF_W  = 8,   // coefficient width
    parameter integer TAPS    = 8,   // number of FIR taps
    parameter integer ACC_W   = DIN_W + COEF_W + $clog2(TAPS),
    parameter integer DOUT_W  = ACC_W
)(
    input  wire                            clk,
    input  wire                            rst_n,
    input  wire                            en,

    // 4-lane parallel signed input samples from ADC
    input  wire signed [DIN_W-1:0]         din0,
    input  wire signed [DIN_W-1:0]         din1,
    input  wire signed [DIN_W-1:0]         din2,
    input  wire signed [DIN_W-1:0]         din3,
    input  wire                            din_valid,

    // Coefficients packed as: [tap0][tap1][tap2]...[tapN-1] -> tap i = coeff_bus[(i+1)*COEF_W-1 : i*COEF_W]
    input  wire [TAPS*COEF_W-1:0]          coeff_bus,

    // Outputs to Canceller
    output reg  signed [DOUT_W-1:0]        dout0,
    output reg  signed [DOUT_W-1:0]        dout1,
    output reg  signed [DOUT_W-1:0]        dout2,
    output reg  signed [DOUT_W-1:0]        dout3,
    output reg                             dout_valid
);

    // Used for storing din
    reg signed [DIN_W-1:0] shift_reg0 [0:TAPS-1];
    reg signed [DIN_W-1:0] shift_reg1 [0:TAPS-1];
    reg signed [DIN_W-1:0] shift_reg2 [0:TAPS-1];
    reg signed [DIN_W-1:0] shift_reg3 [0:TAPS-1];

    // Auucmulation
    integer i;
    reg signed [ACC_W-1:0] acc0, acc1, acc2, acc3;
    reg signed [DIN_W+COEF_W-1:0] mult0, mult1, mult2, mult3;

    always @(*)
    begin
        acc0 = {ACC_W{1'b0}};
        acc1 = {ACC_W{1'b0}};
        acc2 = {ACC_W{1'b0}};
        acc3 = {ACC_W{1'b0}};

        for (i = 0; i < TAPS; i = i + 1)
        begin
            mult0 = shift_reg0[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            mult1 = shift_reg1[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            mult2 = shift_reg2[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            mult3 = shift_reg3[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);

            acc0 = acc0 + {{(ACC_W-(DIN_W+COEF_W)){mult0[DIN_W+COEF_W-1]}}, mult0};
            acc1 = acc1 + {{(ACC_W-(DIN_W+COEF_W)){mult1[DIN_W+COEF_W-1]}}, mult1};
            acc2 = acc2 + {{(ACC_W-(DIN_W+COEF_W)){mult2[DIN_W+COEF_W-1]}}, mult2};
            acc3 = acc3 + {{(ACC_W-(DIN_W+COEF_W)){mult3[DIN_W+COEF_W-1]}}, mult3};
        end
    end

    // Input, shift register and Output
    integer k;
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            for (k = 0; k < TAPS; k = k + 1) begin
                shift_reg0[k] <= {DIN_W{1'b0}};
                shift_reg1[k] <= {DIN_W{1'b0}};
                shift_reg2[k] <= {DIN_W{1'b0}};
                shift_reg3[k] <= {DIN_W{1'b0}};
            end

            dout0 <= {DOUT_W{1'b0}};
            dout1 <= {DOUT_W{1'b0}};
            dout2 <= {DOUT_W{1'b0}};
            dout3 <= {DOUT_W{1'b0}};
            dout_valid <= 1'b0;

        end

        else if (en)
        begin
            if (din_valid)
            begin
                // Shift registers
                for (k = TAPS-1; k > 0; k = k - 1)
                begin
                    shift_reg0[k] <= shift_reg0[k-1];
                    shift_reg1[k] <= shift_reg1[k-1];
                    shift_reg2[k] <= shift_reg2[k-1];
                    shift_reg3[k] <= shift_reg3[k-1];
                end

                shift_reg0[0] <= din0;
                shift_reg1[0] <= din1;
                shift_reg2[0] <= din2;
                shift_reg3[0] <= din3;

                // Registered output
                dout0      <= acc0[DOUT_W-1:0];
                dout1      <= acc1[DOUT_W-1:0];
                dout2      <= acc2[DOUT_W-1:0];
                dout3      <= acc3[DOUT_W-1:0];
                dout_valid <= 1'b1;
            end 
            
            else
            begin
                dout_valid <= 1'b0;
            end
        end
        
        else
        begin
            dout_valid <= 1'b0;
        end
    end

endmodule