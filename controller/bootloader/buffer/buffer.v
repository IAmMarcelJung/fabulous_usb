`timescale 1ps / 1ps
// Abstraction for the underlying fifo interface and dpram
module buffer #(
    parameter SIZE       = 'd512,
    parameter WORD_WIDTH = 'd8,
    parameter ADDR_WIDTH = 'd9

) (
    input                   clk_i,
    input                   reset_n_i,
    input                   en_i,
    input                   in_valid_i,
    output                  in_ready_o,
    output                  out_valid_o,
    input                   out_ready_i,
    output                  empty_o,
    input  [WORD_WIDTH-1:0] data_in_i,
    output [WORD_WIDTH-1:0] data_out_o,
    output                  full_o

);
    wire [ADDR_WIDTH-1:0] fifo_in_addr;
    wire [ADDR_WIDTH-1:0] fifo_out_addr;
    wire                  fifo_in_clke;
    wire                  fifo_out_clke;

    ram_fifo_if #(
        .RAM_SIZE(SIZE)
    ) u_ram_fifo_if (
        .clk_i      (clk_i),
        .rstn_i     (reset_n_i),
        .en_i       (en_i),
        .in_valid_i (in_valid_i),
        .in_ready_o (in_ready_o),
        .out_valid_o(out_valid_o),
        .out_ready_i(out_ready_i),
        .empty_o    (empty_o),
        .full_o     (full_o),
        .in_clke_o  (fifo_in_clke),
        .out_clke_o (fifo_out_clke),
        .in_addr_o  (fifo_in_addr),
        .out_addr_o (fifo_out_addr)
    );

    dpram #(
        .VECTOR_LENGTH(SIZE),
        .WORD_WIDTH   (WORD_WIDTH),
        .ADDR_WIDTH   ($clog2(SIZE))
    ) u_dpram (
        .rdata_o(data_out_o),
        .rclk_i (clk_i),
        .rclke_i(fifo_out_clke),
        .re_i   (1'b1),
        .raddr_i(fifo_out_addr),
        .wdata_i(data_in_i),
        .wclk_i (clk_i),
        .wclke_i(fifo_in_clke),
        .we_i   (1'b1),
        .waddr_i(fifo_in_addr),
        .mask_i (8'd0)
    );
endmodule
