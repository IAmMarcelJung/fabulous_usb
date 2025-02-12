set_disable_timing [get_pins -hierarchical *Q_reg*]
set_disable_timing [get_pins -hierarchical *inferred_i_1__*]
set_disable_timing [get_pins -filter {REF_PIN_NAME =~ "*BEG*"} -of_objects [get_cells -hierarchical -quiet -filter {NAME =~ "*switch_matrix*"}]]

# Ignore timing between usb and system clock
set_false_path -from [get_clocks clk_12_5_MHz_pll_48_12_5_MHz] -to [get_clocks clk_48_MHz_pll_48_12_5_MHz]
set_false_path -from [get_clocks clk_48_MHz_pll_48_12_5_MHz] -to [get_clocks clk_12_5_MHz_pll_48_12_5_MHz]
