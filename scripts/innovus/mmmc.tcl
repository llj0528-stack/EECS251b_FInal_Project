# ============================================================
# MMMC setup for FFE
# ============================================================

create_constraint_mode -name CONSTRAINTS \
    -sdc_files [list ./build/genus/netlist/FFE_synth.sdc]

create_library_set -name SS_LIBSET \
    -timing [list ./tech/lib/sky130_ss_1.62_125_nldm.lib]

create_rc_corner -name SS_RC \
    -temperature 100.0

create_delay_corner -name SS_DELAY \
    -library_set SS_LIBSET \
    -rc_corner SS_RC

create_analysis_view -name SS_SETUP_VIEW \
    -delay_corner SS_DELAY \
    -constraint_mode CONSTRAINTS

create_library_set -name FF_LIBSET \
    -timing [list ./tech/lib/sky130_ff_1.98_0_nldm.lib]

create_rc_corner -name FF_RC \
    -temperature -40.0

create_delay_corner -name FF_DELAY \
    -library_set FF_LIBSET \
    -rc_corner FF_RC

create_analysis_view -name FF_HOLD_VIEW \
    -delay_corner FF_DELAY \
    -constraint_mode CONSTRAINTS

create_library_set -name TT_LIBSET \
    -timing [list ./tech/lib/sky130_tt_1.8_25_nldm.lib]

create_rc_corner -name TT_RC \
    -temperature 25.0

create_delay_corner -name TT_DELAY \
    -library_set TT_LIBSET \
    -rc_corner TT_RC

create_analysis_view -name TT_VIEW \
    -delay_corner TT_DELAY \
    -constraint_mode CONSTRAINTS

set_analysis_view \
    -setup {SS_SETUP_VIEW} \
    -hold  {FF_HOLD_VIEW} \
    -dynamic TT_VIEW \
    -leakage TT_VIEW