`timescale 1ps / 1ps
module boundary_scan_register #(
    parameter LEN = 4
) (
    // verilator lint_off UNUSEDSIGNAL
    input            tck,
    // verilator lint_on UNUSEDSIGNAL
    input            resetn,
    input            enableIn,
    input            enableOut,
    input            mode,
    input            clkDR,
    input            shiftDR,
    input            updateDR,
    input            tdi,
    input  [LEN-1:0] data_pin,
    output           tdo,
    output [LEN-1:0] data_pout
);

    wire [LEN:0] data;

    assign data[0] = tdi;
    assign tdo     = data[LEN];

    genvar i;
    generate
        for (i = 0; i < LEN; i = i + 1) begin : gen_bsr_cells
            bsr_cell bsr_cell_i (
                .resetn   (resetn),
                .enableIn (enableIn),
                .enableOut(enableOut),
                .mode     (mode),
                .clkDR    (clkDR),
                .shiftDR  (shiftDR),
                .updateDR (updateDR),
                .data_pin (data_pin[i]),
                .prevCell (data[i]),
                .nextCell (data[i+1]),
                .data_pout(data_pout[i])
            );
        end
    endgenerate
endmodule
