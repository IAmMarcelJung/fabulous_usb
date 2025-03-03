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


    localparam DESYNC_FLAG_POS = 20;
    localparam [31:0] FINISH_FLAG = 32'hFAB0_FABF;
    reg [2:0] ack_state, ack_state_next;
    localparam STATE_IDLE = 0,
        STATE_BYTE_0 = 1, STATE_BYTE_1 = 2, STATE_BYTE_2 = 3, STATE_BYTE_3 = 4;

    reg [31:0] word_buffer, write_data;
    reg [1:0] byte_index;
    reg [1:0] byte_index_old;
    reg       get_data_flag;
    reg       word_write_strobe;

    // TODO: Check if this works
    // currently no data is sent back to the host
    // assign in_valid_o = 1'b0;
    // assign in_data_o  = 8'hxx;

    reg in_valid_r, in_valid_next;
    reg [7:0] in_data_r, in_data_next;

    assign in_valid_o = in_valid_r;
    assign in_data_o  = in_data_r;

    // always @(posedge clk_i, negedge reset_n_i) begin
    //     if (!reset_n_i) begin
    //         in_valid_r <= 1'b0;
    //         in_data_r  <= 8'b0;
    //     end else begin
    //         if (write_data[DESYNC_FLAG_POS]) begin
    //             in_valid_r <= 1'b1;
    //             in_data_r  <= FINISH_FLAG;
    //         end else begin
    //             // Only send data if the transmission is done
    //         end
    //     end
    // end
    // TODO: add in_ready_i condition

    always @(*) begin
        if (!reset_n_i) begin
            ack_state_next = STATE_IDLE;
        end else begin
            ack_state_next = ack_state;
            case (ack_state)
                STATE_BYTE_3: if (in_ready_i) ack_state_next = STATE_BYTE_2;
                STATE_BYTE_2: if (in_ready_i) ack_state_next = STATE_BYTE_1;
                STATE_BYTE_1: if (in_ready_i) ack_state_next = STATE_BYTE_0;
                STATE_BYTE_0: if (in_ready_i) ack_state_next = STATE_IDLE;
                default:
                if (write_data[DESYNC_FLAG_POS]) begin
                    if (in_ready_i) ack_state_next = STATE_BYTE_3;
                end
            endcase
        end
    end

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            ack_state <= STATE_IDLE;
        end else begin
            ack_state <= ack_state_next;
        end
    end

    always @(*) begin
        if (!reset_n_i) begin
            in_valid_next = 1'b0;
            in_data_next  = 8'b0;
        end else begin
            case (ack_state)
                STATE_BYTE_3: begin
                    in_valid_next = 1'b1;
                    in_data_next  = FINISH_FLAG[24+:8];
                end
                STATE_BYTE_2: begin
                    in_valid_next = 1'b1;
                    in_data_next  = FINISH_FLAG[16+:8];
                end
                STATE_BYTE_1: begin
                    in_valid_next = 1'b1;
                    in_data_next  = FINISH_FLAG[8+:8];
                end
                STATE_BYTE_0: begin
                    in_valid_next = 1'b1;
                    in_data_next  = FINISH_FLAG[0+:8];
                end
                default: begin
                    in_valid_next = 1'b0;
                    in_data_next  = 8'b0;
                end
            endcase
        end
    end

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            in_valid_r <= 1'b0;
            in_data_r  <= 8'b0;
        end else begin
            in_valid_r <= in_valid_next;
            in_data_r  <= in_data_next;
        end
    end

    assign word_write_strobe_o = word_write_strobe;
    assign write_data_o        = write_data;
    // Fabric is assumed to be clocked fast enough that it is always ready
    assign out_ready_o         = 1'b1;

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
