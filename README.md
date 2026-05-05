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

in the ```scratch/eecs251b-aaj/Final_Project``` directory, Which will generate ```/scratch/eecs251b-aaj/Final_Project/build/simulation/ffe.vpd``` waveform file. If you want to view the waveform by using DVE(Synopsys), run

```bash
make sim_gui
```

and add signals to waveform viewer. 


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

# Run DRC
Run
```bash
make drc
```
If you want to open the result in Pegasus GUI, run
```bash
make drc_gui
```
and click Pegasus -> Open Run -> Select file "xxx.drc_errors.ascii" to open the DRC result.

# Run LVS
Run LVS after Genus and Innovus have completed.

To generate the top-level CDL netlist used by Pegasus LVS, run:

```bash
make lvs_cdl_netlist
```

This generates:

```text
build/genus/netlist/FFE_top.cdl
```

The CDL generator reads the Innovus post-PAR Verilog netlist, preserves bracketed bus names, expands the top-level FFE ports, and emits standard-cell instances.

LVS uses the non-merged Innovus GDS together with a LEF-derived abstract standard-cell GDS. If the abstract GDS needs to be regenerated, run:

```bash
python3 scripts/utils/lef_to_stdcell_abstract_gds.py \
  tech/lef/sky130_scl_9T.lef \
  tech/lvs/sky130_scl_9T_abstract.gds
```

The abstract GDS provides standard-cell pin geometry for LVS without including the full transistor-level standard-cell internals. The standard cells are blackboxed in the Pegasus LVS deck so that LVS checks top-level standard-cell connectivity.

Then run LVS:

```bash
make lvs_cdl
```

The main Pegasus LVS report is:

```text
build/pegasus/lvs/FFE.lvsrpt.cls
```
