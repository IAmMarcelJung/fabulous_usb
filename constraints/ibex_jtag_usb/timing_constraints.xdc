## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]

set_false_path -to [get_ports {led dp_pu_o an dn_io dp_io tdi_o tms_o tck_o trst_o srst_o tdo_o captured_tdo_o}]
set_false_path -from [get_ports {IO_RST dn_io dp_io}]

set_false_path -from [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pll_48_12_MHz_inst/inst/mmcm_adv_inst/CLKOUT1]]
