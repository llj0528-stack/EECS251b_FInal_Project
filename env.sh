#!/bin/bash

# ==========================================
# Cadence EDA environment setup
# ==========================================

# Cadence base path
export CADENCE_HOME=/share/instsww/cadence

# Genus
export GENUS_HOME=$CADENCE_HOME/GENUS231
export PATH=$GENUS_HOME/bin:$PATH

# Innovus (optional, useful later)
export INNOVUS_HOME=$CADENCE_HOME/INNOVUS231
export PATH=$INNOVUS_HOME/bin:$PATH

# Spectre (optional)
export SPECTRE_HOME=$CADENCE_HOME/SPECTRE231
export PATH=$SPECTRE_HOME/bin:$PATH

# Print confirmation
echo "--------------------------------------"
echo "Cadence environment loaded"
echo "GENUS_HOME   = $GENUS_HOME"
echo "INNOVUS_HOME = $INNOVUS_HOME"
echo "--------------------------------------"