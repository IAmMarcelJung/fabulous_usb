`timescale 1ps / 1ps
module instruction_register_cell (
    input      clkIR,
    shIR,
    piData,
    preData,
    output reg dataNex
);

    reg s1;

    always @(posedge clkIR) begin
        if (clkIR) s1 <= (shIR == 1'b0) ? piData : preData;
        else dataNex <= s1;
    end
endmodule
