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
.PHONY: genus_debug
genus_debug:
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
.PHONY: par_debug
par_debug:
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
	dve -full64 -vpd vcdplus.vpd &

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
	@echo "===== Clean Done ====="