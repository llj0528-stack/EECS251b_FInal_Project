#!/usr/bin/env python3
import sys
import struct
import datetime
from pathlib import Path

DBU_PER_UM = 1000

MET1_DRAWING = (68, 20)
MET1_PIN     = (68, 16)
MET1_LABELS  = [(68, 5), (68, 16), (68, 0)]

PIN_LAYERS_TO_KEEP = {"met1", "metal1", "m1"}
POWER_PINS = {"VDD", "VSS", "VPWR", "VGND"}


def gds_real8(value):
    if value == 0:
        return b"\x00" * 8
    sign = 0x80 if value < 0 else 0
    value = abs(value)
    exp = 64
    while value < 0.0625:
        value *= 16.0
        exp -= 1
    while value >= 1.0:
        value /= 16.0
        exp += 1
    mant = int(value * (1 << 56) + 0.5)
    if mant >= (1 << 56):
        mant >>= 4
        exp += 1
    return bytes([sign | exp]) + mant.to_bytes(7, "big")


def rec(rtype, dtype, data=b""):
    return struct.pack(">HBB", 4 + len(data), rtype, dtype) + data


def rec_i2(rtype, vals):
    return rec(rtype, 2, b"".join(struct.pack(">h", int(v)) for v in vals))


def rec_i4(rtype, vals):
    return rec(rtype, 3, b"".join(struct.pack(">i", int(v)) for v in vals))


def rec_real8(rtype, vals):
    return rec(rtype, 5, b"".join(gds_real8(v) for v in vals))


def rec_str(rtype, s):
    data = s.encode("ascii", errors="ignore")
    if len(data) % 2:
        data += b"\0"
    return rec(rtype, 6, data)


def dbu(x):
    return int(round(float(x) * DBU_PER_UM))


def rect_xy(x1, y1, x2, y2):
    pts = [(x1, y1), (x2, y1), (x2, y2), (x1, y2), (x1, y1)]
    out = []
    for x, y in pts:
        out.extend([x, y])
    return out


def clean(line):
    line = line.split("#", 1)[0]
    line = line.split("//", 1)[0]
    return line.strip()


def parse_lef(lef_path):
    cells = {}
    cur_macro = None
    cur_pin = None
    cur_layer = None

    for raw in Path(lef_path).read_text(errors="ignore").splitlines():
        line = clean(raw)
        if not line:
            continue

        toks = line.replace(";", " ").split()
        if not toks:
            continue

        key = toks[0].upper()

        if key == "MACRO" and len(toks) >= 2:
            cur_macro = toks[1]
            cells[cur_macro] = {"size": None, "pins": {}}
            cur_pin = None
            cur_layer = None
            continue

        if cur_macro is None:
            continue

        if key == "SIZE" and len(toks) >= 4:
            try:
                by_idx = [t.upper() for t in toks].index("BY")
                w = float(toks[1])
                h = float(toks[by_idx + 1])
                cells[cur_macro]["size"] = (w, h)
            except Exception:
                pass
            continue

        if key == "PIN" and len(toks) >= 2:
            cur_pin = toks[1]
            cur_layer = None
            cells[cur_macro]["pins"].setdefault(cur_pin, [])
            continue

        if key == "LAYER" and cur_pin is not None and len(toks) >= 2:
            cur_layer = toks[1].lower()
            continue

        if key == "RECT" and cur_pin is not None and cur_layer in PIN_LAYERS_TO_KEEP and len(toks) >= 5:
            try:
                x1, y1, x2, y2 = map(float, toks[1:5])
                if x2 > x1 and y2 > y1:
                    cells[cur_macro]["pins"][cur_pin].append((x1, y1, x2, y2))
            except ValueError:
                pass
            continue

        if key == "END" and len(toks) >= 2:
            name = toks[1]
            if cur_pin is not None and name == cur_pin:
                cur_pin = None
                cur_layer = None
            elif name == cur_macro:
                cur_macro = None
                cur_pin = None
                cur_layer = None

    return cells


def power_rail_rects(cell_data):
    size = cell_data["size"]
    pins = cell_data["pins"]

    if size is None:
        return pins

    width, _ = size
    out = {pin: list(rects) for pin, rects in pins.items()}

    for pin, rects in pins.items():
        if pin.upper() not in POWER_PINS or not rects:
            continue

        # Convert each power-pin stripe into a full-width rail, preserving its y span.
        rails = []
        seen = set()
        for _, y1, _, y2 in rects:
            key = (round(y1, 6), round(y2, 6))
            if key in seen:
                continue
            seen.add(key)
            rails.append((0.0, y1, width, y2))

        out[pin] = rails

    return out


def add_boundary(buf, layer, datatype, x1, y1, x2, y2):
    buf += rec(0x08, 0)
    buf += rec_i2(0x0D, [layer])
    buf += rec_i2(0x0E, [datatype])
    buf += rec_i4(0x10, rect_xy(x1, y1, x2, y2))
    buf += rec(0x11, 0)


def add_text(buf, layer, texttype, text, x, y):
    buf += rec(0x0C, 0)
    buf += rec_i2(0x0D, [layer])
    buf += rec_i2(0x16, [texttype])
    buf += rec_i2(0x17, [0])
    buf += rec_i4(0x10, [x, y])
    buf += rec_str(0x19, text)
    buf += rec(0x11, 0)


def write_gds(cells, out_path):
    now = datetime.datetime.now()
    t = [now.year, now.month, now.day, now.hour, now.minute, now.second] * 2

    buf = bytearray()
    buf += rec_i2(0x00, [600])
    buf += rec_i2(0x01, t)
    buf += rec_str(0x02, "sky130_scl_9T_abs")
    buf += rec_real8(0x03, [0.001, 1e-9])

    written = 0
    power_rails = 0

    for cell in sorted(cells):
        pins = power_rail_rects(cells[cell])
        if not any(pins[p] for p in pins):
            continue

        buf += rec_i2(0x05, t)
        buf += rec_str(0x06, cell)

        for pin in sorted(pins):
            for x1, y1, x2, y2 in pins[pin]:
                x1i, y1i, x2i, y2i = dbu(x1), dbu(y1), dbu(x2), dbu(y2)
                cx, cy = (x1i + x2i) // 2, (y1i + y2i) // 2

                if pin.upper() in POWER_PINS:
                    power_rails += 1

                add_boundary(buf, MET1_DRAWING[0], MET1_DRAWING[1], x1i, y1i, x2i, y2i)
                add_boundary(buf, MET1_PIN[0], MET1_PIN[1], x1i, y1i, x2i, y2i)

                for lyr, tt in MET1_LABELS:
                    add_text(buf, lyr, tt, pin, cx, cy)

        buf += rec(0x07, 0)
        written += 1

    buf += rec(0x04, 0)
    Path(out_path).write_bytes(buf)
    return written, power_rails


def main():
    if len(sys.argv) != 3:
        print("usage: lef_to_stdcell_abstract_gds.py input.lef output.gds")
        sys.exit(1)

    cells = parse_lef(sys.argv[1])
    written, power_rails = write_gds(cells, sys.argv[2])

    total_pins = sum(1 for c in cells.values() for p, rects in c["pins"].items() if rects)
    print(f"Parsed LEF macros: {len(cells)}")
    print(f"Pins with met1 rectangles: {total_pins}")
    print(f"Wrote abstract GDS cells: {written}")
    print(f"Full-width power rails emitted: {power_rails}")
    print(f"Output: {sys.argv[2]}")


if __name__ == "__main__":
    main()
