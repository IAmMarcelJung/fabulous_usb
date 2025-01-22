`timescale 1ps / 1ps
module bypass_register (
    input data_in,
    shiftDR,
    clkDR,
    output reg data_out
);

  wire s1 = data_in & shiftDR;

  always @(posedge clkDR) begin
    data_out <= s1;
  end
endmodule
