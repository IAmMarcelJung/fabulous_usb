








create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list pll_48_24_MHz_int/inst/clk_48_MHz]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[0]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[1]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[2]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[3]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[4]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[5]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[6]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[7]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[8]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[9]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[10]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[11]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[12]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[13]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[14]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[15]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[16]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[17]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[18]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[19]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[20]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[21]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[22]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[23]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[24]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[25]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[26]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[27]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[28]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[29]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[30]} {top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteData[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list top_inst/eFPGA_top_inst/eFPGA_Config_inst/ConfigWriteStrobe]]
set_property C_CLK_INPUT_FREQ_HZ 48000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_usb]
