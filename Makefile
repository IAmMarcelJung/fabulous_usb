FAMILY  = artix7
PART    = xc7a35tcpg236-1
BOARD   = basys3
PROJECT = eFPGA_top
CHIPDB  = ${ARTIX7_CHIPDB}
# Collect all Verilog files (with .v or .sv extension) recursively
ADDITIONAL_SOURCES := $(shell find . -type f \( -iname "*.v" -o -iname "*.sv" \) -not -name "eFPGA_top.v")
$(info $(ADDITIONAL_SOURCES))

# SYNTH_OPTS += -noabc
PNR_ARGS += --ignore-loops

include ../openXC7.mk

lint:
	verilator --lint-only -Wall -Wpedantic --top-module eFPGA_top *.v -IFabric/ -Ijtag/ -ITile/ -ITile/include/ -ITile/LUT4AB/ -ITile/N_term_RAM_IO/ -ITile/N_term_single/ -ITile/RAM_IO/ -ITile/S_term_RAM_IO/ -ITile/S_term_single/ -ITile/W_IO/ -Ijtag/cells/ -Ijtag/registers/ -f verilator_filelist.f   > lint.log 2>&1

.PHONY: lint
