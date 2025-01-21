FAMILY  = artix7
PART    = xc7a35tcpg236-1
BOARD   = basys3
PROJECT = eFPGA_top
CHIPDB  = ${ARTIX7_CHIPDB}
# Collect all Verilog files (with .v or .sv extension) recursively
ADDITIONAL_SOURCES := $(shell find . -type f \( -iname "*.v" -o -iname "*.sv" \) -not -name "eFPGA_top.v")
$(info $(ADDITIONAL_SOURCES))


include ../openXC7.mk
