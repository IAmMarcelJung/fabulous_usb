`timescale 1ps / 1ps
module config_usb_cdc (
    input        clk_i,
    input        reset_n_i,
    output [7:0] in_data_o,
    output       in_valid_o,
    // While in_valid_o is high, in_data_o shall be valid.
    input        in_ready_i,
    // When both in_ready_i and in_valid_o are high, in_data_o shall
    //   be consumed.

    input  [ 7:0] out_data_i,
    input         out_valid_i,
    // While out_valid_i is high, the out_data_i shall be valid and both
    //   out_valid_i and out_data_i shall not change until consumed.
    output        out_ready_o,
    // When both out_valid_i and out_ready_o are high, the out_data_i shall
    //   be consumed.
    output        word_write_strobe_o,
    output [31:0] write_data_o
);


    reg [31:0] word_buffer, write_data;
    reg [1:0] byte_index;
    reg [1:0] byte_index_old;
    reg       get_data_flag;
    reg       word_write_strobe;

    // TODO: Check if this works
    // currently no data is sent back to the host
    assign in_valid_o = 1'b0;
    assign in_data_o = 8'hxx;

    assign word_write_strobe_o = word_write_strobe;
    assign write_data_o = write_data;
    assign
        out_ready_o = 1'b1;  // Fabric is assumed to be clocked high enough that it is always ready

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            word_buffer    <= 32'b0;
            byte_index     <= 2'b0;
            byte_index_old <= 2'b0;
            get_data_flag  <= 1'b0;
        end else begin
            byte_index_old <= byte_index;
            if (out_valid_i) begin
                word_buffer <= {word_buffer[23:0], out_data_i};
                if (word_buffer[31:8] == 24'h00AAFF &&
                    (word_buffer[6:0] == {7'h1} || word_buffer[6:0] == {7'h2})) begin
                    byte_index    <= 2'b01;
                    get_data_flag <= 1'b1;
                end
                byte_index <= byte_index + 1'b1;
            end
        end
    end

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            write_data        <= 32'b0;
            word_write_strobe <= 1'b0;
        end else begin
            word_write_strobe <= 1'b0;
            if (get_data_flag && byte_index == 2'b00) begin
                write_data <= word_buffer;
                if (byte_index == 2'b00 && byte_index_old == 2'b11) word_write_strobe <= 1'b1;
            end
        end
    end

endmodule
