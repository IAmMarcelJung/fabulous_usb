`timescale 1ps / 1ps
module id_cell (
    input clkDR,
    shiftDR,
    id_code_bit,
    prevCell,
    output reg nextCell
);

  wire s1;

  assign s1 = (shiftDR == 1'b0) ? id_code_bit : prevCell;

  always @(posedge clkDR) begin
    nextCell <= s1;
  end
endmodule
