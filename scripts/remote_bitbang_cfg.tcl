# Use the remote_bitbang driver to communicate over TCP
adapter driver remote_bitbang
transport select jtag

remote_bitbang host 127.0.0.1
remote_bitbang port 4567

reset_config none

# Define the JTAG TAP and expected device ID
set _CHIPNAME riscv
set _EXPECTED_ID 0x11001CDF

jtag newtap $_CHIPNAME cpu -irlen 5 -expected-id $_EXPECTED_ID
set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME

# OpenOCD settings
riscv set_mem_access sysbus
gdb_report_data_abort enable
gdb_report_register_access_error enable
gdb_breakpoint_override hard

# Start debugging
init
halt
