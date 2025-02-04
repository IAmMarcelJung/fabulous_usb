FAMILY  = artix7
PART    = xc7a35tcpg236-1
BOARD   = basys3
PROJECT = top
CHIPDB  = ${ARTIX7_CHIPDB}



SYNTH_OPTS += -json -noscopeinfo
PNR_ARGS += --ignore-loops -f

MAX_BITBYTES=16384

# Define directories
TB_DIR := ./tb
TB_BUILD_DIR := $(TB_DIR)/build
TB_EFPGA_MODULE := eFPGA_top_tb
TB_EFPGA_FILENAME := ${TB_EFPGA_MODULE}.v
TB_EFPGA_FILE := ${TB_DIR}/${TB_EFPGA_MODULE}.v
SIM_EFPGA_OUTPUT_FILE := ./build/${TB_EFPGA_MODULE}.vvp
TB_EFPGA_SOURCES := $(shell find . -type f \( -iname "*.v" -o -iname "*.sv" \)  -not -path "./jtag/*" -not -path "*./Tile/gl/*")

TB_TOP_MODULE := top_tb
TB_TOP_FILENAME := ${TB_TOP_MODULE}.v
TB_TOP_FILE := ${TB_DIR}/${TB_TOP_MODULE}.v
SIM_TOP_OUTPUT_FILE := ./build/${TB_TOP_MODULE}.vvp
TB_TOP_SOURCES := $(shell find . -type f \( -iname "*.v" -o -iname "*.sv" \)   -not -path "./jtag/*" -not -path "*./Tile/gl/*")

DESIGN=counter
DESIGN_BITSTREAM=${TB_DIR}/${DESIGN}.bin
DESIGN_BITSTREAM_HEX=${TB_BUILD_DIR}/${DESIGN}.hex

TOP_TEST_DESIGN=test_design
TOP_TEST_DESIGN_BITSTREAM=${TB_DIR}/${TOP_TEST_DESIGN}.bin
TOP_TEST_DESIGN_BITSTREAM_HEX=${TB_BUILD_DIR}/${TOP_TEST_DESIGN}.hex

include ../openXC7.mk

$(TB_BUILD_DIR):
	mkdir -p $(TB_BUILD_DIR)

lint:
	verilator --lint-only -Wall -Wpedantic --top-module top *.v -IFabric/  -ITile/ -ITile/include/ -ITile/LUT4AB/ -ITile/N_term_RAM_IO/ -ITile/N_term_single/ -ITile/RAM_IO/ -ITile/S_term_RAM_IO/ -ITile/S_term_single/ -ITile/W_IO/ -Iclocking/ -f verilator_filelist.f > lint.log 2>&1

sim_eFPGA: $(TB_BUILD_DIR)
	iverilog -s ${TB_EFPGA_MODULE} -o ./tb/${SIM_EFPGA_OUTPUT_FILE}  ${TB_EFPGA_SOURCES} -DCREATE_FST
	python3 ${TB_DIR}/makehex.py ${DESIGN_BITSTREAM} ${MAX_BITBYTES} ${DESIGN_BITSTREAM_HEX}
	(cd $(TB_DIR) && vvp ${SIM_EFPGA_OUTPUT_FILE})

sim_top: $(TB_BUILD_DIR)
	iverilog -s ${TB_TOP_MODULE} -o ./tb/${SIM_TOP_OUTPUT_FILE}  ${TB_TOP_SOURCES} -DCREATE_FST -DSIM
	python3 ${TB_DIR}/makehex.py ${TOP_TEST_DESIGN_BITSTREAM} ${MAX_BITBYTES} ${TOP_TEST_DESIGN_BITSTREAM_HEX}
	(cd $(TB_DIR) && vvp ${SIM_TOP_OUTPUT_FILE})

clean_local:
	rm -rf $(TB_BUILD_DIR)

.PHONY: clean clean_local lint sim_eFPGA sim_top
clean: clean_local clean_included

clean_included:
	$(MAKE) -f ../openXC7.mk clean
