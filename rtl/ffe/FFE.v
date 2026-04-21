module FFE #(
    parameter integer DIN_W   = 10,  // input sample width
    parameter integer COEF_W  = 8,   // coefficient width
    parameter integer TAPS    = 8,   // number of FIR taps
    parameter integer PROD_W  = DIN_W + COEF_W,
    parameter integer ACC_W   = PROD_W + $clog2(TAPS),
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
    // Local parameter:
    // TREE_N = next power of 2 >= TAPS
    // used for zero-padding the balanced adder tree:
    // e.g. SUM = (x0 + x1) + (x2 + x3) + (x4 + 0) + (0 + 0) padding the so-called x5, x6, x7 with 0 
    // e.g. If (2^N-1)<TAPS<=2^N , TREE_N = 2^N
    // =========================================================
    localparam integer TREE_N = (TAPS <= 1) ? 1 : (1 << $clog2(TAPS));

    // =========================================================
    // Shift registers
    // shift_reg?[0] stores x[n-1]
    // shift_reg?[1] stores x[n-2]
    // ...
    // current input din? is used directly as tap 0, do not need to be stored!
    // =========================================================
    reg signed [DIN_W-1:0] shift_reg0 [0:TAPS-2];
    reg signed [DIN_W-1:0] shift_reg1 [0:TAPS-2];
    reg signed [DIN_W-1:0] shift_reg2 [0:TAPS-2];
    reg signed [DIN_W-1:0] shift_reg3 [0:TAPS-2];

    // =========================================================
    // Stage 0: combinational multiply
    // tap0 uses current din
    // tapi (i>=1) uses shift_reg[i-1]
    // =========================================================
    reg signed [PROD_W-1:0] mult0_comb [0:TAPS-1];
    reg signed [PROD_W-1:0] mult1_comb [0:TAPS-1];
    reg signed [PROD_W-1:0] mult2_comb [0:TAPS-1];
    reg signed [PROD_W-1:0] mult3_comb [0:TAPS-1];

    // =========================================================
    // Stage 1: registered products
    // =========================================================
    reg signed [PROD_W-1:0] mult0_reg [0:TAPS-1];
    reg signed [PROD_W-1:0] mult1_reg [0:TAPS-1];
    reg signed [PROD_W-1:0] mult2_reg [0:TAPS-1];
    reg signed [PROD_W-1:0] mult3_reg [0:TAPS-1];

    // =========================================================
    // Balanced adder tree work arrays
    // tree arrays are combinational scratch space
    // e.g.: 
    // Level 0 (leaf):
    // tree[0]=p0  tree[1]=p1 ... tree[7]=p7
    // Level 1:
    // tree[0]=p0+p1
    // tree[2]=p2+p3
    // tree[4]=p4+p5
    // tree[6]=p6+p7
    // Level 2:
    // tree[0]=(p0+p1)+(p2+p3)
    // tree[4]=(p4+p5)+(p6+p7)
    // Level 3:
    // tree[0]= p0 + ... p7
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
    // valid pipeline
    // one cycle for product register
    // one cycle for output register
    // =========================================================
    reg valid_pipe1;
    reg valid_pipe2;

    integer i; // for loop
    integer k; // for loop
    integer stride; // stored result on each layer: x[0], x[stride-1], x[2*stride - 1]
    integer base; // for loop on each layer

    // =========================================================
    // Combinational multiplication
    // IMPORTANT:
    // coefficient is treated as signed
    // =========================================================
    always @(*)
    begin
        for (i = 0; i < TAPS; i = i + 1)
        begin
            if (i == 0)
            begin
                mult0_comb[i] = din0 * $signed(coeff_bus[i*COEF_W +: COEF_W]);
                mult1_comb[i] = din1 * $signed(coeff_bus[i*COEF_W +: COEF_W]);
                mult2_comb[i] = din2 * $signed(coeff_bus[i*COEF_W +: COEF_W]);
                mult3_comb[i] = din3 * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            end
            else
            begin
                mult0_comb[i] = shift_reg0[i-1] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
                mult1_comb[i] = shift_reg1[i-1] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
                mult2_comb[i] = shift_reg2[i-1] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
                mult3_comb[i] = shift_reg3[i-1] * $signed(coeff_bus[i*COEF_W +: COEF_W]);
            end
        end
    end

    // =========================================================
    // Combinational balanced adder tree
    // load leaves from mult*_reg, sign-extend to ACC_W
    // zero-pad unused leaves
    // then reduce in-place
    // =========================================================
    always @(*)
    begin
        // leaf loading
        for (i = 0; i < TREE_N; i = i + 1)
        begin
            if (i < TAPS)
            begin
                tree0[i] = {{(ACC_W-PROD_W){mult0_reg[i][PROD_W-1]}}, mult0_reg[i]}; // Sign extension
                tree1[i] = {{(ACC_W-PROD_W){mult1_reg[i][PROD_W-1]}}, mult1_reg[i]};
                tree2[i] = {{(ACC_W-PROD_W){mult2_reg[i][PROD_W-1]}}, mult2_reg[i]};
                tree3[i] = {{(ACC_W-PROD_W){mult3_reg[i][PROD_W-1]}}, mult3_reg[i]};
            end
            else // If TAPS is not a power of 2, padding with 0s
            begin
                tree0[i] = {ACC_W{1'b0}};
                tree1[i] = {ACC_W{1'b0}};
                tree2[i] = {ACC_W{1'b0}};
                tree3[i] = {ACC_W{1'b0}};
            end
        end

        // balanced reduction
        stride = 1;
        while (stride < TREE_N) // Genus will not generate combination loop in the while loop. 
        begin
            for (base = 0; base < TREE_N; base = base + 2*stride)
            begin
                tree0[base] = tree0[base] + tree0[base + stride];
                tree1[base] = tree1[base] + tree1[base + stride];
                tree2[base] = tree2[base] + tree2[base + stride];
                tree3[base] = tree3[base] + tree3[base + stride];
            end
            stride = stride << 1; // Stride = Stride*2
        end

        sum0_comb = tree0[0];
        sum1_comb = tree1[0];
        sum2_comb = tree2[0];
        sum3_comb = tree3[0];
    end

    // =========================================================
    // Sequential logic
    // 1) update valid pipeline
    // 2) shift input history
    // 3) register products
    // 4) register outputs
    // =========================================================
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n) // Reset
        begin
            if (TAPS > 1)
            begin
                for (k = 0; k < TAPS-1; k = k + 1)
                begin
                    shift_reg0[k] <= {DIN_W{1'b0}};
                    shift_reg1[k] <= {DIN_W{1'b0}};
                    shift_reg2[k] <= {DIN_W{1'b0}};
                    shift_reg3[k] <= {DIN_W{1'b0}};
                end
            end

            for (k = 0; k < TAPS; k = k + 1)
            begin
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

            valid_pipe1 <= 1'b0;
            valid_pipe2 <= 1'b0;
        end
        else if (en)
        begin
            // ---------------------------------------------
            // valid pipeline
            // ---------------------------------------------
            valid_pipe1 <= din_valid;
            valid_pipe2 <= valid_pipe1;
            dout_valid  <= valid_pipe2; // Shifte 2 cycles

            if (din_valid) begin
                // -----------------------------------------
                // shift history
                // after clock:
                // shift_reg[0] = current din
                // shift_reg[1] = previous shift_reg[0]
                // ...
                // only needed when TAPS > 1
                // -----------------------------------------
                if (TAPS > 1)
                begin
                    for (k = TAPS-2; k > 0; k = k - 1)
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
                end

                // -----------------------------------------
                // register products corresponding to:
                // tap0 = current din
                // tapi = old samples from shift_reg
                // -----------------------------------------
                for (k = 0; k < TAPS; k = k + 1)
                begin
                    mult0_reg[k] <= mult0_comb[k]; // multi_comb is a wre signal. In order to use in the always(*) block, we define it as reg signal
                    mult1_reg[k] <= mult1_comb[k];
                    mult2_reg[k] <= mult2_comb[k];
                    mult3_reg[k] <= mult3_comb[k];
                end
            end

            // ---------------------------------------------
            // register adder-tree outputs
            // ---------------------------------------------
            dout0 <= sum0_comb[DOUT_W-1:0];
            dout1 <= sum1_comb[DOUT_W-1:0];
            dout2 <= sum2_comb[DOUT_W-1:0];
            dout3 <= sum3_comb[DOUT_W-1:0];
        end
    end

endmodule