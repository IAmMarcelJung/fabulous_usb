`timescale 1ps / 1ps
module dpram_fabric #(
    parameter VECTOR_LENGTH = 512,  // Total memory words
    parameter WORD_WIDTH    = 8,    // Bit width of each word
    parameter ADDR_WIDTH    = 9     // Address length
) (
    output reg  [WORD_WIDTH-1:0] rdata_o,     // Read data
    input  wire                  rclk_i,      // Read clock
    input  wire                  rclke_i,     // Read clock enable
    input  wire                  re_i,        // Read enable
    input  wire [ADDR_WIDTH-1:0] raddr_i,     // Read address
    input  wire [WORD_WIDTH-1:0] wdata_i,     // Write data
    input  wire                  wclk_i,      // Write clock
    input  wire                  wclke_i,     // Write clock enable
    input  wire                  we_i,        // Write enable
    input  wire [ADDR_WIDTH-1:0] waddr_i,     // Write address
    input  wire [           3:0] wbytemask_i  // Mask
);

    // Memory array
    reg [WORD_WIDTH-1:0] mem[0:VECTOR_LENGTH-1];

    // Write operation
    always @(posedge wclk_i) begin
        if (wclke_i && we_i) begin
            mem[waddr_i][7:0]   <= (wbytemask_i[0] ? wdata_i[7:0] : mem[waddr_i][7:0]);
            mem[waddr_i][15:8]  <= (wbytemask_i[1] ? wdata_i[15:8] : mem[waddr_i][15:8]);
            mem[waddr_i][23:16] <= (wbytemask_i[2] ? wdata_i[23:16] : mem[waddr_i][23:16]);
            mem[waddr_i][31:24] <= (wbytemask_i[3] ? wdata_i[31:24] : mem[waddr_i][31:24]);
        end
    end

    // Read operation
    always @(posedge rclk_i) begin
        if (rclke_i && re_i) begin
            rdata_o <= mem[raddr_i];
        end
    end

endmodule
