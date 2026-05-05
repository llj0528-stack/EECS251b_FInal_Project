# ============================================================
# Final_Project Makefile
# ============================================================

SHELL := /bin/bash

# ------------------------------------------------------------
# Root
# ------------------------------------------------------------
ROOT := $(shell pwd)

# ------------------------------------------------------------
# Genus
# ------------------------------------------------------------
GENUS_DIR       := $(ROOT)/scripts/genus
GENUS_BUILD_DIR := $(ROOT)/build/genus
GENUS_LOG_DIR   := $(GENUS_BUILD_DIR)/logs

# ------------------------------------------------------------
# Innovus
# ------------------------------------------------------------
INNOVUS_DIR     := $(ROOT)
PAR_SCRIPT      := $(ROOT)/scripts/innovus/innovus.tcl
PAR_BUILD_DIR   := $(ROOT)/build/innovus
PAR_LOG_DIR     := $(PAR_BUILD_DIR)/logs

# ------------------------------------------------------------
# Simulation
# ------------------------------------------------------------
SIM_DIR  := $(ROOT)/build/simulation
TB_FILE  := $(ROOT)/tb/ffe/tb_ffe.v
RTL_FILE := $(ROOT)/rtl/ffe/FFE.v

# ------------------------------------------------------------
# Golden model simulation
# ------------------------------------------------------------
GOLDEN_SIM_DIR := $(ROOT)/build/golden_model_simulation
GOLDEN_TB_FILE := $(ROOT)/tb/golden_model/ffe_golden_model_tb.v
GOLDEN_PY_SCRIPT := $(ROOT)/reference_model/ffe/run_ffe_check.py

# ------------------------------------------------------------
# Pegasus DRC
# ------------------------------------------------------------
PEGASUS_DIR        := $(ROOT)/build/pegasus
PEGASUS_DRC_DIR    := $(PEGASUS_DIR)/drc
PEGASUS_LOG_DIR    := $(PEGASUS_DRC_DIR)/logs

GDS_FILE           := $(ROOT)/build/innovus/outputs/FFE_nomerged.gds ## choose merged or nomerged!!!
TOP_CELL           := FFE
DRC_RULE           := $(ROOT)/tech/drc/sky130_rev_0.0_1.0.drc.pvl

PEGASUS_CMD        := pegasus
PEGASUS_REVIEW_CMD := pegasusDesignReview

PEGASUS_REVIEW_CMD := pegasusDesignReview

# ------------------------------------------------------------
# Pegasus LVS
# ------------------------------------------------------------
LVS_DIR           := $(ROOT)/build/pegasus/lvs
LVS_LOG_DIR       := $(LVS_DIR)/logs
LVS_RULE          := $(ROOT)/tech/lvs/sky130.lvs.pvl
LVS_MERGED_VERILOG := $(LVS_DIR)/FFE_lvs_merged.v

# Scheme A: direct Verilog LVS
LVS_VERILOG := $(ROOT)/build/innovus/outputs/FFE_par.v
# LVS_VERILOG       := $(ROOT)/build/genus/netlist/FFE_synth.v
STDCELL_VERILOG   := $(ROOT)/tech/lvs/sky130_scl_9T.v
LVS_GDS_FILE      := $(ROOT)/build/innovus/outputs/FFE_merged.gds

# Scheme B: CDL fallback
CDL_LIB           := $(ROOT)/tech/sky130_scl_9T.cdl
# CDL_LIB := /home/ff/eecs251b/sky130/sky130A/libs.ref/sky130_fd_sc_hd/cdl/sky130_fd_sc_hd.cdl
CDL_GEN_SCRIPT    := $(ROOT)/scripts/utils/gen_ffe_cdl.py
TOP_CDL_FILE      := $(ROOT)/build/genus/netlist/FFE_top.cdl



# ------------------------------------------------------------
# Default target
# ------------------------------------------------------------
.PHONY: all
all: genus

# ------------------------------------------------------------
# Full flow
# ------------------------------------------------------------
.PHONY: flow
flow: genus par
	@echo "===== Full Flow Done ====="

# ------------------------------------------------------------
# Genus synthesis
# ------------------------------------------------------------
.PHONY: genus
genus:
	@echo "===== Running Genus Synthesis ====="
	mkdir -p $(GENUS_LOG_DIR)
	cd $(GENUS_DIR) && \
	genus -files genus.tcl | tee $(GENUS_LOG_DIR)/genus.log
	@echo "===== Genus Done ====="

# ------------------------------------------------------------
# Genus GUI (debug)
# ------------------------------------------------------------
.PHONY: genus_gui
genus_gui:
	@echo "===== Launching Genus GUI ====="
	cd $(GENUS_DIR) && \
	genus -gui

