# Create main clock
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
set_false_path -to [get_ports {an user_io heartbeat dp_pu_o dn_io dp_io led_o
jtag_led ibex_uart_tx ibex_led}]
set_false_path -from [get_ports {reset user_io dn_io dp_io ibex_uart_rx ibex_sw
ibex_btn}]

set_disable_timing [get_pins -hierarchical *Q_reg*]
set_disable_timing [get_pins -hierarchical *inferred_i_1__*]
set_disable_timing [get_pins -filter {REF_PIN_NAME =~ "*BEG*"} -of_objects [get_cells -hierarchical -quiet -filter {NAME =~ "*switch_matrix*"}]]

# Ignore timing between usb and system clock
# Vivado recommended this setting for getting the clocks in the methodology report

set_false_path -from [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT1]]
