
# Toolchain
RISCV_PREFIX = riscv32-unknown-elf

# Tools
CC      = $(RISCV_PREFIX)-gcc
OBJDUMP = $(RISCV_PREFIX)-objdump
OBJCOPY = $(RISCV_PREFIX)-objcopy
SIZE    = $(RISCV_PREFIX)-size

# Directories
COMMON_DIR    = ../../ibex-demo-system/sw/c/common
INCLUDE_DIR   = $(COMMON_DIR)
LINKER_SCRIPT = ../../ibex-demo-system/sw/common/link.ld

# Flags
# CFLAGS   = -g -march=rv32imc -mabi=ilp32 -mcmodel=medany -Wall -Og -fvisibility=hidden -ffreestanding -I$(INCLUDE_DIR)
CFLAGS = -g -march=rv32imc -mabi=ilp32 -mcmodel=medany -Wall -Og -fvisibility=hidden -ffreestanding \
		 -D__riscv__ -DIBEX -I$(INCLUDE_DIR)
LDFLAGS  = -nostartfiles -T$(LINKER_SCRIPT)

# Files
CRT0     = $(COMMON_DIR)/crt0.S
COMMON_SRCS = $(wildcard $(COMMON_DIR)/*.c)
SRC      = main.c $(COMMON_SRCS) $(CRT0)
OUT      = main.elf

# Build rules
all: $(OUT)

$(OUT): $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	$(SIZE) $@

clean:
	rm -f $(OUT)

.PHONY: all clean
