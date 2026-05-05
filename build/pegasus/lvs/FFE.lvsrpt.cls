##############################################################################################################
#####  
#####                                       Pegasus LVS COMPARISON
#####  
#####  Version                       :   22.14-s007
#####  NVN Run Start                 :   Mon May  4 19:35:31 2026
#####  ERC Summary File              :   result.sum
#####  Extraction Report File        :   FFE.lvsrpt
#####  Comparison Report File        :   FFE.lvsrpt.cls
#####  Top Cell                      :   FFE  <vs>  FFE
#####  
#####  Run Result                    :   MATCH
#####  
#####  Run Summary                   :   [INFO]  ERC Results: Empty
#####                                :   [INFO]  Extraction Clean
#####                                :   [INFO]  Cells Have Been Blackboxed
#####                                :   [INFO]  Some Sections Have Been Truncated
#####  
#####  Layout Design                 :   /scratch/eecs251b-abi/project/EECS251b_FInal_Project/build/innovus/outputs/FFE_nomerged.gds (GDSII)
#####  Layout File                   :   FFE.net (cdl)
#####  Schematic File                :   ../../genus/netlist/FFE_top.cdl (cdl)
#####  Rules File                    :   /scratch/eecs251b-abi/project/EECS251b_FInal_Project/build/pegasus/lvs/../../../tech/lvs/sky130.lvs.pvl
#####  Pin Swap File                 :   FFE.lvsrpt.cps
#####  
#####  Extraction CPU Time           :   0h 0m 3s - (3s)
#####  Extraction Exec Time          :   0h 0m 12s - (12s)
#####  Extraction Peak Memory Usage  :   147.00MB
#####  NVN CPU Time                  :   0h 0m 0s - (0s)                 
#####  NVN Exec Time                 :   0h 0m 1s - (1s)                 
#####  NVN Peak Memory Usage         :   517.02MB
#####  LVS Total CPU Time            :   0h 0m 3s - (3s)                 
#####  LVS Total Exec Time           :   0h 0m 13s - (13s)               
#####  LVS Total Peak Memory Usage   :   517.02MB
#####  
##############################################################################################################


##############################################################################################################
#
#                                            CELL MATCH STATISTICS                                            
#
##############################################################################################################

Cell Statistic Descriptions                  | Count
---------------------------------------------+----------
Cells matched                                |        62
Cells expanded                               |         0
Cells not run                                |         0
Cells which mismatch                         |         0
---------------------------------------------+----------
Total                                        |        62


Cell Statistic Detail                        | Count
---------------------------------------------+----------
Cells with parameter mismatches              |         0
Cells with mismatched instance subtypes      |         0
Cells that have been blackboxed              |        61


##############################################################################################################
#
#                                             CELL MATCH SUMMARY                                              
#
##############################################################################################################

              |     Initial Pins     |     Compare Pins     |            | 
