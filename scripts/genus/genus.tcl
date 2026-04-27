# ============================================================
# Genus synthesis script for FFE
# Matching backend library: sky130_scl_9T
# ============================================================

# ------------------------------------------------------------
# Top module
# ------------------------------------------------------------
set TOP FFE

# ------------------------------------------------------------
# Paths
# genus.tcl is under: scripts/genus/
# project root is: ../..
# ------------------------------------------------------------
set ROOT       [file normalize "../.."]
set RTL_DIR    "$ROOT/rtl/ffe"
set CONS_DIR   "$ROOT/constraints"
set TECH_LIB   "$ROOT/tech/lib"
set BUILD_DIR  "$ROOT/build/genus"
set LOG_DIR    "$BUILD_DIR/logs"
set RPT_DIR    "$BUILD_DIR/reports"
set DB_DIR     "$BUILD_DIR/db"
set NET_DIR    "$BUILD_DIR/netlist"

file mkdir $BUILD_DIR
file mkdir $LOG_DIR
file mkdir $RPT_DIR
file mkdir $DB_DIR
file mkdir $NET_DIR

# ------------------------------------------------------------
# Library setup
# IMPORTANT:
# Use the same standard-cell family as Innovus:
#   sky130_scl_9T
# ------------------------------------------------------------
set_db init_lib_search_path [list $TECH_LIB]
set_db library [list sky130_tt_1.8_25_nldm.lib]

puts "Using library search path: $TECH_LIB"
puts "Using target library: sky130_tt_1.8_25_nldm.lib"

# ------------------------------------------------------------
# HDL search path
# ------------------------------------------------------------
set_db init_hdl_search_path [list $RTL_DIR]

# ------------------------------------------------------------
# Read RTL
# ------------------------------------------------------------
read_hdl $RTL_DIR/FFE.v

# ------------------------------------------------------------
# Elaborate
# ------------------------------------------------------------
elaborate $TOP
current_design $TOP

# ------------------------------------------------------------
# Prevent functional mapping to scan FFs, which is unable to used by innovus
# Must be set before initial synthesis
# ------------------------------------------------------------
set_db / .use_scan_seqs_for_non_dft false

# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------
check_design > $RPT_DIR/check_design.rpt
report_design_rules > $RPT_DIR/${TOP}_design_rules.rpt

# ------------------------------------------------------------
# Read constraints
# ------------------------------------------------------------
read_sdc $CONS_DIR/ffe.sdc

# ------------------------------------------------------------
# Synthesis
# ------------------------------------------------------------
syn_generic
write_db $DB_DIR/${TOP}_generic.db

syn_map
write_db $DB_DIR/${TOP}_mapped.db

syn_opt
write_db $DB_DIR/${TOP}_opt.db

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------
report_timing              > $RPT_DIR/${TOP}_timing.rpt
report_timing -max_paths 20 > $RPT_DIR/${TOP}_timing_top20.rpt
report_area                > $RPT_DIR/${TOP}_area.rpt
report_power               > $RPT_DIR/${TOP}_power.rpt
report_qor                 > $RPT_DIR/${TOP}_qor.rpt
report_gates               > $RPT_DIR/${TOP}_gates.rpt

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
write_hdl > $NET_DIR/${TOP}_synth.v
write_sdc > $NET_DIR/${TOP}_synth.sdc
write_sdf $NET_DIR/${TOP}.sdf

exit