import pya
import sys
from pathlib import Path

if len(sys.argv) != 3:
    print("usage: make_stdcell_abstract_gds.py in.gds out.gds")
    sys.exit(1)

in_gds = sys.argv[1]
out_gds = sys.argv[2]

ly = pya.Layout()
ly.read(in_gds)

# Keep likely SKY130 met1 drawing/pin/text layers.
# These are intentionally conservative; remove device layers, keep only abstract metal/pin/label layers.
keep = {
    (68, 20),  # met1 drawing
    (68, 16),  # met1 pin
    (68, 5),   # met1 label/text in many SKY130 decks
    (68, 0),   # met1 text/pin variant in some libraries
}

for li in list(ly.layer_indexes()):
    info = ly.get_info(li)
    if (info.layer, info.datatype) not in keep:
        ly.delete_layer(li)

ly.write(out_gds)
print(f"Wrote {out_gds}")