Cell          |   lay    :    sch    |   lay    :    sch    | Status     | Detail
--------------+----------+-----------+----------+-----------+------------+--------------
NAND3X4       |        6 :         6 |        6 :         6 | match      | black box
BUFX2         |        4 :         4 |        4 :         4 | match      | black box
BUFX16        |        4 :         4 |        4 :         4 | match      | black box
CLKAND2X2 .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
NAND2X4       |        5 :         5 |        5 :         5 | match      | black box
NAND3X2   .  .|.  .  . 6 :.  .  .  6 |.  .  . 6 :.  .  .  6 | match  .  .| black box
OAI22X1       |        7 :         7 |        7 :         7 | match      | black box
CLKBUFX4  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
OAI21X2       |        6 :         6 |        6 :         6 | match      | black box
CLKINVX2  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
INVX8         |        4 :         4 |        4 :         4 | match      | black box
INVX2  .  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
CLKINVX4      |        4 :         4 |        4 :         4 | match      | black box
BUFX8  .  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
CLKINVX8      |        4 :         4 |        4 :         4 | match      | black box
INVX4  .  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
CLKINVX1      |        4 :         4 |        4 :         4 | match      | black box
CLKMX2X2  .  .|.  .  . 6 :.  .  .  6 |.  .  . 6 :.  .  .  6 | match  .  .| black box
OAI21X1       |        6 :         6 |        6 :         6 | match      | black box
CLKXOR2X1 .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
NAND2X1       |        5 :         5 |        5 :         5 | match      | black box
OR2X1  .  .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
NAND2X2       |        5 :         5 |        5 :         5 | match      | black box
XNOR2X1   .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
CLKBUFX8      |        4 :         4 |        4 :         4 | match      | black box
OAI221X1  .  .|.  .  . 8 :.  .  .  8 |.  .  . 8 :.  .  .  8 | match  .  .| black box
NAND3X1       |        6 :         6 |        6 :         6 | match      | black box
AOI22X1   .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
AND2X1        |        5 :         5 |        5 :         5 | match      | black box
NOR2X1 .  .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
AOI21X1       |        6 :         6 |        6 :         6 | match      | black box
OAI22X2   .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
AOI21X2       |        6 :         6 |        6 :         6 | match      | black box
BUFX4  .  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
CLKBUFX2      |        4 :         4 |        4 :         4 | match      | black box
INVX16 .  .  .|.  .  . 4 :.  .  .  4 |.  .  . 4 :.  .  .  4 | match  .  .| black box
OAI221X2      |        8 :         8 |        8 :         8 | match      | black box
OAI211X2  .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
NOR3X1        |        6 :         6 |        6 :         6 | match      | black box
NAND4X2   .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
OAI211X1      |        7 :         7 |        7 :         7 | match      | black box
OR2X2  .  .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
AOI22X2       |        7 :         7 |        7 :         7 | match      | black box
NAND4X1   .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
AOI221X2      |        8 :         8 |        8 :         8 | match      | black box
NAND4X4   .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
OAI222X1      |        9 :         9 |        9 :         9 | match      | black box
NOR2X2 .  .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
MX2X1         |        6 :         6 |        6 :         6 | match      | black box
AND3X2 .  .  .|.  .  . 6 :.  .  .  6 |.  .  . 6 :.  .  .  6 | match  .  .| black box
OAI222X2      |        9 :         9 |        9 :         9 | match      | black box
OR3X1  .  .  .|.  .  . 6 :.  .  .  6 |.  .  . 6 :.  .  .  6 | match  .  .| black box
AND2X2        |        5 :         5 |        5 :         5 | match      | black box
DFFRX1 .  .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
DFFRX4        |        7 :         7 |        7 :         7 | match      | black box
ADDFX1 .  .  .|.  .  . 7 :.  .  .  7 |.  .  . 7 :.  .  .  7 | match  .  .| black box
INVX1         |        4 :         4 |        4 :         4 | match      | black box
ADDHX1 .  .  .|.  .  . 6 :.  .  .  6 |.  .  . 6 :.  .  .  6 | match  .  .| black box
XOR2X2        |        5 :         5 |        5 :         5 | match      | black box
NOR2X4 .  .  .|.  .  . 5 :.  .  .  5 |.  .  . 5 :.  .  .  5 | match  .  .| black box
XOR2X4        |        5 :         5 |        5 :         5 | match      | black box
FFE           |      193 :       193 |      193 :       193 | match      | truncated


##############################################################################################################
#
#                                                  LVS RULES                                                  
#
##############################################################################################################

Command Line LVS Rule Values
----------------------------

    lvs_cname                               yes -cell {-automatch}
    layout_primary                          FFE {-layout_top_cell FFE}
    layout_path                             ../../../tech/lvs/sky130_scl_9T_abstract.gds {-gds
                                            ../../../tech/lvs/sky130_scl_9T_abstract.gds}
    layout_format                           GDSII {-gds ../../../tech/lvs/sky130_scl_9T_abstract.gds}
    layout_path                             /scratch/eecs251b-abi/project/EECS251b_FInal_Project/build/innovus/outputs/FFE_nomerged.gds
                                            {-gds ../../../tech/lvs/sky130_scl_9T_abstract.gds}
    layout_format                           GDSII {-gds ../../../tech/lvs/sky130_scl_9T_abstract.gds}
    schematic_primary                       FFE {-source_top_cell FFE}
    schematic_path                          ../../genus/netlist/FFE_top.cdl {-source_cdl
                                            ../../genus/netlist/FFE_top.cdl}
    schematic_format                        CDL {-source_cdl ../../genus/netlist/FFE_top.cdl}

