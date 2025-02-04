# Synthesize module: LUT4AB
read_verilog ../Fabric/auxiliary.v
read_verilog ../Fabric/models_pack.v
read_verilog LUT4AB/*.v
hierarchy -top LUT4AB
synth -top LUT4AB
write_verilog -noattr gl/LUT4AB_synth.v
write_json json/LUT4AB_synth.json
design -reset

# Synthesize module: N_term_RAM_IO
read_verilog ../Fabric/auxiliary.v
read_verilog ../Fabric/models_pack.v
read_verilog N_term_RAM_IO/*.v
hierarchy -top N_term_RAM_IO
synth -top N_term_RAM_IO
write_verilog -noattr gl/N_term_RAM_IO_synth.v
write_json json/N_term_RAM_IO_synth.json
design -reset

# Synthesize module: N_term_single
read_verilog ../Fabric/auxiliary.v
read_verilog ../Fabric/models_pack.v
read_verilog N_term_single/*.v
hierarchy -top N_term_single
synth -top N_term_single
write_verilog -noattr gl/N_term_single_synth.v
write_json json/N_term_single_synth.json
design -reset

# Synthesize module: RAM_IO
read_verilog ../Fabric/auxiliary.v
read_verilog ../Fabric/models_pack.v
read_verilog RAM_IO/*.v
hierarchy -top RAM_IO
synth -top RAM_IO
write_verilog -noattr gl/RAM_IO_synth.v
write_json json/RAM_IO_synth.json
design -reset

# Synthesize module: S_term_RAM_IO
read_verilog ../Fabric/models_pack.v
read_verilog ../Fabric/auxiliary.v
read_verilog S_term_RAM_IO/*.v
hierarchy -top S_term_RAM_IO
synth -top S_term_RAM_IO
write_verilog -noattr gl/S_term_RAM_IO_synth.v
write_json json/S_term_RAM_IO_synth.json
design -reset

# Synthesize module: S_term_single
read_verilog ../Fabric/models_pack.v
read_verilog ../Fabric/auxiliary.v
read_verilog S_term_single/*.v
hierarchy -top S_term_single
synth -top S_term_single
write_verilog -noattr gl/S_term_single_synth.v
write_json json/S_term_single_synth.json
design -reset

# Synthesize module: W_IO
read_verilog ../Fabric/models_pack.v
read_verilog ../Fabric/auxiliary.v
read_verilog ../Tile/RAM_IO/Config_access.v
read_verilog W_IO/*.v
hierarchy -top W_IO
synth -top W_IO
write_verilog -noattr gl/W_IO_synth.v
write_json json/W_IO_synth.json
design -reset

log "Synthesis completed for all modules!"
