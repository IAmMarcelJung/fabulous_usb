`timescale 1ps / 1ps
module config_usb #(
    parameter BUFFER_SIZE = 'd512
) (
    input        clk_i,
    input        reset_n_i,
    // ---- to/from USB_DFU ------------------------------------------
    input        dfu_mode_i,
    // While USB_DFU is in DFU Mode, dfu_mode_i shall be high.
    input  [2:0] dfu_alt_i,
    // dfu_alt_i shall report the current alternate interface setting.
    // verilator lint_off PINCONNECTEMPTY
    // NOTE: don't use these for now
    input        dfu_out_en_i,
    // While DFU is in dfuDNBUSY|dfuDNLOAD_SYNC|dfuDNLOAD_IDLE states, dfu_out_en_i shall be high.
    input        dfu_in_en_i,
    // While DFU is in dfuUPLOAD_IDLE state, dfu_in_en_i shall be high.
    output [7:0] dfu_in_data_o,
    output       dfu_in_valid_o,
    // While dfu_in_valid_o is high, dfu_in_data_o shall be valid.
    input        dfu_in_ready_i,
    // When both dfu_in_ready_i and dfu_in_valid_o are high, dfu_in_data_o shall
    //   be consumed.
    // verilator lint_on PINCONNECTEMPTY

    input  [ 7:0] dfu_out_data_i,
    input         dfu_out_valid_i,
    // While dfu_out_valid_i is high, the dfu_out_data_i shall be valid and both
    //   dfu_out_valid_i and dfu_out_data_i shall not change until consumed.
    output        dfu_out_ready_o,
    // When both dfu_out_valid_i and dfu_out_ready_o are high, the dfu_out_data_i shall
    //   be consumed.
    input         dfu_clear_status_i,
    // While DFU is in dfuIDLE state, dfu_clear_status_o shall be high.
    // verilator lint_off PINCONNECTEMPTY
    // NOTE: don't use for now
    output        dfu_busy_o,
    // When DFU_DNLOAD request target is busy and needs time to be ready for next data, dfu_busy_o
    //   shall be high.
    // verilator lint_on PINCONNECTEMPTY
    output [ 3:0] dfu_status_o,
    // dfu_status_o shall report the status resulting from the execution of the most recent DFU request.
    // verilator lint_off PINCONNECTEMPTY
    // NOTE: don't use for now
    input         heartbeat_i,
    // heartbeat_i transitions shall occur if the USB interface is alive.
    // verilator lint_on PINCONNECTEMPTY
    output        word_write_strobe_o,
    output [31:0] write_data_o
);

    localparam DFU_ALT_UPLOAD_BITSTREAM = 3'd2;
    wire       in_correct_dfu_mode;

    wire       enable_buffer;
    wire       dfu_out_valid;
    wire       dfu_out_ready;
    wire       buffer_empty;
    wire [7:0] buffer_data_out;
    wire       buffer_out_valid;
    wire       reset_n_local;

    // localparam IDLE = 0, GET_ID_00 = 1, GET_ID_AA = 2, GET_ID_FF = 3, GET_COMMAND = 4,
    //     EVAL_COMMAND = 5, GET_DATA = 6, ERR_WRONG_COMMAND = 7;
    // reg [2:0] present_state, present_state_next;
    //
    // localparam WAIT_FOR_WORD_0 = 0, WAIT_FOR_WORD_1 = 1, WAIT_FOR_WORD_2 = 2, WAIT_FOR_WORD_3 = 3;
    // reg [1:0] get_word_state, get_word_state_next;
    //
    localparam [3:0] STATUS_OK = 4'h0, STATUS_errTARGET = 4'h1, STATUS_END = 4'hF;


    // reg [23:0] id_reg, id_comb;
    // reg [7:0] command_reg, command_comb;
    // reg [7:0] data_reg, data_comb;
    // reg [31:0] write_data_reg, write_data_comb;
    // reg word_write_strobe_reg, word_write_strobe_comb;

    // reg [31:0] word_buffer, write_data;
    // reg  [1:0] byte_index;
    // reg  [1:0] byte_index_old;
    // reg        get_data_flag;
    // reg        word_write_strobe;

    wire buffer_out_ready;
    assign dfu_status_o = STATUS_OK;

    config_usb_cdc config_usb_cdc_inst (
        .clk_i              (clk_i),
        .reset_n_i          (reset_n_local),
        .in_data_o          (dfu_in_data_o),
        .in_valid_o         (dfu_in_valid_o),
        .in_ready_i         (dfu_in_ready_i),
        // .out_data_i         (buffer_data_out),
        // .out_valid_i        (buffer_out_valid),
        // .out_ready_o        (buffer_out_ready),
        .out_data_i         (dfu_out_data_i),
        .out_valid_i        (dfu_out_valid_i),
        .out_ready_o        (dfu_out_ready),
        .word_write_strobe_o(word_write_strobe_o),
        .write_data_o       (write_data_o)
    );

    //     // TODO: Check if this works
    //     // currently no data is sent back to the host
    //     assign dfu_in_valid_o = 1'b0;
    //     assign dfu_in_data_o = 8'hxx;
    //
    //     assign word_write_strobe_o = word_write_strobe;
    //     assign write_data_o = write_data;
    //     assign
    //         out_ready_o = 1'b1;  // Fabric is assumed to be clocked high enough that it is always ready
    //     always @(posedge clk_i, negedge reset_n_local) begin
    //         if (!reset_n_local) begin
    //             word_buffer    <= 32'b0;
    //             byte_index     <= 2'b0;
    //             byte_index_old <= 2'b0;
    //             get_data_flag  <= 1'b0;
    //             usb_led_o      <= 1'b0;
    //         end else begin
    //             byte_index_old <= byte_index;
    //             if (dfu_out_valid_i) begin
    //                 word_buffer <= {word_buffer[23:0], dfu_out_data_i};
    //                 if (word_buffer[31:8] == 24'h00AAFF &&
    //                     (word_buffer[6:0] == {7'h1} || word_buffer[6:0] == {7'h2})) begin
    //                     // TODO: maybe remove this when done checking
    //                     usb_led_o     <= 1'b1;
    //                     byte_index    <= 2'b01;
    //                     get_data_flag <= 1'b1;
    //                 end
    //                 byte_index <= byte_index + 1'b1;
    //             end
    //         end
    //     end
    //
    //     always @(posedge clk_i, negedge reset_n_local) begin
    //         if (!reset_n_local) begin
    //             write_data        <= 32'b0;
    //             word_write_strobe <= 1'b0;
    //         end else begin
    //             word_write_strobe <= 1'b0;
    //             if (get_data_flag && byte_index == 2'b00) begin
    //                 write_data <= word_buffer;
    //                 if (byte_index == 2'b00 && byte_index_old == 2'b11) word_write_strobe <= 1'b1;
    //             end
    //         end
    //     end
    //
    //
    //     reg buffer_out_ready_reg, buffer_out_ready_comb;
    assign in_correct_dfu_mode = (dfu_alt_i == DFU_ALT_UPLOAD_BITSTREAM) && dfu_mode_i;
    assign enable_buffer       = (dfu_out_en_i | ~buffer_empty) & ~dfu_clear_status_i;
    //
    assign dfu_out_valid       = (dfu_alt_i == DFU_ALT_UPLOAD_BITSTREAM) ? dfu_out_valid_i : 1'b0;
    assign dfu_out_ready_o     = (dfu_alt_i == DFU_ALT_UPLOAD_BITSTREAM) ? dfu_out_ready : 1'b0;
    // assign word_write_strobe_o = word_write_strobe_reg;
    //     assign write_data_o        = write_data_reg;
    assign reset_n_local       = in_correct_dfu_mode & reset_n_i;
    //
    //     always @(posedge clk_i, negedge reset_n_local) begin
    //         if (!reset_n_local) begin
    //             present_state <= IDLE;
    //         end else begin
    //             present_state <= present_state_next;
    //         end
    //     end
    //
    //     always @(*) begin : P_FSM
    //         present_state_next = present_state;
    //         case (present_state_next)
    //             GET_ID_00: begin
    //                 if (buffer_out_valid) present_state_next = GET_ID_AA;
    //             end
    //             GET_ID_AA: begin
    //                 if (buffer_out_valid) present_state_next = GET_ID_FF;
    //             end
    //             GET_ID_FF: begin
    //                 if (buffer_out_valid) present_state_next = GET_COMMAND;
    //             end
    //             GET_COMMAND: begin
    //                 if (buffer_out_valid) present_state_next = EVAL_COMMAND;
    //             end
    //             EVAL_COMMAND: begin
    //                 if (id_reg == 24'h00AAFF &&
    //                     (command_reg[6:0] == {7'h1} || command_reg[6:0] == {7'h2})) begin
    //                     present_state_next = GET_DATA;
    //                 end else begin
    //                     present_state_next = ERR_WRONG_COMMAND;
    //                 end
    //             end
    //             ERR_WRONG_COMMAND: begin
    //                 if (buffer_out_valid) present_state_next = IDLE;
    //             end
    //             GET_DATA: begin
    //                 present_state_next = present_state;
    //             end
    //             // IDLE
    //             default: begin
    //                 if (buffer_out_valid) present_state_next = GET_ID_00;
    //             end
    //         endcase
    //     end
    //
    //     always @(*) begin
    //         id_comb               = id_reg;
    //         command_comb          = command_reg;
    //         data_comb             = data_reg;
    //         // Usually dfu out is ready since the data can be read at every clock
    //         // cycle
    //         buffer_out_ready_comb = 1'b1;
    //         // TODO: Use logic to set the state correctly
    //         dfu_status_o          = STATUS_OK;
    //
    //         case (present_state)
    //             GET_ID_00: begin
    //                 if (buffer_out_valid) begin
    //                     id_comb[15:8] = buffer_data_out;
    //                 end
    //             end
    //             GET_ID_AA: begin
    //                 if (buffer_out_valid) begin
    //                     id_comb[7:0] = buffer_data_out;
    //                 end
    //             end
    //             GET_ID_FF: begin
    //                 if (buffer_out_valid) begin
    //                     command_comb = buffer_data_out;
    //                 end
    //             end
    //             GET_COMMAND:  buffer_out_ready_comb = 1'b0;  // Here new data cannot be read
    //             EVAL_COMMAND: buffer_out_ready_comb = 1'b0;  // Here new data cannot be read
    //             GET_DATA: begin
    //                 if (buffer_out_valid) begin
    //                     data_comb = buffer_data_out;
    //                 end
    //             end
    //             ERR_WRONG_COMMAND: begin
    //                 buffer_out_ready_comb = 1'b0;  // Here new data cannot be read
    //                 // TODO:: think about if this is the best status to set
    //                 dfu_status_o          = STATUS_errTARGET;
    //             end
    //             // IDLE
    //             default: begin
    //                 id_comb               = id_reg;
    //                 command_comb          = command_reg;
    //                 data_comb             = data_reg;
    //                 // Usually dfu out is ready since the data can be read at every clock
    //                 // cycle
    //                 buffer_out_ready_comb = 1'b1;  // Don't read data when in IDLE
    //
    //                 if (buffer_out_valid) begin
    //                     id_comb[23:16] = buffer_data_out;
    //                 end
    //             end
    //         endcase
    //     end
    //
    //     always @(posedge clk_i, negedge reset_n_local) begin
    //         if (!reset_n_local) begin
    //             id_reg               <= 24'b0;
    //             command_reg          <= 8'b0;
    //             data_reg             <= 8'b0;
    //             buffer_out_ready_reg <= 1'b0;
    //         end else begin
    //             id_reg               <= id_comb;
    //             command_reg          <= command_comb;
    //             data_reg             <= data_comb;
    //             buffer_out_ready_reg <= buffer_out_ready_comb;
    //         end
    //     end
    //
    //
    //     always @(posedge clk_i, negedge reset_n_local) begin
    //         if (!reset_n_local) get_word_state <= WAIT_FOR_WORD_0;
    //         else get_word_state <= get_word_state_next;
    //     end
    //
    //     always @(*) begin
    //         get_word_state_next = get_word_state;
    //         if (present_state == EVAL_COMMAND) begin
    //             if (buffer_out_valid) get_word_state_next = WAIT_FOR_WORD_1;
    //         end else begin
    //             case (get_word_state)
    //                 WAIT_FOR_WORD_1: begin
    //                     if (buffer_out_valid) get_word_state_next = WAIT_FOR_WORD_2;
    //                 end
    //                 WAIT_FOR_WORD_2: begin
    //                     if (buffer_out_valid) get_word_state_next = WAIT_FOR_WORD_3;
    //                 end
    //                 WAIT_FOR_WORD_3: begin
    //                     if (buffer_out_valid) get_word_state_next = WAIT_FOR_WORD_0;
    //                 end
    //                 // WAIT_FOR_WORD_0
    //                 default: begin
    //                     if (buffer_out_valid) get_word_state_next = WAIT_FOR_WORD_1;
    //                 end
    //             endcase
    //         end
    //     end
    //
    //     always @(*) begin
    //         word_write_strobe_comb = 1'b0;
    //         write_data_comb        = write_data_reg;
    //         if (present_state == EVAL_COMMAND) begin
    //             if (buffer_out_valid) write_data_comb[31:24] = data_reg;
    //         end else begin
    //             case (get_word_state)
    //                 WAIT_FOR_WORD_1: if (buffer_out_valid) write_data_comb[15:8] = data_reg;
    //                 WAIT_FOR_WORD_2:
    //                 if (buffer_out_valid) begin
    //                     write_data_comb[7:0]   = data_reg;
    //                     word_write_strobe_comb = 1'b1;
    //                 end
    //                 WAIT_FOR_WORD_3: begin
    //                     if (buffer_out_valid) write_data_comb[31:24] = data_reg;
    //                 end
    //                 // WAIT_FOR_WORD_0
    //                 default:         if (buffer_out_valid) write_data_comb[23:16] = data_reg;
    //             endcase
    //         end
    //     end
    //
    //
    //     always @(posedge clk_i, negedge reset_n_local) begin
    //         if (!reset_n_local) begin
    //             write_data_reg        <= 32'b0;
    //             word_write_strobe_reg <= 1'b0;
    //         end else begin
    //             write_data_reg        <= write_data_comb;
    //             word_write_strobe_reg <= word_write_strobe_comb;
    //         end
    //     end
    //
    // buffer #(
    //     .SIZE      (BUFFER_SIZE),
    //     .WORD_WIDTH('d8),
    //     .ADDR_WIDTH($clog2(BUFFER_SIZE))
    // ) buffer_inst (
    //     .clk_i      (clk_i),
    //     .reset_n_i  (reset_n_local),
    //     .en_i       (enable_buffer),
    //     .in_valid_i (dfu_out_valid),
    //     .in_ready_o (dfu_out_ready),
    //     .out_valid_o(buffer_out_valid),
    //     .out_ready_i(buffer_out_ready),
    //     .empty_o    (buffer_empty),
    //     .data_in_i  (dfu_out_data_i),
    //     .data_out_o (buffer_data_out),
    //     //TODO: Add justifcation why this is empty
    //     /* verilator lint_off PINCONNECTEMPTY */
    //     .full_o     ()
    //     /* verilator lint_on PINCONNECTEMPTY */
    // );
endmodule
