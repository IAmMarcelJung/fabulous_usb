set_disable_timing [get_pins -hierarchical *Q_reg*]
set_disable_timing [get_pins -hierarchical *inferred_i_1__*]
set_disable_timing [get_pins -filter {REF_PIN_NAME =~ "*BEG*"} -of_objects [get_cells -hierarchical -quiet -filter {NAME =~ "*switch_matrix*"}]]

# Ignore timing between usb and system clock
# Vivado recommended this setting for getting the clocks in the methodology report
# NOTE: 24 MHz is too fast for user design running on the emulated FABulous
# fabric
set_false_path -from [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT1]]

# This is an additional clock that can be used
set_false_path -from [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pll_48_24_MHz_int/inst/mmcm_adv_inst/CLKOUT2]]
