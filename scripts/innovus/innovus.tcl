# ============================================================
# Innovus P&R script for FFE
# Conservative version for Innovus 23.15
# With IO file enabled
# Full GDS merge for std cells
# ============================================================

set TOP FFE

# ------------------------------------------------------------
# Output directories
# ------------------------------------------------------------
file mkdir ./build/innovus
file mkdir ./build/innovus/logs
file mkdir ./build/innovus/reports
file mkdir ./build/innovus/db
file mkdir ./build/innovus/outputs

# ------------------------------------------------------------
# Basic setup
# ------------------------------------------------------------
setMultiCpuUsage -localCpu 8
set_db design_process_node 130

# ------------------------------------------------------------
# Unified initialization
# ------------------------------------------------------------
set init_mmmc_file ./scripts/innovus/mmmc.tcl
set init_verilog   ./build/genus/netlist/FFE_synth.v
set init_top_cell  $TOP
set init_lef_file  { ./tech/lef/sky130_scl_9T.tlef ./tech/lef/sky130_scl_9T.lef }
set init_gds_file  { /scratch/eecs251b-aaj/Final_Project/tech/sky130_scl_9T.gds }
set init_io_file   ./scripts/innovus/FFE.io
set init_pwr_net   {VDD}
set init_gnd_net   {VSS}

init_design

saveDesign ./build/innovus/db/${TOP}_init.enc

# ------------------------------------------------------------
# Routing layer setup
# ------------------------------------------------------------
set_db design_bottom_routing_layer met2
set_db design_top_routing_layer    met5

# ------------------------------------------------------------
# Global power / ground connection
# ------------------------------------------------------------
clearGlobalNets
globalNetConnect VDD -type pgpin -pin {VDD} -all -override
globalNetConnect VSS -type pgpin -pin {VSS} -all -override

# ------------------------------------------------------------
# Floorplan
# ------------------------------------------------------------
floorPlan -r 1.0 0.25 30 30 30 30

saveDesign ./build/innovus/db/${TOP}_floorplan.enc

# ------------------------------------------------------------
# Power planning: core ring and straps
# ------------------------------------------------------------
addRing \
    -nets {VDD VSS} \
    -type core_rings \
    -follow core \
    -layer {top met5 bottom met5 left met4 right met4} \
    -width {top 2.0 bottom 2.0 left 2.0 right 2.0} \
    -spacing {top 2.0 bottom 2.0 left 2.0 right 2.0} \
    -offset {top 2.0 bottom 2.0 left 2.0 right 2.0}

addStripe \
    -nets {VDD VSS} \
    -layer met4 \
    -direction vertical \
    -width 1.0 \
    -spacing 1.0 \
    -set_to_set_distance 40 \
    -start_from left \
    -start_offset 10 \
    -stop_offset 10

# ------------------------------------------------------------
# Placement
# ------------------------------------------------------------
placeDesign

saveDesign ./build/innovus/db/${TOP}_place.enc

report_area   > ./build/innovus/reports/${TOP}_postplace_area.rpt
report_timing > ./build/innovus/reports/${TOP}_postplace_timing.rpt

# ------------------------------------------------------------
# Power routing: connect stdcell PG pins/rails
# ------------------------------------------------------------
globalNetConnect VDD -type pgpin -pin {VDD} -all -override
globalNetConnect VSS -type pgpin -pin {VSS} -all -override

sroute \
    -nets {VDD VSS} \
    -connect {corePin} \
    -allowJogging true \
    -allowLayerChange true

saveDesign ./build/innovus/db/${TOP}_sroute.enc

# ------------------------------------------------------------
# Pre-CTS optimization
# ------------------------------------------------------------
optDesign -preCTS -drv
optDesign -preCTS -setup

saveDesign ./build/innovus/db/${TOP}_prects_opt.enc

report_timing > ./build/innovus/reports/${TOP}_prects_timing.rpt

# ------------------------------------------------------------
# CTS cell candidates
# ------------------------------------------------------------
set_ccopt_property buffer_cells   {CLKBUFX2 CLKBUFX4 CLKBUFX8}
set_ccopt_property inverter_cells {CLKINVX1 CLKINVX2 CLKINVX4 CLKINVX8}

# ------------------------------------------------------------
# Clock tree synthesis
# ------------------------------------------------------------
create_ccopt_clock_tree_spec
ccopt_design -timing_debug_report

saveDesign ./build/innovus/db/${TOP}_cts.enc

report_timing > ./build/innovus/reports/${TOP}_postcts_timing.rpt

# ------------------------------------------------------------
# Post-CTS optimization
# ------------------------------------------------------------
optDesign -postCTS -drv
optDesign -postCTS -setup
optDesign -postCTS -hold

saveDesign ./build/innovus/db/${TOP}_postcts_opt.enc

report_timing > ./build/innovus/reports/${TOP}_postcts_opt_timing.rpt

# ------------------------------------------------------------
# Routing
# ------------------------------------------------------------
routeDesign

saveDesign ./build/innovus/db/${TOP}_route.enc

# ------------------------------------------------------------
# Post-route optimization
# ------------------------------------------------------------
setDelayCalMode -SIAware false

optDesign -postRoute -drv
optDesign -postRoute -setup
optDesign -postRoute -hold

saveDesign ./build/innovus/db/${TOP}_postroute_opt.enc

# ------------------------------------------------------------
# Filler insertion for stdcell rail continuity
# ------------------------------------------------------------
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILL

saveDesign ./build/innovus/db/${TOP}_fill.enc

# ------------------------------------------------------------
# Final checks / reports
# ------------------------------------------------------------
verify_drc > ./build/innovus/reports/${TOP}_drc.rpt

verifyConnectivity -type all -error 1000 -warning 1000 \
    > ./build/innovus/reports/${TOP}_verify_connectivity_all.rpt

verifyConnectivity -type special -nets {VDD VSS} -error 1000 -warning 1000 \
    > ./build/innovus/reports/${TOP}_verify_connectivity_pg.rpt

report_timing -max_paths 50 > ./build/innovus/reports/${TOP}_final_timing.rpt
report_area   > ./build/innovus/reports/${TOP}_final_area.rpt
report_power  > ./build/innovus/reports/${TOP}_final_power.rpt

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
saveNetlist ./build/innovus/outputs/${TOP}_par.v

# SDF optional
write_sdf ./build/innovus/outputs/${TOP}.par.sdf

saveDesign ./build/innovus/db/${TOP}_final.enc

# ------------------------------------------------------------
# GDS outputs
# 1) merged GDS   : for final physical view / DRC
# 2) non-merged GDS: for LVS experiments with preserved hierarchy
# ------------------------------------------------------------

# ---- merged GDS (std-cell geometry merged in) ----
streamOut ./build/innovus/outputs/${TOP}_merged.gds \
    -mapFile ./tech/sky130_stream.mapFile \
    -structureName ${TOP} \
    -merge { ./tech/sky130_scl_9T.gds } \
    -uniquifyCellNames \
    -mode ALL

# ---- non-merged GDS (no std-cell merge) ----
streamOut ./build/innovus/outputs/${TOP}_nomerged.gds \
    -mapFile ./tech/sky130_stream.mapFile \
    -structureName ${TOP} \
    -mode ALL

exit
