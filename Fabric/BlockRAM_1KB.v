`timescale 1ps / 1ps
module BlockRAM_1KB (
    clk,
    rd_addr,
    rd_data,
    wr_addr,
    wr_data,
    C0,
    C1,
    C2,
    C3,
    C4,
    C5
);

    parameter READ_ADDRESS_MSB_FROM_DATALSB =
        24;  //default 24 means bits wr_data[25:24] will become bits [9:8] of read address
    parameter WRITE_ADDRESS_MSB_FROM_DATALSB =
        16;  //default 16 means bits wr_data[17:16] will become bits [9:8] of write address
    parameter WRITE_ENABLE_FROM_DATA =
        20;  //default 20 means bit wr_data[20] will become the dynamic writeEnable input
    input clk;
    input [7:0] rd_addr;
    output [31:0] rd_data;

    input [7:0] wr_addr;
    input [31:0] wr_data;

    input C0;  //naming of these doesnt really matter
    input C1;  // C0,C1 select write port width
    input C2;  // C2,C3 select read port width
    input C3;
    input C4;  //C4 selects the alwaysWriteEnable
    input C5;  //C5 selects register bypass
    // NOTE, the read enable is currently constantly ON
    // NOTE, the R/W port on the standard cell is used only in write mode
    // NOTE, enable ports on the primitive RAM are active lows
    wire [1:0] rd_port_configuration;
    wire [1:0] wr_port_configuration;
    wire       optional_register_enabled_configuration;
    wire       alwaysWriteEnable;
    assign wr_port_configuration                   = {C0, C1};
    assign rd_port_configuration                   = {C2, C3};
    assign alwaysWriteEnable                       = C4;
    assign optional_register_enabled_configuration = C5;

    reg memWriteEnable;
    always @(*) begin  // write enable
        if (alwaysWriteEnable) begin
            memWriteEnable = 0;  // This RAM primitive is active low.
        end else begin
            memWriteEnable = (
                !(wr_data[WRITE_ENABLE_FROM_DATA]));  // inverting the bit to make it active-high
        end
    end
    reg  [ 3:0] mem_wr_mask;
    reg  [31:0] muxedDataIn;

    wire [ 1:0] wr_addr_topbits;
    assign
        wr_addr_topbits = wr_data[WRITE_ADDRESS_MSB_FROM_DATALSB+1:WRITE_ADDRESS_MSB_FROM_DATALSB];
    always @(*) begin  //write port config -> mask + write data multiplex
        muxedDataIn = 32'dx;
        if (wr_port_configuration == 1) begin
            if (wr_addr_topbits == 0) begin
                mem_wr_mask       = 4'b0011;
                muxedDataIn[15:0] = wr_data[15:0];
            end else begin
                mem_wr_mask        = 4'b1100;
                muxedDataIn[31:16] = wr_data[15:0];
            end
        end else if (wr_port_configuration == 2) begin
            if (wr_addr_topbits == 0) begin
                mem_wr_mask      = 4'b0001;
                muxedDataIn[7:0] = wr_data[7:0];
            end else if (wr_addr_topbits == 1) begin
                mem_wr_mask       = 4'b0010;
                muxedDataIn[15:8] = wr_data[7:0];
            end else if (wr_addr_topbits == 2) begin
                mem_wr_mask        = 4'b0100;
                muxedDataIn[23:16] = wr_data[7:0];
            end else begin
                mem_wr_mask        = 4'b1000;
                muxedDataIn[31:24] = wr_data[7:0];
            end
            // wr_port_configuration == 0
        end else begin
            mem_wr_mask = 4'b1111;
            muxedDataIn = wr_data;
        end
    end
    wire [31:0] mem_dout;
    localparam DPRAM_VECTOR_LENGTH = 'd256;

    dpram_fabric #(
        .VECTOR_LENGTH(DPRAM_VECTOR_LENGTH),
        .WORD_WIDTH   ('d32),
        .ADDR_WIDTH   ($clog2(DPRAM_VECTOR_LENGTH))
    ) memory_cell (
        .wclk_i     (clk),
        .we_i       (!memWriteEnable),
        .wclke_i    (!memWriteEnable),
        .wbytemask_i(mem_wr_mask),
        .waddr_i    (wr_addr),
        .wdata_i    (muxedDataIn),
        .rclk_i     (clk),
        .rclke_i    (1'b1),
        .re_i       (1'b1),
        .raddr_i    (rd_addr),
        .rdata_o    (mem_dout)
    );

    reg [1:0] rd_dout_sel;
    always @(posedge clk) begin
        rd_dout_sel <= wr_data[READ_ADDRESS_MSB_FROM_DATALSB+1:READ_ADDRESS_MSB_FROM_DATALSB];
    end
    reg [31:0] rd_dout_muxed;
    always @(*) begin
        // a default value. Could be 32'dx if tools support it for logic saving!
        rd_dout_muxed = 32'dx;
        if (rd_port_configuration == 0) begin
            rd_dout_muxed = mem_dout;
        end else if (rd_port_configuration == 1) begin
            if (rd_dout_sel[0] == 0) begin
                rd_dout_muxed[15:0] = mem_dout[15:0];
            end else begin
                rd_dout_muxed[15:0] = mem_dout[31:16];
            end
        end else if (rd_port_configuration == 2) begin
            if (rd_dout_sel == 0) begin
                rd_dout_muxed[7:0] = mem_dout[7:0];
            end else if (rd_dout_sel == 1) begin
                rd_dout_muxed[7:0] = mem_dout[15:8];
            end else if (rd_dout_sel == 2) begin
                rd_dout_muxed[7:0] = mem_dout[23:16];
            end else begin
                rd_dout_muxed[7:0] = mem_dout[31:24];
            end
        end
    end
    reg [31:0] rd_dout_additional_register;
    always @(posedge clk) begin
        rd_dout_additional_register <= rd_dout_muxed;
    end
    reg [31:0] final_dout;
    assign rd_data = final_dout;
    always @(*) begin
        if (optional_register_enabled_configuration) begin
            final_dout = rd_dout_additional_register;
        end else begin
            final_dout = rd_dout_muxed;
        end
    end
endmodule
