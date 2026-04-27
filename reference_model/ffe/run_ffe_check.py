import os
import sys
from ffe_golden_model import FFEGoldenModel


def parse_verilog_int(token: str, field_name: str, line_num: int, fname: str) -> int:
    """
    Parse integer tokens dumped from Verilog.
    If token contains x/z, treat it as 0 but print a warning.
    """
    token = token.strip().lower()

    if "x" in token or "z" in token:
        print(
            f"[WARN] Unknown value in {fname} line {line_num}, field {field_name}: "
            f"'{token}' -> treating as 0"
        )
        return 0

    return int(token)


def parse_verilog_hex(token: str, field_name: str, line_num: int, fname: str) -> int:
    token = token.strip().lower()

    if "x" in token or "z" in token:
        print(
            f"[WARN] Unknown value in {fname} line {line_num}, field {field_name}: "
            f"'{token}' -> treating as 0"
        )
        return 0

    return int(token, 16)


def read_input(fname):
    data = []
    with open(fname, "r") as f:
        for line_num, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue

            tokens = line.split()
            if len(tokens) != 9:
                raise ValueError(
                    f"Input trace format error in {fname} line {line_num}: "
                    f"expected 9 fields, got {len(tokens)} -> {tokens}"
                )

            data.append({
                "cycle": parse_verilog_int(tokens[0], "cycle", line_num, fname),
                "rst_n": parse_verilog_int(tokens[1], "rst_n", line_num, fname),
                "en": parse_verilog_int(tokens[2], "en", line_num, fname),
                "din_valid": parse_verilog_int(tokens[3], "din_valid", line_num, fname),
                "din0": parse_verilog_int(tokens[4], "din0", line_num, fname),
                "din1": parse_verilog_int(tokens[5], "din1", line_num, fname),
                "din2": parse_verilog_int(tokens[6], "din2", line_num, fname),
                "din3": parse_verilog_int(tokens[7], "din3", line_num, fname),
                "coeff_bus": parse_verilog_hex(tokens[8], "coeff_bus", line_num, fname),
            })
    return data


def read_dut(fname):
    data = []
    with open(fname, "r") as f:
        for line_num, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue

            tokens = line.split()
            if len(tokens) != 6:
                raise ValueError(
                    f"DUT trace format error in {fname} line {line_num}: "
                    f"expected 6 fields, got {len(tokens)} -> {tokens}"
                )

            data.append({
                "cycle": parse_verilog_int(tokens[0], "cycle", line_num, fname),
                "valid": parse_verilog_int(tokens[1], "valid", line_num, fname),
                "d0": parse_verilog_int(tokens[2], "d0", line_num, fname),
                "d1": parse_verilog_int(tokens[3], "d1", line_num, fname),
                "d2": parse_verilog_int(tokens[4], "d2", line_num, fname),
                "d3": parse_verilog_int(tokens[5], "d3", line_num, fname),
            })
    return data


def main():
    # Usage:
    # python3 run_ffe_check.py /path/to/build/golden_model_simulation
    if len(sys.argv) > 1:
        sim_dir = sys.argv[1]
    else:
        sim_dir = "."

    input_file = os.path.join(sim_dir, "input_trace.txt")
    dut_file = os.path.join(sim_dir, "dut_trace.txt")

    print(f"[INFO] Using simulation directory: {sim_dir}")
    print(f"[INFO] Input trace file: {input_file}")
    print(f"[INFO] DUT trace file:   {dut_file}")

    if not os.path.isfile(input_file):
        raise FileNotFoundError(f"Input trace file not found: {input_file}")
    if not os.path.isfile(dut_file):
        raise FileNotFoundError(f"DUT trace file not found: {dut_file}")

    gm = FFEGoldenModel()
    inp = read_input(input_file)
    dut = read_dut(dut_file)

    if len(inp) != len(dut):
        raise ValueError(
            f"Trace length mismatch: input_trace has {len(inp)} lines, "
            f"dut_trace has {len(dut)} lines"
        )

    errors = 0

    for i in range(len(inp)):
        in_rec = inp[i]
        dut_rec = dut[i]

        o0, o1, o2, o3, ovalid = gm.step(
            True,
            in_rec["rst_n"],
            in_rec["en"],
            in_rec["din0"],
            in_rec["din1"],
            in_rec["din2"],
            in_rec["din3"],
            in_rec["din_valid"],
            in_rec["coeff_bus"],
        )

        cycle = in_rec["cycle"]

        if in_rec["cycle"] != dut_rec["cycle"]:
            print(
                f"[ERROR] Cycle index mismatch at row {i}: "
                f"input cycle={in_rec['cycle']}, dut cycle={dut_rec['cycle']}"
            )
            errors += 1
            continue

        if dut_rec["valid"] != ovalid:
            print(
                f"[ERROR] VALID MISMATCH @cycle {cycle}: "
                f"DUT valid={dut_rec['valid']}, REF valid={ovalid}"
            )
            errors += 1

        if ovalid == 1:
            dut_tuple = (dut_rec["d0"], dut_rec["d1"], dut_rec["d2"], dut_rec["d3"])
            ref_tuple = (o0, o1, o2, o3)

            if dut_tuple != ref_tuple:
                print(f"[ERROR] DATA MISMATCH @cycle {cycle}")
                print(f"        DUT: {dut_tuple}")
                print(f"        REF: {ref_tuple}")
                errors += 1

    if errors == 0:
        print("========================================")
        print("PASS: RTL output matches Python golden model")
        print("========================================")
    else:
        print("========================================")
        print(f"FAIL: {errors} mismatches found")
        print("========================================")
        sys.exit(1)


if __name__ == "__main__":
    main()