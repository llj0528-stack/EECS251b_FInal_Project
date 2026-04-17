# 1. Running Genus Synthesis

To run synthesis for the `FFE` module from the project root directory:

```bash
source env.sh
make genus
```

This flow reads the RTL, loads the SKY130 standard-cell library, applies the timing constraints in constraints/ffe.sdc, and runs syn_generic, syn_map, and syn_opt. If synthesis completes successfully, the main outputs are generated under:

build/genus/netlist/FFE_synth.v
build/genus/netlist/FFE_synth.sdc
build/genus/reports/

The generated FFE_synth.v confirms that synthesis has completed and that a gate-level netlist has been produced.

# 2. Viewing the Design in Genus GUI

To launch the Genus GUI:

```bash
source env.sh
make genus_debug
```

or equivalently:

```bash
genus -gui
```

inside the GUI command window, run the following tcl script: 

```genus
set_db library [list /home/ff/eecs251b/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib]

read_hdl /scratch/eecs251b-aaj/Final_Project/build/genus/netlist/FFE_synth.v

elaborate FFE

current_design FFE
```

Then open genus GUI, choose "schematic" after clicking the "+" button next to "Layout". 

# 3. Running simulation by using vcs
Run 

```bash
source env.sh
make sim
```

in the ```scratch/eecs251b-aaj/Final_Project``` directory. 

# 4. Run PAR
Run 

```bash
make innovus
```

# 4. Open different layout result in PAR process
e.g. Open the final result: Open Innovus first

```bash
innovus
```

Then in the innovus terminal, run

```innovus
restoreDesign ./build/innovus/db/FFE_final.enc.dat FFE
```