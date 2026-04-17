create_clock -name clk -period 8.0 [get_ports clk]

set_input_delay  1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]

set_false_path -from [get_ports rst_n]