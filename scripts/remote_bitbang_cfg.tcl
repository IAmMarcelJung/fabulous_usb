# Use the remote_bitbang driver to communicate over TCP
adapter driver remote_bitbang
remote_bitbang host 127.0.0.1
remote_bitbang port 4567

# Define the JTAG TAP and expected device ID
set _CHIPNAME riscv
set _EXPECTED_ID 0x110001CDF  ;# Ibex on Arty A7-35T (or use correct ID)

jtag newtap $_CHIPNAME cpu -irlen 6 -expected-id $_EXPECTED_ID -ignore-version
set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME

# Define debug module interface
riscv set_ir idcode 0x09
riscv set_ir dtmcs 0x22
riscv set_ir dmi 0x23

# OpenOCD settings
riscv set_mem_access sysbus
gdb_report_data_abort enable
gdb_report_register_access_error enable
gdb_breakpoint_override hard

# Start debugging
init
halt