# ------------------------------------------------------------
# Innovus PAR
# ------------------------------------------------------------
.PHONY: innovus
innovus:
	@echo "===== Running Innovus PAR ====="
	mkdir -p $(PAR_LOG_DIR)
	cd $(INNOVUS_DIR) && \
	innovus -files $(PAR_SCRIPT) | tee $(PAR_LOG_DIR)/innovus.log
	@echo "===== PAR Done ====="

# ------------------------------------------------------------
# Innovus GUI (debug)
# ------------------------------------------------------------
.PHONY: innovus_gui
innovus_gui:
	@echo "===== Launching Innovus GUI ====="
	cd $(INNOVUS_DIR) && \
	innovus -files $(PAR_SCRIPT) -gui

# ------------------------------------------------------------
# VCS Simulation
# ------------------------------------------------------------
.PHONY: sim
sim:
	@echo "===== Running VCS Simulation ====="
	mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && \
	source $(ROOT)/env.sh && \
	vcs -full64 -sverilog -debug_access+all \
	$(TB_FILE) \
	$(RTL_FILE) \
	-o simv && \
	./simv
	@echo "===== Simulation Done ====="

# ------------------------------------------------------------
# VCS GUI
# ------------------------------------------------------------
.PHONY: sim_gui
sim_gui:
	@echo "===== Opening DVE ====="
	cd $(SIM_DIR) && \
	dve -full64 -vpd ffe.vpd &

# ------------------------------------------------------------
# Golden Model Simulation (RTL + Python)
# ------------------------------------------------------------
.PHONY: golden_model_sim
golden_model_sim:
	@echo "===== Running Golden Model Simulation ====="
	mkdir -p $(GOLDEN_SIM_DIR)

	cd $(GOLDEN_SIM_DIR) && \
	source $(ROOT)/env.sh && \
	vcs -full64 -sverilog -debug_access+all \
	$(GOLDEN_TB_FILE) \
	$(RTL_FILE) \
	-o simv_golden && \
	./simv_golden

	@echo "===== Running Python Golden Model Checker ====="
	cd $(ROOT) && \
	python3 $(GOLDEN_PY_SCRIPT) $(GOLDEN_SIM_DIR)

	@echo "===== Golden Model Simulation Done ====="

# ------------------------------------------------------------
# Clean simulation only
# ------------------------------------------------------------
.PHONY: clean_sim
clean_sim:
	@echo "===== Cleaning simulation build ====="
	rm -rf $(SIM_DIR)
	@echo "===== Simulation Clean Done ====="


# ------------------------------------------------------------
# Clean everything
# ------------------------------------------------------------
.PHONY: clean_innovus clean_genus clean_all

clean_innovus:
	rm -rf $(PAR_BUILD_DIR)

clean_genus:
	rm -rf $(GENUS_BUILD_DIR)

clean_all:
	@echo "===== Cleaning build ====="
	rm -rf $(GENUS_BUILD_DIR)
	rm -rf $(PAR_BUILD_DIR)
	rm -rf $(PEGASUS_DIR)
	@echo "===== Clean Done ====="

# ------------------------------------------------------------
# Pegasus DRC
# ------------------------------------------------------------
.PHONY: drc
drc:
	@echo "===== Running Pegasus DRC ====="
	mkdir -p $(PEGASUS_DRC_DIR)
	mkdir -p $(PEGASUS_LOG_DIR)
	test -f $(GDS_FILE) || (echo "ERROR: GDS file not found: $(GDS_FILE)" && exit 1)
	test -f $(DRC_RULE) || (echo "ERROR: DRC rule file not found: $(DRC_RULE)" && exit 1)
	cd $(PEGASUS_DRC_DIR) && \
	$(PEGASUS_CMD) -drc -dp 8 -license_dp_continue \
	-gds $(GDS_FILE) \
	-top_cell $(TOP_CELL) \
	-ui_data \
	$(DRC_RULE) \
	| tee $(PEGASUS_LOG_DIR)/pegasus_drc.log
	@echo "===== DRC Done ====="

# ------------------------------------------------------------
# Pegasus DRC Review GUI
# ------------------------------------------------------------
.PHONY: drc_gui
drc_gui:
	@echo "===== Opening Pegasus DRC Review ====="
	test -f $(GDS_FILE) || (echo "ERROR: GDS file not found: $(GDS_FILE)" && exit 1)
	cd $(PEGASUS_DRC_DIR) && \
	$(PEGASUS_REVIEW_CMD) -qrv -data $(GDS_FILE) &

