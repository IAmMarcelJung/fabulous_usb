`ifndef CONSTANTS_VH
`define CONSTANTS_VH

// LSB must be 1
`define ID_DATA 32'h0000_0001

`define INSTRUCTION_LENGTH 5
`define IREG_LENGTH 3

`define BYPASS_INSTR 0
`define IDCODE_INSTR 5'b00001
`define SAMPLE_PRELOAD_INSTR 5'b00010
`define EXTEST_INSTR 5'b00100
`define INTEST_INSTR 5'b01000
`define PROGRAM_INSTR 5'b10000

`define TLRESET_C 4'hF
`define IDLE_C 4'hC
`define SELDR_C 4'h7
`define CAPDR_C 4'h6
`define SHDR_C 4'h2
`define EX1DR_C 4'h1
`define PDR_C 4'h3
`define EX2DR_C 4'h0
`define UPDR_C 4'h5
`define SELIR_C 4'h4
`define CAPIR_C 4'hE
`define SHIR_C 4'hA
`define EX1IR_C 4'h9
`define PIR_C 4'hB
`define EX2IR_C 4'h8
`define UPIR_C 4'hD

`endif
