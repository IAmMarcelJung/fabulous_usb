FAMILY  = artix7
PART    = xc7a35tcpg236-1
BOARD   = basys3
PROJECT = top_basys3
CHIPDB  = ${ARTIX7_CHIPDB}



SYNTH_OPTS += -json -noscopeinfo
PNR_ARGS += --ignore-loops -f

MAX_BITBYTES=16384

# Define directories
TB_DIR := ./tb
TB_BUILD_DIR := $(TB_DIR)/build

TB_TOP_SOURCES := $(shell find . -type f \( -iname "*.v" -o -iname "*.sv" \) \
				  -not -path "./jtag/*" \
				  -not -path "./JTAG-interface/*" \
				  -not -path "*./Tile/gl/*" \
				  -not -path "*/in_fifo/*" )
TB_INCLUDE_DIRS += ./common_constants/ ./controller/usb_common/

# Used for the open source flow
ADDITIONAL_SOURCES := $(shell find . -type f \( -iname "*.v" -o -iname "*.sv" \) \
					  -not -name "${PROJECT}.v" \
					  -not -name "*synth*" \
					  -not -name "*_tb.v*" \
					  -not -path "./tb/*" \
					  -not -path "./JTAG-interface/*" \
					  -not -path "*/in_fifo/*" \
					  -not -path "./jtag/*")

# Define a variable to hold the include flags
TB_INCLUDE_FLAGS = $(foreach dir,$(TB_INCLUDE_DIRS),-I $(dir))

DESIGN=counter
DESIGN_BITSTREAM=${TB_DIR}/${DESIGN}.bin
DESIGN_BITSTREAM_HEX=${TB_BUILD_DIR}/${DESIGN}.hex

include ../openXC7.mk

$(TB_BUILD_DIR):
	mkdir -p $(TB_BUILD_DIR)

lint:
	verilator --lint-only -Wall -Wpedantic --top-module top *.v -DDEBUG \
	-IFabric/ \
	-ITile/ \
	-ITile/include/ \
	-ITile/LUT4AB/ \
	-ITile/N_term_RAM_IO/ \
	-ITile/N_term_single/ \
	-ITile/RAM_IO/ \
	-ITile/S_term_RAM_IO/ \
	-ITile/S_term_single/ \
	-ITile/W_IO/ \
	-Iclocking/ \
	-Icontroller/ \
	-Icontroller/usb_dfu \
	-Icontroller/usb_cdc \
	-Icontroller/usb_common \
	-Icontroller/usb_common/out_fifo \
	-Icontroller/bootloader \
	-Icontroller/bootloader/flash/ \
	-Icontroller/bootloader/buffer/ \
	-Itb/ \
	-IJTAG-interface/ \
	-f verilator_filelist.f > lint.log 2>&1

$(TB_BUILD_DIR)/%.vvp: $(TB_BUILD_DIR)
	iverilog -D TOP_MODULE=$* -D DUMP_FILE="\"./build/$*.fst\"" -s $* -o tb/build/$*.vvp ${TB_TOP_SOURCES} ${TB_INCLUDE_FLAGS}
	python3 ${TB_DIR}/makehex.py ${DESIGN_BITSTREAM} ${MAX_BITBYTES} ${DESIGN_BITSTREAM_HEX}
	(cd $(TB_DIR) && vvp build/$*.vvp -fst)

in_fifo_tb \
phy_rx_tb \
eFPGA_top_tb \
top_tb \
config_usb_tb \
config_usb_eFPGA_top_tb\
config_usb_cdc_tb:\
%: $(TB_BUILD_DIR)/%.vvp

clean_local:
	rm -rf $(TB_BUILD_DIR)

.PHONY: clean clean_local lint
clean: clean_local clean_included

clean_included:
	$(MAKE) -f ../openXC7.mk clean
