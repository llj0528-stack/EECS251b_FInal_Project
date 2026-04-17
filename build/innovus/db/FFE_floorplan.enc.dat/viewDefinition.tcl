if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name TT_LIBSET\
   -timing\
    [list ${::IMEX::libVar}/mmmc/sky130_tt_1.8_25_nldm.lib]
create_library_set -name FF_LIBSET\
   -timing\
    [list ${::IMEX::libVar}/mmmc/sky130_ff_1.98_0_nldm.lib]
create_library_set -name SS_LIBSET\
   -timing\
    [list ${::IMEX::libVar}/mmmc/sky130_ss_1.62_125_nldm.lib]
create_rc_corner -name SS_RC\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_rc_corner -name FF_RC\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_rc_corner -name TT_RC\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_delay_corner -name FF_DELAY\
   -library_set FF_LIBSET\
   -rc_corner FF_RC
create_delay_corner -name SS_DELAY\
   -library_set SS_LIBSET\
   -rc_corner SS_RC
create_delay_corner -name TT_DELAY\
   -library_set TT_LIBSET\
   -rc_corner TT_RC
create_constraint_mode -name CONSTRAINTS\
   -sdc_files\
    [list ${::IMEX::libVar}/mmmc/FFE_synth.sdc]
create_analysis_view -name TT_VIEW -constraint_mode CONSTRAINTS -delay_corner TT_DELAY
create_analysis_view -name SS_SETUP_VIEW -constraint_mode CONSTRAINTS -delay_corner SS_DELAY
create_analysis_view -name FF_HOLD_VIEW -constraint_mode CONSTRAINTS -delay_corner FF_DELAY
set_analysis_view -setup [list SS_SETUP_VIEW] -hold [list FF_HOLD_VIEW] -leakage TT_VIEW -dynamic TT_VIEW
