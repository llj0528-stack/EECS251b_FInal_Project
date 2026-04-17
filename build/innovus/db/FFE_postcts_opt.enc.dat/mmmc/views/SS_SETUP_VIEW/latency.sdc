set_clock_latency -source -early -max -rise  -0.726195 [get_ports {clk}] -clock clk 
set_clock_latency -source -early -max -fall  -0.763068 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -rise  -0.726195 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -fall  -0.763068 [get_ports {clk}] -clock clk 
