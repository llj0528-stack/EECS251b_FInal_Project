module FFE #(
    parameter integer DIN_W   = 10,  // input sample width
    parameter integer COEF_W  = 8,   // coefficient width
    parameter integer TAPS    = 8,   // number of FIR taps
    parameter integer PROD_W  = DIN_W + COEF_W,
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

    // Packed coefficients:
    // tap i = coeff_bus[i*COEF_W +: COEF_W]
    input  wire [TAPS*COEF_W-1:0]          coeff_bus,

    // Outputs
    output reg  signed [DOUT_W-1:0]        dout0,
    output reg  signed [DOUT_W-1:0]        dout1,
    output reg  signed [DOUT_W-1:0]        dout2,
    output reg  signed [DOUT_W-1:0]        dout3,
    output reg                             dout_valid
);

    // =========================================================
    // Local parameters
    // TREE_N: number of leaves in adder tree, rounded up to power of 2
    // =========================================================
    localparam integer TREE_N = (TAPS <= 1) ? 1 : (1 << $clog2(TAPS));

    // =========================================================
    // Shift registers for 4 lanes
    // =========================================================
    reg signed [DIN_W-1:0] shift_reg0 [0:TAPS-1];
    reg signed [DIN_W-1:0] shift_reg1 [0:TAPS-1];
    reg signed [DIN_W-1:0] shift_reg2 [0:TAPS-1];
    reg signed [DIN_W-1:0] shift_reg3 [0:TAPS-1];

    // =========================================================
    // Stage 0: combinational multiply results from current shift regs
    // These are registered in Stage 1
    // =========================================================
    reg  signed [PROD_W-1:0] mult0_comb [0:TAPS-1];
    reg  signed [PROD_W-1:0] mult1_comb [0:TAPS-1];
    reg  signed [PROD_W-1:0] mult2_comb [0:TAPS-1];
    reg  signed [PROD_W-1:0] mult3_comb [0:TAPS-1];

    // =========================================================
    // Stage 1: registered products
    // =========================================================
    reg  signed [PROD_W-1:0] mult0_reg [0:TAPS-1];
    reg  signed [PROD_W-1:0] mult1_reg [0:TAPS-1];
    reg  signed [PROD_W-1:0] mult2_reg [0:TAPS-1];
    reg  signed [PROD_W-1:0] mult3_reg [0:TAPS-1];

    // Valid pipeline: one extra cycle due to product register
    reg valid_pipe;

    integer i;
    integer k;
    integer stride;
    integer base;

    // =========================================================
    // Coefficient extraction + combinational multiplication
    // =========================================================
    always @(*) begin
        for (i = 0; i < TAPS; i = i + 1) begin
            mult0_comb[i] = shift_reg0[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            mult1_comb[i] = shift_reg1[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            mult2_comb[i] = shift_reg2[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            mult3_comb[i] = shift_reg3[i] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
        end
    end

    // =========================================================
    // Balanced adder tree input / working arrays
    // tree*_lvl is combinational and built from mult*_reg
    // Unused leaves are padded with zero
    // =========================================================
    reg signed [ACC_W-1:0] tree0 [0:TREE_N-1];
    reg signed [ACC_W-1:0] tree1 [0:TREE_N-1];
    reg signed [ACC_W-1:0] tree2 [0:TREE_N-1];
    reg signed [ACC_W-1:0] tree3 [0:TREE_N-1];

    reg signed [ACC_W-1:0] sum0_comb;
    reg signed [ACC_W-1:0] sum1_comb;
    reg signed [ACC_W-1:0] sum2_comb;
    reg signed [ACC_W-1:0] sum3_comb;

    // =========================================================
    // Combinational balanced adder tree
    // =========================================================
    always @(*) begin
        // Load leaves with sign-extended registered products
        for (i = 0; i < TREE_N; i = i + 1) begin
            if (i < TAPS) begin
                tree0[i] = {{(ACC_W-PROD_W){mult0_reg[i][PROD_W-1]}}, mult0_reg[i]};
                tree1[i] = {{(ACC_W-PROD_W){mult1_reg[i][PROD_W-1]}}, mult1_reg[i]};
                tree2[i] = {{(ACC_W-PROD_W){mult2_reg[i][PROD_W-1]}}, mult2_reg[i]};
                tree3[i] = {{(ACC_W-PROD_W){mult3_reg[i][PROD_W-1]}}, mult3_reg[i]};
            end
            else begin
                tree0[i] = {ACC_W{1'b0}};
                tree1[i] = {ACC_W{1'b0}};
                tree2[i] = {ACC_W{1'b0}};
                tree3[i] = {ACC_W{1'b0}};
            end
        end

        // Reduce by balanced tree in-place
        stride = 1;
        while (stride < TREE_N) begin
            for (base = 0; base < TREE_N; base = base + 2*stride) begin
                tree0[base] = tree0[base] + tree0[base + stride];
                tree1[base] = tree1[base] + tree1[base + stride];
                tree2[base] = tree2[base] + tree2[base + stride];
                tree3[base] = tree3[base] + tree3[base + stride];
            end
            stride = stride << 1;
        end

        sum0_comb = tree0[0];
        sum1_comb = tree1[0];
        sum2_comb = tree2[0];
        sum3_comb = tree3[0];
    end

    // =========================================================
    // Sequential logic
    // 1) shift input samples
    // 2) register products
    // 3) register final outputs
    // =========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < TAPS; k = k + 1) begin
                shift_reg0[k] <= {DIN_W{1'b0}};
                shift_reg1[k] <= {DIN_W{1'b0}};
                shift_reg2[k] <= {DIN_W{1'b0}};
                shift_reg3[k] <= {DIN_W{1'b0}};

                mult0_reg[k] <= {PROD_W{1'b0}};
                mult1_reg[k] <= {PROD_W{1'b0}};
                mult2_reg[k] <= {PROD_W{1'b0}};
                mult3_reg[k] <= {PROD_W{1'b0}};
            end

            dout0      <= {DOUT_W{1'b0}};
            dout1      <= {DOUT_W{1'b0}};
            dout2      <= {DOUT_W{1'b0}};
            dout3      <= {DOUT_W{1'b0}};
            dout_valid <= 1'b0;
            valid_pipe <= 1'b0;
        end
        else if (en) begin
            if (din_valid) begin
                // ---------------------------------------------
                // Shift registers
                // ---------------------------------------------
                for (k = TAPS-1; k > 0; k = k - 1) begin
                    shift_reg0[k] <= shift_reg0[k-1];
                    shift_reg1[k] <= shift_reg1[k-1];
                    shift_reg2[k] <= shift_reg2[k-1];
                    shift_reg3[k] <= shift_reg3[k-1];
                end

                shift_reg0[0] <= din0;
                shift_reg1[0] <= din1;
                shift_reg2[0] <= din2;
                shift_reg3[0] <= din3;

                // ---------------------------------------------
                // Register multiply results from current shift regs
                // ---------------------------------------------
                for (k = 0; k < TAPS; k = k + 1) begin
                    mult0_reg[k] <= mult0_comb[k];
                    mult1_reg[k] <= mult1_comb[k];
                    mult2_reg[k] <= mult2_comb[k];
                    mult3_reg[k] <= mult3_comb[k];
                end

                // ---------------------------------------------
                // Register output sums from previous cycle's mult_reg
                // ---------------------------------------------
                dout0      <= sum0_comb[DOUT_W-1:0];
                dout1      <= sum1_comb[DOUT_W-1:0];
                dout2      <= sum2_comb[DOUT_W-1:0];
                dout3      <= sum3_comb[DOUT_W-1:0];
                dout_valid <= valid_pipe;

                // Valid pipeline
                valid_pipe <= 1'b1;
            end
            else begin
                dout_valid <= 1'b0;
                valid_pipe <= 1'b0;
            end
        end
        else begin
            dout_valid <= 1'b0;
            valid_pipe <= 1'b0;
        end
    end

endmodule