# ------------------------------------------------------------
# Clean Pegasus DRC, LVS, Pegasus
# ------------------------------------------------------------
.PHONY: clean_drc clean
clean_drc:
	@echo "===== Cleaning Pegasus DRC ====="
	rm -rf $(PEGASUS_DRC_DIR)
	@echo "===== Pegasus DRC Clean Done ====="

.PHONY: clean_lvs clean
clean_lvs:
	@echo "===== Cleaning Pegasus LVS ====="
	rm -rf $(LVS_DIR)
	@echo "===== Pegasus LVS Clean Done ====="

.PHONY: clean_pegasus clean
clean_pegasus:
	@echo "===== Cleaning Pegasus ====="
	rm -rf $(PEGASUS_DIR)
	@echo "===== Pegasus Clean Done ====="

# ------------------------------------------------------------
# Pegasus LVS - Scheme A
# Direct gate-level Verilog source
# ------------------------------------------------------------
.PHONY: lvs
lvs:
	@echo "===== Running Pegasus LVS (Verilog source) ====="
	test -f $(LVS_VERILOG) || (echo "ERROR: source Verilog not found: $(LVS_VERILOG)" && exit 1)
	test -f $(STDCELL_VERILOG) || (echo "ERROR: stdcell Verilog not found: $(STDCELL_VERILOG)" && exit 1)
	test -f $(LVS_GDS_FILE) || (echo "ERROR: GDS file not found: $(LVS_GDS_FILE)" && exit 1)
	test -f $(LVS_RULE) || (echo "ERROR: LVS rule file not found: $(LVS_RULE)" && exit 1)
	mkdir -p $(LVS_DIR)
	mkdir -p $(LVS_LOG_DIR)
	cat $(STDCELL_VERILOG) $(LVS_VERILOG) > $(LVS_MERGED_VERILOG)
	cd $(LVS_DIR) && \
	$(PEGASUS_CMD) -lvs -dp 8 \
	-automatch \
	-check_schematic \
	-ui_data \
	-source_verilog $(LVS_MERGED_VERILOG) \
	-gds $(LVS_GDS_FILE) \
	-source_top_cell $(TOP_CELL) \
	-layout_top_cell $(TOP_CELL) \
	$(LVS_RULE) \
	| tee $(LVS_LOG_DIR)/lvs.log

# ------------------------------------------------------------
# Pegasus LVS - Scheme B
# Generate top-level CDL for LVS
# ------------------------------------------------------------
.PHONY: lvs_cdl_netlist
lvs_cdl_netlist:
	@echo "===== Generating top-level CDL for LVS ====="
	test -f $(CDL_GEN_SCRIPT) || (echo "ERROR: CDL generator script not found: $(CDL_GEN_SCRIPT)" && exit 1)
	test -f $(LVS_VERILOG) || (echo "ERROR: synth Verilog not found: $(LVS_VERILOG)" && exit 1)
	test -f $(CDL_LIB) || (echo "ERROR: CDL library not found: $(CDL_LIB)" && exit 1)
	mkdir -p $(ROOT)/build/genus/netlist
	python3 $(CDL_GEN_SCRIPT) \
		--verilog $(LVS_VERILOG) \
		--cdl-lib $(CDL_LIB) \
		--out $(TOP_CDL_FILE) \
		--top $(TOP_CELL)
	@echo "===== CDL netlist generated: $(TOP_CDL_FILE) ====="

# ------------------------------------------------------------
# LVS using generated CDL + merged GDS
# ------------------------------------------------------------
.PHONY: lvs_cdl
lvs_cdl: lvs_cdl_netlist
	@echo "===== Running CDL-based LVS ====="
	test -f $(TOP_CDL_FILE) || (echo "ERROR: top CDL file not found: $(TOP_CDL_FILE)" && exit 1)
	test -f $(LVS_GDS_FILE) || (echo "ERROR: GDS file not found: $(LVS_GDS_FILE)" && exit 1)
	test -f $(LVS_RULE) || (echo "ERROR: LVS rule file not found: $(LVS_RULE)" && exit 1)
	mkdir -p $(LVS_DIR)
	mkdir -p $(LVS_LOG_DIR)
	cd $(LVS_DIR) && \
	$(PEGASUS_CMD) -lvs -dp 8 \
	-automatch \
	-check_schematic \
	-ui_data \
	-source_cdl $(TOP_CDL_FILE) \
	-gds $(LVS_GDS_FILE) \
	-source_top_cell $(TOP_CELL) \
	-layout_top_cell $(TOP_CELL) \
	$(LVS_RULE) \
	| tee $(LVS_LOG_DIR)/lvs_cdl.log
	@echo "===== CDL-based LVS Done ====="
