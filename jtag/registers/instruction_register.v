`timescale 1ps / 1ps
`include "constants.vh"

module instruction_register #(
    parameter REG_LEN   = 3,
    parameter INSTR_NUM = 5
) (
    input                      clkIR,
    upIR,
    shIR,
    tdi,
    reset,
    input      [  REG_LEN-1:0] piData,
    input      [          3:0] state,
    output                     tdo_mux,
    output reg [INSTR_NUM-1:0] instrB
);

    wire [    REG_LEN:0] data;
    reg  [INSTR_NUM-1:0] instr_data;

    initial begin
        instr_data = 0;
    end

    assign data[0] = tdi;
    assign tdo_mux = data[REG_LEN];

    genvar i;
    generate
        for (i = 0; i < REG_LEN; i = i + 1) begin : g_instruction_register_cell
            instruction_register_cell ireg_i (
                .clkIR  (clkIR),
                .shIR   (shIR),
                .piData (piData[i]),
                .preData(data[i]),
                .dataNex(data[i+1])
            );
        end
    endgenerate

    always @(*) begin
        if (state == `EX1IR_C) begin
            case (data[REG_LEN:1])
                3'b001:  instr_data = `IDCODE_INSTR;
                3'b010:  instr_data = `SAMPLE_PRELOAD_INSTR;
                3'b100:  instr_data = `EXTEST_INSTR;
                3'b101:  instr_data = `PROGRAM_INSTR;
                3'b110:  instr_data = `INTEST_INSTR;
                default: instr_data = `BYPASS_INSTR;
            endcase
        end
        instr_data = `BYPASS_INSTR;
    end

    always @(posedge clkIR or posedge reset) begin
        if (reset == 1'b0) begin
            instrB    <= 0;
            instrB[0] <= 1'b1;
        end else if (~upIR)  // clocked instruction bits output
            instrB <= instr_data;
    end
endmodule