LVS Rules Given in the Rules File
---------------------------------

    layout_path                             ./sky130_fd_sc_ls__bufinv_16.gds
    layout_format                           gdsii
    layout_primary                          sky130_fd_sc_ls__bufinv_16
    lvs_black_box                           cap_vpp_02p4x04p6_m1m2_noshield -grey
    lvs_black_box                           cap_vpp_04p4x04p6_m1m2_noshield -grey
    lvs_black_box                           cap_vpp_04p4x04p6_m1m2m3_shieldl1 -grey
    lvs_black_box                           cap_vpp_08p6x07p8_m1m2_noshield -grey
    lvs_black_box                           cap_vpp_08p6x07p8_m1m2m3_shieldl1 -grey
    lvs_black_box                           cap_vpp_08p6x07p8_m1m2m3_shieldl1m5_floatm4 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_l1m1m2_shieldpom3 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_l1m1m2m3_shieldm4 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_l1m1m2m3_shieldpom4 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_l1m1m2m3m4_shieldm5 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_l1m1m2m3m4_shieldpom5 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_m1m2_noshield -grey
    lvs_black_box                           cap_vpp_11p5x11p7_m1m2m3_shieldl1 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5 -grey
    lvs_black_box                           cap_vpp_11p5x11p7_m1m2m3m4_shieldm5 -grey
    lvs_black_box                           ADDFX1
    lvs_black_box                           ADDHX1
    lvs_black_box                           AND2X1
    lvs_black_box                           AND2X2
    lvs_black_box                           AOI21X1
    lvs_black_box                           AOI21X2
    lvs_black_box                           AOI22X1
    lvs_black_box                           AOI22X2
    lvs_black_box                           BUFX16
    lvs_black_box                           BUFX2
    lvs_black_box                           BUFX4
    lvs_black_box                           BUFX8
    lvs_black_box                           CLKAND2X2
    lvs_black_box                           CLKBUFX2
    lvs_black_box                           CLKBUFX4
    lvs_black_box                           CLKBUFX8
    lvs_black_box                           CLKINVX1
    lvs_black_box                           CLKINVX2
    lvs_black_box                           CLKINVX4
    lvs_black_box                           CLKINVX8
    lvs_black_box                           CLKMX2X2
    lvs_black_box                           CLKXOR2X1
    lvs_black_box                           DFFRX1
    lvs_black_box                           DFFRX4
    lvs_black_box                           INVX1
    lvs_black_box                           INVX16
    lvs_black_box                           INVX2
    lvs_black_box                           INVX4
    lvs_black_box                           INVX8
    lvs_black_box                           MX2X1
    lvs_black_box                           NAND2X1
    lvs_black_box                           NAND2X2
    lvs_black_box                           NAND2X4
    lvs_black_box                           NAND3X1
    lvs_black_box                           NAND3X2
    lvs_black_box                           NAND3X4
    lvs_black_box                           NAND4X1
    lvs_black_box                           NAND4X2
    lvs_black_box                           NAND4X4
    lvs_black_box                           NOR2X1
    lvs_black_box                           NOR2X2
    lvs_black_box                           NOR2X4
    lvs_black_box                           NOR3X1
    lvs_black_box                           OAI211X1
    lvs_black_box                           OAI211X2
    lvs_black_box                           OAI21X1
    lvs_black_box                           OAI21X2
    lvs_black_box                           OAI221X1
    lvs_black_box                           OAI221X2
    lvs_black_box                           OAI222X1
    lvs_black_box                           OAI222X2
    lvs_black_box                           OAI22X1
    lvs_black_box                           OAI22X2
    lvs_black_box                           OR2X1
    lvs_black_box                           OR2X2
    lvs_black_box                           OR3X1
    lvs_black_box                           XNOR2X1
    lvs_black_box                           XOR2X2
    lvs_black_box                           XOR2X4
    lvs_black_box                           AND3X2
    lvs_black_box                           AOI221X2
                                             
    lvs_cdn_flow_options                    -cdl_use_scale
                                             
    lvs_reduce_split_gates                  no  
    lvs_recognize_gates                     -none
    lvs_recognize_gates                     -none
    lvs_reduce                              yes -parallel_mos
    lvs_reduce                              yes -series_mos
                                             
    lvs_check_property                      MP L l
    lvs_check_property                      MP W w
    lvs_check_property                      MN L l
    lvs_check_property                      MN W w
    lvs_check_property                      R W W
    lvs_check_property                      R L L
    lvs_check_property                      C L L
    lvs_check_property                      C W W
    lvs_report_file                         FFE.lvsrpt
    lvs_short_equivalent_nodes              yes
    lvs_generic_device                      C ( cap_vpp_02p4x04p6_m1m2_noshield ) [ PLUS = C0 MINUS = C1 BULK
                                            = B ] -source
    lvs_generic_device                      C ( cap_vpp_04p4x04p6_m1m2_noshield ) [ PLUS = C0 MINUS = C1 BULK
                                            = B ] -source
    lvs_generic_device                      C ( cap_vpp_04p4x04p6_m1m2m3_shieldl1 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_08p6x07p8_m1m2_noshield ) [ PLUS = C0 MINUS = C1 BULK
                                            = B ] -source
    lvs_generic_device                      C ( cap_vpp_08p6x07p8_m1m2m3_shieldl1 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_08p6x07p8_m1m2m3_shieldl1m5_floatm4 ) [ PLUS = C0
                                            MINUS = C1 BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_l1m1m2_shieldpom3 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_l1m1m2m3_shieldm4 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_l1m1m2m3_shieldpom4 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_l1m1m2m3m4_shieldm5 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_l1m1m2m3m4_shieldpom5 ) [ PLUS = C0 MINUS =
                                            C1 BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_m1m2_noshield ) [ PLUS = C0 MINUS = C1 BULK
                                            = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_m1m2m3_shieldl1 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    lvs_generic_device                      C ( cap_vpp_11p5x11p7_m1m2m3m4_shieldm5 ) [ PLUS = C0 MINUS = C1
                                            BULK = B ] -source
    text_depth                              -primary
                                             

Default LVS Rule Values
-----------------------

    lvs_abort                               -softchk no
    lvs_abort                               -supply_error no
    lvs_abort                               -check_device_for_property_rule no
    lvs_abort                               -missing_hcell no
    lvs_abort                               -erc_error yes
    lvs_abort                               -inconsistent_reduction yes
    layout_case_sensitive                   no
    // layout_cpf_file                       
    // schematic_cpf_file                    
    schematic_case_sensitive                no
    // hcell_file                            
    // hcell                                 
    // lvs_exclude_hcell                     
    // lvs_delete_cell                       
    lvs_push_devices                        yes
    lvs_push_devices_properties             no
    lvs_netlist                             yes -substrate_comment
    lvs_netlist                             yes -box_contents
    lvs_netlist                             yes -unnamed_box_pins
    lvs_netlist                             no -allow_inconsistent_model
    lvs_netlist                             yes -properties_comment
    // lvs_write_netlist                     
    // lvs_write_netlist_reduced             
    // lvs_delete_cell_pin                   
    // lvs_interposer                        
    lvs_spice                               yes -allow_floating_pins
    lvs_spice                               yes -allow_duplicate_subcircuit_names
    lvs_spice                               no  -conditional_ldd
    lvs_spice                               no  -prefer_pins
    lvs_spice                               no  -override_globals
    lvs_spice                               no  -redefine_param
    lvs_spice                               no  -replicate_devices
    lvs_spice                               no  -replicate_devices_enhanced
    lvs_spice                               yes -slash_is_space
    lvs_spice                               yes -keep_back_slash
    lvs_spice                               no  -allow_unquoted_strings
    lvs_spice                               no  -allow_inline_parameters
    lvs_spice                               no  -calculate_mos_area
    lvs_spice                               no  -strict_wl
    lvs_spice                               no  -cull_primitive_subcircuits
    lvs_spice                               no  -ignore_option_scale
    lvs_spice                               no  -show_neg_param_warning
    lvs_spice                               no  -scale_x_parameters
    lvs_spice                               yes -strict_subckts_order
    // lvs_spice_option                      
    lvs_reverse_wl                          no
    // lvs_spice_multiplier_name             
                                             
    lvs_compare_case                        no
    lvs_cname                               yes -pin
    lvs_cname                               yes -net
    lvs_cname                               no  -instance
    lvs_non_user_name                       -port "^[0-9]+$"
    lvs_non_user_name                       -net  "^[0-9]+$"
    // lvs_non_user_name                    -instance 
    lvs_out_of_range_exclude_zero           no
    // lvs_group_models                      
    lvs_strict_subtypes                     no
    lvs_exact_subtypes                      no
    lvs_preserve_box_ports                  no
    // lvs_cpoint                            
    // lvs_power_name                        
    // lvs_ground_name                       
    // lvs_cell_list                         
    // lvs_device_type                       
                                             
    lvs_auto_pin_swap                       yes -swap_threshold 4000000
    lvs_swap_non_cpoint_pins                yes
    // lvs_swap_pins                         
    lvs_all_cap_pins_swappable              no
    lvs_builtin_device_pin_swap             yes
    // lvs_join_nets                         
    lvs_ignore_ports                        no
    lvs_compare_port_names                  no
    lvs_find_shorts                         no
    lvs_global_sigs_are_ports               yes
    lvs_discard_pins                        no
    lvs_break_ambig_max                     32
                                             
    lvs_filter                              no  -bipolar
    lvs_filter                              no  -capacitors
    lvs_filter                              no  -diodes
    lvs_filter                              no  -mos
    lvs_filter                              no  -resistors
    // lvs_filter_option                     
    // lvs_filter_device                     
                                             
    lvs_reduction_priority                  -parallel
    lvs_derive_logic                        yes -sram
    lvs_derive_logic                        no  -dram
    lvs_derive_logic                        no  -rom
    // lvs_recognize_gates_tolerance         
    lvs_reduce                              yes -parallel_bipolar
    lvs_reduce                              yes -parallel_caps
    lvs_reduce                              yes -series_caps
    lvs_reduce                              yes -parallel_diodes
    lvs_reduce                              no  -series_diodes
    lvs_reduce                              yes -parallel_resistors
    lvs_reduce                              yes -series_resistors
    // lvs_reduce_device                     
    // lvs_reduce_do_not_merge               
                                             
    lvs_expand_on_device_climbing           no
    lvs_expand_unbalanced_cells             yes
    lvs_expand_cell_on_error                no
                                             
    // lvs_check_all_properties_by_name      
    // lvs_property_map                      
    // lvs_transfer_property                 
    lvs_report_max                          50 -mismatched_net_limit 100
    lvs_warn_max                            50
    lvs_inconsistent_reduction_threshold    1000000
    // lvs_report_opt                        
    lvs_report_units                        yes
    lvs_keep_data                           no
    lvs_keep_source_cells                   no
    lvs_create_match_db                     no
    // lvs_map_device                        
    unit                                    -length u
    unit                                    -resistance ohm
    unit                                    -capacitance pf
    lvs_verilog_bus_map_by_position         no
    lvs_verilog_keep_backslash              no
    lvs_verilog_detect_buses                no
    lvs_do_not_normalize                    no
    input_scale                             1000
    virtual_connect                         no  -colon
    virtual_connect                         yes -semicolon_as_colon
    virtual_connect                         -depth primary
    // virtual_connect                      -name 
    virtual_connect                         no -report
    virtual_connect                         no -incremental
    lvs_preserve_parameterized_cells        no
    lvs_check_color                         no
    // lvs_schematic_color_path              
    // lvs_assign_conflict_layer             
    // lvs_conflict_layer_check             
    lvs_check_color_label                   no
    // lvs_preserve_cells                    
    port                                    -depth -primary
                                             

Effective LVS Rule Values
-------------------------

    lvs_swap_non_cpoint_pins                yes -unbound_pin_threshold 10000
    layout_path                             /scratch/eecs251b-abi/project/EECS251b_FInal_Project/build/innovus/outputs/FFE_nomerged.gds
    layout_format                           GDSII
    layout_primary                          FFE
    lvs_recognize_gates                     -none


##############################################################################################################
#
#                                               CELL COMPARISON                                               
#
##############################################################################################################

                              +------------------------------------------------+
                              |                                                |
                              |        ------->>>   MATCH   <<<-------         |
                              |                                                |
                              |                 FFE  <vs>  FFE                 |
                              |                                                |
                              |                                                |
                              +------------------------------------------------+
                              | * Some sections truncated                      |
                              +------------------------------------------------+

+===[FFE]=====================================================================================================
|                                                 STATISTICS                                                  
+=============================================================================================================


              |        Original         |        Reduced         
Cell          |    lay     :    sch     |    lay     :    sch
--------------+------------+------------+------------+-----------
ADDFX1        |      1,273 :      1,273 |      1,273 :      1,273
ADDHX1        |         12 :         12 |         12 :         12
AND2X1        |         41 :         41 |         41 :         41
AND2X2 .  .  .|.  .  .   1 :.  .  .   1 |.  .  .   1 :.  .  .   1
AND3X2        |          1 :          1 |          1 :          1
AOI21X1   .  .|.  .  . 377 :.  .  . 377 |.  .  . 377 :.  .  . 377
AOI21X2       |         18 :         18 |         18 :         18
AOI221X2  .  .|.  .  .   1 :.  .  .   1 |.  .  .   1 :.  .  .   1
AOI22X1       |        653 :        653 |        653 :        653
AOI22X2   .  .|.  .  .  44 :.  .  .  44 |.  .  .  44 :.  .  .  44
BUFX16        |          1 :          1 |          1 :          1
BUFX2  .  .  .|.  .  . 491 :.  .  . 491 |.  .  . 491 :.  .  . 491
BUFX4         |         54 :         54 |         54 :         54
BUFX8  .  .  .|.  .  .  10 :.  .  .  10 |.  .  .  10 :.  .  .  10
CLKAND2X2     |        132 :        132 |        132 :        132
CLKBUFX2  .  .|.  .  .   2 :.  .  .   2 |.  .  .   2 :.  .  .   2
CLKBUFX4      |         77 :         77 |         77 :         77
CLKBUFX8  .  .|.  .  .  63 :.  .  .  63 |.  .  .  63 :.  .  .  63
CLKINVX1      |         71 :         71 |         71 :         71
CLKINVX2  .  .|.  .  . 578 :.  .  . 578 |.  .  . 578 :.  .  . 578
CLKINVX4      |         46 :         46 |         46 :         46
CLKINVX8  .  .|.  .  .  18 :.  .  .  18 |.  .  .  18 :.  .  .  18
CLKMX2X2      |          2 :          2 |          2 :          2
CLKXOR2X1 .  .|.  .  1,232 :.  .  1,232 |.  .  1,232 :.  .  1,232
DFFRX1        |        869 :        869 |        869 :        869
DFFRX4 .  .  .|.  .  .  74 :.  .  .  74 |.  .  .  74 :.  .  .  74
INVX1         |        512 :        512 |        512 :        512
INVX16 .  .  .|.  .  .   2 :.  .  .   2 |.  .  .   2 :.  .  .   2
INVX2         |        406 :        406 |        406 :        406
INVX4  .  .  .|.  .  .   9 :.  .  .   9 |.  .  .   9 :.  .  .   9
INVX8         |         32 :         32 |         32 :         32
MX2X1  .  .  .|.  .  . 924 :.  .  . 924 |.  .  . 924 :.  .  . 924
NAND2X1       |      1,250 :      1,250 |      1,250 :      1,250
NAND2X2   .  .|.  .  . 175 :.  .  . 175 |.  .  . 175 :.  .  . 175
NAND2X4       |         42 :         42 |         42 :         42
NAND3X1   .  .|.  .  .  33 :.  .  .  33 |.  .  .  33 :.  .  .  33
NAND3X2       |         29 :         29 |         29 :         29
NAND3X4   .  .|.  .  .  14 :.  .  .  14 |.  .  .  14 :.  .  .  14
NAND4X1       |          5 :          5 |          5 :          5
NAND4X2   .  .|.  .  .   7 :.  .  .   7 |.  .  .   7 :.  .  .   7
NAND4X4       |          5 :          5 |          5 :          5
NOR2X1 .  .  .|.  .  . 581 :.  .  . 581 |.  .  . 581 :.  .  . 581
NOR2X2        |         27 :         27 |         27 :         27
NOR2X4 .  .  .|.  .  .  16 :.  .  .  16 |.  .  .  16 :.  .  .  16
NOR3X1        |         34 :         34 |         34 :         34
OAI211X1  .  .|.  .  .  12 :.  .  .  12 |.  .  .  12 :.  .  .  12
OAI211X2      |          6 :          6 |          6 :          6
OAI21X1   .  .|.  .  . 343 :.  .  . 343 |.  .  . 343 :.  .  . 343
OAI21X2       |         49 :         49 |         49 :         49
OAI221X1  .  .|.  .  .   3 :.  .  .   3 |.  .  .   3 :.  .  .   3
OAI221X2      |          1 :          1 |          1 :          1
OAI222X1  .  .|.  .  .   7 :.  .  .   7 |.  .  .   7 :.  .  .   7
OAI222X2      |          2 :          2 |          2 :          2
OAI22X1   .  .|.  .  . 696 :.  .  . 696 |.  .  . 696 :.  .  . 696
OAI22X2       |         33 :         33 |         33 :         33
OR2X1  .  .  .|.  .  . 192 :.  .  . 192 |.  .  . 192 :.  .  . 192
OR2X2         |         47 :         47 |         47 :         47
OR3X1  .  .  .|.  .  .   2 :.  .  .   2 |.  .  .   2 :.  .  .   2
XNOR2X1       |         87 :         87 |         87 :         87
XOR2X2        |          7 :          7 |          7 :          7
XOR2X4        |          5 :          5 |          5 :          5
--------------+------------+------------+------------+-----------
Total         |     11,736 :     11,736 |     11,736 :     11,736
==============+============+============+============+===========
Pins          |            :            |        193 :        193
Nets          |            :            |     13,881 :     13,881
==============+============+============+============+===========

+===[FFE]=====================================================================================================
|                                           INITIAL CORRESPONDENCES                                           
+====================================================================================================truncated

Type | Name
-----+--------------------------------------------------------------------------------------------------------
Pin  | clk coeff_bus[0] coeff_bus[10] coeff_bus[11] coeff_bus[12] coeff_bus[13] coeff_bus[14] coeff_bus[15]
     | coeff_bus[16] coeff_bus[17] coeff_bus[18] coeff_bus[19] coeff_bus[1] coeff_bus[20] coeff_bus[21]
     | coeff_bus[22] coeff_bus[23] coeff_bus[24] coeff_bus[25] coeff_bus[26] coeff_bus[27] coeff_bus[28]
     | coeff_bus[29] coeff_bus[2] coeff_bus[30] coeff_bus[31] coeff_bus[32] coeff_bus[33] coeff_bus[34]
     | coeff_bus[35] coeff_bus[36] coeff_bus[37] coeff_bus[38] coeff_bus[39] coeff_bus[3] coeff_bus[40]
     | coeff_bus[41] coeff_bus[42] coeff_bus[43] coeff_bus[44] coeff_bus[45] coeff_bus[46] coeff_bus[47]
     | coeff_bus[48] coeff_bus[49] coeff_bus[4] coeff_bus[50] coeff_bus[51] coeff_bus[52] coeff_bus[53]


++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++ Section truncated to 50 issues, adjust this using the lvs_report_max rule +++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


##############################################################################################################
#
#                                                END OF REPORT                                                
#
##############################################################################################################

