#!/usr/bin/env python3
"""
Generate a top-level CDL netlist for LVS from:
1) a synthesized gate-level Verilog netlist
2) a standard-cell CDL library

This script is designed for simple synthesized Verilog netlists that instantiate
standard cells using named-port connections.

Main features:
- Parses .SUBCKT pin order from the CDL library
- Parses the top module and its instances from the Verilog netlist
- Converts named-port Verilog instances into CDL X-instances
- Handles escaped Verilog identifiers such as:
      \shift_reg2[4] [6]
  by converting them into safe CDL tokens:
      ESC_shift_reg2_4_6
- Preserves bracketed bus names such as:
      coeff_bus[57]
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from typing import Dict, List, Tuple


def read_text(path: pathlib.Path) -> str:
    """Read a text file."""
    return path.read_text(encoding="utf-8", errors="ignore")


def strip_verilog_comments(text: str) -> str:
    """Remove Verilog line comments and block comments."""
    text = re.sub(r"//.*?$", "", text, flags=re.MULTILINE)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return text


def escape_to_safe_name(token: str) -> str:
    """
    Convert one escaped Verilog identifier into a CDL-safe token.

    Example:
        \\shift_reg2[4] [6]  -> ESC_shift_reg2_4_6
    """
    token = token.strip()
    if not token.startswith("\\"):
        return token

    token = token[1:]
    token = token.replace(" ", "_")
    token = token.replace("[", "_")
    token = token.replace("]", "_")
    token = token.replace(".", "_")
    token = token.replace("/", "_")
    token = token.replace(":", "_")
    token = token.replace("-", "_")
    token = re.sub(r"_+", "_", token).strip("_")
    return f"ESC_{token}"


def sanitize_escaped_identifiers(text: str) -> str:
    """
    Replace escaped Verilog identifiers with safe one-token names.

    This specifically targets patterns such as:
        \\shift_reg2[4] [6]
        \\mult0_comb[7] [11]

    The escaped identifier starts with a backslash and terminates at the next
    whitespace, but synthesized netlists often continue with bracket groups.
    This regex captures the whole escaped name plus optional bracket groups.
    """
    pattern = re.compile(r"\\[^\s,();]+(?:\s*\[[^\]]+\])*")

    def repl(match: re.Match[str]) -> str:
        return escape_to_safe_name(match.group(0))

    return pattern.sub(repl, text)


def sanitize_bracket_name(name: str) -> str:
    return name.strip()


def clean_net_name(net: str) -> str:
    """
    Convert a Verilog net token into a CDL-safe token.
    """
    net = net.strip()

    if net in {"1'b0", "1'h0", "1'd0"}:
        return "0"
    if net in {"1'b1", "1'h1", "1'd1"}:
        return "1"

    if net.startswith("ESC_"):
        return net

    return sanitize_bracket_name(net)


def normalize_whitespace(text: str) -> str:
    """Collapse repeated whitespace."""
    return re.sub(r"[ \t\r\f\v]+", " ", text)


def parse_cdl_subckts(cdl_text: str) -> Dict[str, List[str]]:
    """
    Parse .SUBCKT pin order from a CDL library.

    Supports '+' continuation lines.

    Returns:
        cell_pin_map[cell_name] = [pin1, pin2, ...]
    """
    cell_pin_map: Dict[str, List[str]] = {}

    lines = cdl_text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()

        if line.upper().startswith(".SUBCKT "):
            stmt = line
            i += 1
            while i < len(lines):
                nxt = lines[i].strip()
                if nxt.startswith("+"):
                    stmt += " " + nxt[1:].strip()
                    i += 1
                else:
                    break

            parts = stmt.split()
            if len(parts) >= 3:
                cell_name = parts[1]
                pins = parts[2:]
                cell_pin_map[cell_name] = pins
            continue

        i += 1

    return cell_pin_map


def parse_module_ports(verilog_text: str, top_name: str) -> List[str]:
    """
    Parse the top module port list from:
        module TOP ( ... );
    """
    pattern = re.compile(
        rf"\bmodule\s+{re.escape(top_name)}\s*\((.*?)\)\s*;",
        flags=re.DOTALL,
    )
    match = pattern.search(verilog_text)
    if not match:
        raise ValueError(f"Could not find top module declaration for '{top_name}'.")

    port_blob = match.group(1)
    raw_ports = [p.strip() for p in port_blob.replace("\n", " ").split(",")]
    ports = [clean_net_name(p) for p in raw_ports if p]
    return ports


def ffe_top_ports() -> List[str]:
    ports: List[str] = []

    ports += ["clk", "rst_n", "en"]

    for bus in ["din0", "din1", "din2", "din3"]:
        ports += [f"{bus}[{i}]" for i in range(10)]

    ports += ["din_valid"]

    ports += [f"coeff_bus[{i}]" for i in range(64)]

    for bus in ["dout0", "dout1", "dout2", "dout3"]:
        ports += [f"{bus}[{i}]" for i in range(21)]

    ports += ["dout_valid"]

    return ports


def extract_module_body(verilog_text: str, top_name: str) -> str:
    """
    Extract the full body of:
        module TOP ... endmodule
    """
    pattern = re.compile(
        rf"\bmodule\s+{re.escape(top_name)}\b(.*?)\bendmodule\b",
        flags=re.DOTALL,
    )
    match = pattern.search(verilog_text)
    if not match:
        raise ValueError(f"Could not find full definition for top module '{top_name}'.")
    return match.group(1)


def split_top_level_commas(blob: str) -> List[str]:
    """
    Split a connection blob by commas only at top level.

    This avoids breaking if unexpected formatting appears.
    """
    items: List[str] = []
    cur: List[str] = []
    depth = 0

    for ch in blob:
        if ch == "(":
            depth += 1
            cur.append(ch)
        elif ch == ")":
            depth -= 1
            cur.append(ch)
        elif ch == "," and depth == 0:
            item = "".join(cur).strip()
            if item:
                items.append(item)
            cur = []
        else:
            cur.append(ch)

    tail = "".join(cur).strip()
    if tail:
        items.append(tail)

    return items


def parse_named_port_connections(conn_blob: str) -> Dict[str, str]:
    """
    Parse named-port Verilog instance connections.

    Example:
        .A(net1), .B(net2), .Y(net3)

    Returns:
        {"A": "net1", "B": "net2", "Y": "net3"}
    """
    conn_dict: Dict[str, str] = {}

    items = split_top_level_commas(conn_blob)
    for item in items:
        m = re.match(r"\.(\w+)\s*\(\s*(.*?)\s*\)\s*$", item, flags=re.DOTALL)
        if not m:
            continue
        pin = m.group(1)
        net = clean_net_name(m.group(2))
        if not net:
            net = "0"
        conn_dict[pin] = net

    return conn_dict


def parse_verilog_instances(
    module_body: str,
    cell_pin_map: Dict[str, List[str]],
) -> List[Tuple[str, str, Dict[str, str]]]:
    instances: List[Tuple[str, str, Dict[str, str]]] = []

    pattern = re.compile(r"\b(\w+)\s+(\w+)\s*\((.*?)\)\s*;", flags=re.DOTALL)

    total_matches = 0
    skipped_not_in_cdl = 0
    skipped_escaped_cell = 0
    skipped_escaped_inst = 0
    skipped_no_named_ports = 0

    seen_cell_types = {}

    for match in pattern.finditer(module_body):
        total_matches += 1

        cell_type = match.group(1)
        inst_name = match.group(2)
        conn_blob = match.group(3)

        seen_cell_types[cell_type] = seen_cell_types.get(cell_type, 0) + 1

        if cell_type not in cell_pin_map:
            skipped_not_in_cdl += 1
            continue

        if cell_type.startswith("ESC_"):
            skipped_escaped_cell += 1
            continue

        if inst_name.startswith("ESC_"):
            skipped_escaped_inst += 1

        conn_dict = parse_named_port_connections(conn_blob)
        if not conn_dict:
            skipped_no_named_ports += 1
            continue

        instances.append((cell_type, inst_name, conn_dict))

    print(f"DEBUG: regex instance-like matches: {total_matches}", file=sys.stderr)
    print(f"DEBUG: skipped because cell type not in CDL: {skipped_not_in_cdl}", file=sys.stderr)
    print(f"DEBUG: skipped escaped cell type: {skipped_escaped_cell}", file=sys.stderr)
    print(f"DEBUG: escaped instance names seen: {skipped_escaped_inst}", file=sys.stderr)
    print(f"DEBUG: skipped because no named .PIN(net) ports: {skipped_no_named_ports}", file=sys.stderr)
    print("DEBUG: first 25 seen cell/module types:", file=sys.stderr)
    for name, count in list(seen_cell_types.items())[:25]:
        print(f"  {name}: {count}", file=sys.stderr)

    print("DEBUG: first 25 CDL cells:", file=sys.stderr)
    for name in list(cell_pin_map.keys())[:25]:
        print(f"  {name}", file=sys.stderr)

    return instances


def build_cdl_instance_line(
    cell_type: str,
    inst_name: str,
    conn_dict: Dict[str, str],
    pin_order: List[str],
) -> str:
    """
    Build one CDL X-instance line using the CDL library pin order.
    Unconnected non-supply pins default to 0.
    """
    ordered_nets: List[str] = []
    for pin in pin_order:
        if pin in conn_dict:
            net = conn_dict[pin]
        elif pin in {"VDD", "VPWR", "VPB", "vdd", "vpwr", "vpb"}:
            net = "VDD"
        elif pin in {"VSS", "VGND", "VNB", "gnd", "vss", "vgnd", "vnb"}:
            net = "VSS"
        else:
            net = "0"

        ordered_nets.append(clean_net_name(net))

    line = f"X{inst_name} " + " ".join(ordered_nets) + f" {cell_type}"
    return line

def write_top_cdl(
    out_path: pathlib.Path,
    cdl_lib_path: pathlib.Path,
    top_name: str,
    top_ports: List[str],
    cdl_instance_lines: List[str],
) -> None:
    """Write the final top-level CDL file."""
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with out_path.open("w", encoding="utf-8") as f:
        f.write(f'.INCLUDE "{cdl_lib_path.resolve()}"\n\n')
        f.write(f".SUBCKT {top_name} " + " ".join(top_ports) + "\n")
        for line in cdl_instance_lines:
            f.write(line + "\n")
        f.write(f".ENDS {top_name}\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a top-level CDL from synthesized Verilog and a CDL library."
    )
    parser.add_argument("--verilog", required=True, help="Path to synthesized Verilog netlist.")
    parser.add_argument("--cdl-lib", required=True, help="Path to standard-cell CDL library.")
    parser.add_argument("--out", required=True, help="Output path for generated top-level CDL.")
    parser.add_argument("--top", required=True, help="Top module / subckt name.")

    args = parser.parse_args()

    verilog_path = pathlib.Path(args.verilog)
    cdl_lib_path = pathlib.Path(args.cdl_lib)
    out_path = pathlib.Path(args.out)
    top_name = args.top

    if not verilog_path.is_file():
        print(f"ERROR: Verilog file not found: {verilog_path}", file=sys.stderr)
        return 1

    if not cdl_lib_path.is_file():
        print(f"ERROR: CDL library file not found: {cdl_lib_path}", file=sys.stderr)
        return 1

    verilog_text = read_text(verilog_path)
    verilog_text = strip_verilog_comments(verilog_text)
    verilog_text = sanitize_escaped_identifiers(verilog_text)

    cdl_text = read_text(cdl_lib_path)
    cell_pin_map = parse_cdl_subckts(cdl_text)
    if not cell_pin_map:
        print("ERROR: No .SUBCKT definitions found in CDL library.", file=sys.stderr)
        return 1

    try:
        top_ports = ffe_top_ports() if top_name == "FFE" else parse_module_ports(verilog_text, top_name)
        module_body = extract_module_body(verilog_text, top_name)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    instances = parse_verilog_instances(module_body, cell_pin_map)
    if not instances:
        print("ERROR: No standard-cell instances were parsed from the top module.", file=sys.stderr)
        return 1

    cdl_instance_lines: List[str] = []
    bad_lines = 0

    for cell_type, inst_name, conn_dict in instances:
        pin_order = cell_pin_map[cell_type]
        line = build_cdl_instance_line(
            cell_type=cell_type,
            inst_name=inst_name,
            conn_dict=conn_dict,
            pin_order=pin_order,
        )

        if not line.startswith("X"):
            bad_lines += 1
            continue

        tokens = line.split()
        if len(tokens) < 3:
            bad_lines += 1
            continue

        if tokens[-1] not in cell_pin_map:
            bad_lines += 1
            continue

        if len(tokens) > 1 and tokens[1].startswith("_"):
            bad_lines += 1
            continue

        cdl_instance_lines.append(line)

    write_top_cdl(
        out_path=out_path,
        cdl_lib_path=cdl_lib_path,
        top_name=top_name,
        top_ports=top_ports,
        cdl_instance_lines=cdl_instance_lines,
    )

    print(f"Loaded {len(cell_pin_map)} .SUBCKT definitions from CDL library.")
    print(f"Parsed {len(instances)} standard-cell instances from Verilog.")
    print(f"Rejected {bad_lines} malformed instance lines.")
    print(f"Wrote top-level CDL to: {out_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
