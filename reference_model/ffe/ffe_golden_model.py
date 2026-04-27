from typing import List, Tuple


def mask(width: int) -> int:
    return (1 << width) - 1


def to_sint(value: int, width: int) -> int:
    """
    Interpret value as signed two's-complement integer of given width.
    """
    value &= mask(width)
    if value & (1 << (width - 1)):
        value -= (1 << width)
    return value


def trunc_sint(value: int, width: int) -> int:
    """
    Truncate/wrap value into width-bit signed two's-complement range.
    """
    return to_sint(value, width)


def unpack_coeff_bus(coeff_bus: int, taps: int, coef_w: int) -> List[int]:
    """
    coeff_bus[i*COEF_W +: COEF_W]
    same as Verilog packed bus slicing
    """
    coeffs = []
    for i in range(taps):
        raw = (coeff_bus >> (i * coef_w)) & mask(coef_w)
        coeffs.append(to_sint(raw, coef_w))
    return coeffs


class FFEGoldenModel:
    def __init__(
        self,
        din_w: int = 10,
        coef_w: int = 8,
        taps: int = 8,
    ):
        self.DIN_W = din_w
        self.COEF_W = coef_w
        self.TAPS = taps
        self.PROD_W = din_w + coef_w
        self.ACC_W = self.PROD_W + (taps - 1).bit_length()
        self.DOUT_W = self.ACC_W

        hist_len = max(0, taps - 1)
        self.shift_reg0 = [0] * hist_len
        self.shift_reg1 = [0] * hist_len
        self.shift_reg2 = [0] * hist_len
        self.shift_reg3 = [0] * hist_len

        # registered products
        self.mult0_reg = [0] * taps
        self.mult1_reg = [0] * taps
        self.mult2_reg = [0] * taps
        self.mult3_reg = [0] * taps

        # registered sums to model output register stage
        self.sum0_reg = 0
        self.sum1_reg = 0
        self.sum2_reg = 0
        self.sum3_reg = 0

        # valid pipeline
        # IMPORTANT:
        # To match the previously passing Verilog TB,
        # data compares against d2-equivalent, but valid compares against d3-equivalent.
        self.valid_pipe1 = 0
        self.valid_pipe2 = 0
        self.valid_pipe3 = 0

        self.dout0 = 0
        self.dout1 = 0
        self.dout2 = 0
        self.dout3 = 0
        self.dout_valid = 0

    def reset(self) -> None:
        hist_len = max(0, self.TAPS - 1)
        self.shift_reg0 = [0] * hist_len
        self.shift_reg1 = [0] * hist_len
        self.shift_reg2 = [0] * hist_len
        self.shift_reg3 = [0] * hist_len

        self.mult0_reg = [0] * self.TAPS
        self.mult1_reg = [0] * self.TAPS
        self.mult2_reg = [0] * self.TAPS
        self.mult3_reg = [0] * self.TAPS

        self.sum0_reg = 0
        self.sum1_reg = 0
        self.sum2_reg = 0
        self.sum3_reg = 0

        self.valid_pipe1 = 0
        self.valid_pipe2 = 0
        self.valid_pipe3 = 0

        self.dout0 = 0
        self.dout1 = 0
        self.dout2 = 0
        self.dout3 = 0
        self.dout_valid = 0

    def _sum_products(self, prods: List[int]) -> int:
        total = 0
        for p in prods:
            p_s = to_sint(p, self.PROD_W)
            total += p_s
            total = trunc_sint(total, self.ACC_W)
        return total

    def step(
        self,
        clk_rising: bool,
        rst_n: int,
        en: int,
        din0: int,
        din1: int,
        din2: int,
        din3: int,
        din_valid: int,
        coeff_bus: int,
    ) -> Tuple[int, int, int, int, int]:
        """
        One-cycle model of the RTL/reference checking behavior.
        Returns: (dout0, dout1, dout2, dout3, dout_valid)
        """

        if not clk_rising:
            return self.dout0, self.dout1, self.dout2, self.dout3, self.dout_valid

        if not rst_n:
            self.reset()
            return self.dout0, self.dout1, self.dout2, self.dout3, self.dout_valid

        din0 = to_sint(din0, self.DIN_W)
        din1 = to_sint(din1, self.DIN_W)
        din2 = to_sint(din2, self.DIN_W)
        din3 = to_sint(din3, self.DIN_W)

        coeffs = unpack_coeff_bus(coeff_bus, self.TAPS, self.COEF_W)

        if en:
            # -------------------------------------------------
            # combinational sum uses OLD mult_reg
            # -------------------------------------------------
            sum0_comb = self._sum_products(self.mult0_reg)
            sum1_comb = self._sum_products(self.mult1_reg)
            sum2_comb = self._sum_products(self.mult2_reg)
            sum3_comb = self._sum_products(self.mult3_reg)

            # save old values for NBA-style behavior
            old_valid_pipe1 = self.valid_pipe1
            old_valid_pipe2 = self.valid_pipe2
            old_valid_pipe3 = self.valid_pipe3

            old_sum0_reg = self.sum0_reg
            old_sum1_reg = self.sum1_reg
            old_sum2_reg = self.sum2_reg
            old_sum3_reg = self.sum3_reg

            next_shift_reg0 = self.shift_reg0[:]
            next_shift_reg1 = self.shift_reg1[:]
            next_shift_reg2 = self.shift_reg2[:]
            next_shift_reg3 = self.shift_reg3[:]

            next_mult0_reg = self.mult0_reg[:]
            next_mult1_reg = self.mult1_reg[:]
            next_mult2_reg = self.mult2_reg[:]
            next_mult3_reg = self.mult3_reg[:]

            # -------------------------------------------------
            # valid pipeline
            # d3-equivalent to match original passing Verilog TB
            # -------------------------------------------------
            next_valid_pipe1 = din_valid
            next_valid_pipe2 = old_valid_pipe1
            next_valid_pipe3 = old_valid_pipe2
            next_dout_valid = old_valid_pipe3

            # -------------------------------------------------
            # if (din_valid) update history and mult regs
            # -------------------------------------------------
            if din_valid:
                for k in range(self.TAPS):
                    c = coeffs[k]
                    if k == 0:
                        next_mult0_reg[k] = trunc_sint(din0 * c, self.PROD_W)
                        next_mult1_reg[k] = trunc_sint(din1 * c, self.PROD_W)
                        next_mult2_reg[k] = trunc_sint(din2 * c, self.PROD_W)
                        next_mult3_reg[k] = trunc_sint(din3 * c, self.PROD_W)
                    else:
                        next_mult0_reg[k] = trunc_sint(self.shift_reg0[k - 1] * c, self.PROD_W)
                        next_mult1_reg[k] = trunc_sint(self.shift_reg1[k - 1] * c, self.PROD_W)
                        next_mult2_reg[k] = trunc_sint(self.shift_reg2[k - 1] * c, self.PROD_W)
                        next_mult3_reg[k] = trunc_sint(self.shift_reg3[k - 1] * c, self.PROD_W)

                if self.TAPS > 1:
                    for k in range(self.TAPS - 2, 0, -1):
                        next_shift_reg0[k] = self.shift_reg0[k - 1]
                        next_shift_reg1[k] = self.shift_reg1[k - 1]
                        next_shift_reg2[k] = self.shift_reg2[k - 1]
                        next_shift_reg3[k] = self.shift_reg3[k - 1]

                    next_shift_reg0[0] = din0
                    next_shift_reg1[0] = din1
                    next_shift_reg2[0] = din2
                    next_shift_reg3[0] = din3

            # -------------------------------------------------
            # output register stage
            # observable dout this cycle = old sum_reg
            # current sum_comb becomes next sum_reg
            # -------------------------------------------------
            next_sum0_reg = trunc_sint(sum0_comb, self.ACC_W)
            next_sum1_reg = trunc_sint(sum1_comb, self.ACC_W)
            next_sum2_reg = trunc_sint(sum2_comb, self.ACC_W)
            next_sum3_reg = trunc_sint(sum3_comb, self.ACC_W)

            next_dout0 = trunc_sint(old_sum0_reg, self.DOUT_W)
            next_dout1 = trunc_sint(old_sum1_reg, self.DOUT_W)
            next_dout2 = trunc_sint(old_sum2_reg, self.DOUT_W)
            next_dout3 = trunc_sint(old_sum3_reg, self.DOUT_W)

            # commit
            self.shift_reg0 = next_shift_reg0
            self.shift_reg1 = next_shift_reg1
            self.shift_reg2 = next_shift_reg2
            self.shift_reg3 = next_shift_reg3

            self.mult0_reg = next_mult0_reg
            self.mult1_reg = next_mult1_reg
            self.mult2_reg = next_mult2_reg
            self.mult3_reg = next_mult3_reg

            self.sum0_reg = next_sum0_reg
            self.sum1_reg = next_sum1_reg
            self.sum2_reg = next_sum2_reg
            self.sum3_reg = next_sum3_reg

            self.valid_pipe1 = next_valid_pipe1
            self.valid_pipe2 = next_valid_pipe2
            self.valid_pipe3 = next_valid_pipe3

            self.dout_valid = next_dout_valid

            self.dout0 = next_dout0
            self.dout1 = next_dout1
            self.dout2 = next_dout2
            self.dout3 = next_dout3

        return self.dout0, self.dout1, self.dout2, self.dout3, self.dout_valid