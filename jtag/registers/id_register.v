`timescale 1ps / 1ps
// MSB                                                LSB
//  31       28 27         12 11                    1  0
// | version | part number | manufacturer identity | 1 |
//   4 bits      16 bits           11 bits

module id_register (
    input  clkDR,
    shiftDR,
    output data_out
);

    localparam ID_DATA = 32'h0000_0001;  //LSB must be 1

    wire [32:0] data;

    assign data[32] = 1'b0;
    assign data_out = data[0];

    genvar i;

    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_id_cells
            id_cell id_cell_i (
                .clkDR      (clkDR),
                .shiftDR    (shiftDR),
                .id_code_bit(ID_DATA[i]),
                .prevCell   (data[i+1]),
                .nextCell   (data[i])
            );
        end
    endgenerate
endmodule
