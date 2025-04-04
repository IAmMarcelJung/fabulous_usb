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
    localparam [31:0] DESYNC_FRAME = 1 << DESYNC_FLAG_POS;
    localparam [31:0] DONE_FRAME = 32'hFAB0_FABF;
    localparam STATE_IDLE = 0;
    localparam STATE_BYTE_0 = 1;
    localparam STATE_BYTE_1 = 2;
    localparam STATE_BYTE_2 = 3;
    localparam STATE_BYTE_3 = 4;
    localparam STATE_BYTE_0_WAIT = 5;
    localparam STATE_BYTE_1_WAIT = 6;
    localparam STATE_BYTE_2_WAIT = 7;
    localparam STATE_BYTE_3_WAIT = 8;

    reg [31:0] word_buffer, write_data;
    reg [1:0] byte_index;
    reg [1:0] byte_index_old;
    reg       get_data_flag;
    reg       word_write_strobe;

    reg in_valid_r, in_valid_next;
    reg [7:0] in_data_r, in_data_next;
    reg [3:0] ack_state, ack_state_next;

    assign in_valid_o = in_valid_r;
    assign in_data_o  = in_data_r;

    // NOTE: The wait states are needed because otherwise the data was not sent
    // correctly

    always @(*) begin
        ack_state_next = ack_state;
        case (ack_state)
            STATE_IDLE: begin
                if (write_data == DESYNC_FRAME)
                    ack_state_next = STATE_BYTE_3;  // Start sending sequence
            end
            STATE_BYTE_3:      if (in_ready_i) ack_state_next = STATE_BYTE_3_WAIT;
            STATE_BYTE_2:      if (in_ready_i) ack_state_next = STATE_BYTE_2_WAIT;
            STATE_BYTE_1:      if (in_ready_i) ack_state_next = STATE_BYTE_1_WAIT;
            STATE_BYTE_0:      if (in_ready_i) ack_state_next = STATE_BYTE_0_WAIT;
            // STATE_BYTE_3:      if (in_ready_i) ack_state_next = STATE_BYTE_2;
            // STATE_BYTE_2:      if (in_ready_i) ack_state_next = STATE_BYTE_1;
            // STATE_BYTE_1:      if (in_ready_i) ack_state_next = STATE_BYTE_0;
            // STATE_BYTE_0:      if (in_ready_i) ack_state_next = STATE_IDLE;
            STATE_BYTE_3_WAIT: ack_state_next = STATE_BYTE_2;
            STATE_BYTE_2_WAIT: ack_state_next = STATE_BYTE_1;
            STATE_BYTE_1_WAIT: ack_state_next = STATE_BYTE_0;
            STATE_BYTE_0_WAIT: ack_state_next = STATE_IDLE;
            default:           ack_state_next = STATE_IDLE;
        endcase
    end

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            ack_state <= STATE_IDLE;
        end else begin
            ack_state <= ack_state_next;
        end
    end

    always @(*) begin
        case (ack_state)
            STATE_BYTE_3: begin
                in_valid_next = 1'b1;
                in_data_next  = DONE_FRAME[24+:8];
            end
            STATE_BYTE_2: begin
                in_valid_next = 1'b1;
                in_data_next  = DONE_FRAME[16+:8];
            end
            STATE_BYTE_1: begin
                in_valid_next = 1'b1;
                in_data_next  = DONE_FRAME[8+:8];
            end
            STATE_BYTE_0: begin
                in_valid_next = 1'b1;
                in_data_next  = DONE_FRAME[0+:8];
            end
            // All wait states
            default: begin
                in_valid_next = 1'b0;
                in_data_next  = in_data_r;
            end
        endcase
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
            byte_index     <= 2'b0;
            byte_index_old <= 2'b0;
            get_data_flag  <= 1'b0;
        end else begin
            byte_index_old <= byte_index;
            if (out_valid_i) begin
                if (word_buffer[31:8] == 24'h00AAFF &&
                    (word_buffer[6:0] == {7'h1} || word_buffer[6:0] == {7'h2})) begin
                    byte_index    <= 2'b01;
                    get_data_flag <= 1'b1;
                end
                byte_index <= byte_index + 1'b1;
                // Do not get more data
                if (write_data == DESYNC_FRAME) get_data_flag <= 1'b0;
            end
        end
    end

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            word_buffer <= 32'b0;
        end else begin
            if (out_valid_i) begin
                word_buffer <= {word_buffer[23:0], out_data_i};
            end
        end
    end

    always @(posedge clk_i, negedge reset_n_i) begin
        if (!reset_n_i) begin
            write_data        <= 32'b0;
            word_write_strobe <= 1'b0;
        end else begin
            word_write_strobe <= 1'b0;
            write_data        <= 32'b0;
            if (get_data_flag && byte_index == 2'b00) begin
                write_data <= word_buffer;
                if (byte_index == 2'b00 && byte_index_old == 2'b11) word_write_strobe <= 1'b1;
            end
        end
    end

endmodule
