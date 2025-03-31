`timescale 1ps / 1ps
//  USB 2.0 full speed Communications Device Class and Device Firmware Upgrade (DFU) Class.
//  Written in verilog 2001

// USB_DFU module shall implement Full Speed (12Mbit/s) USB communications device
//   class (or USB CDC class), Abstract Control Model (ACM) subclass and DFU class.
// USB_DFU shall implement two IN/OUT FIFO interfaces between USB and external APP
//   module, one for ACM class and the other for DFU class.

module usb_dfu #(
    parameter VENDORID = 16'h0000,
    parameter PRODUCTID = 16'h0000,
    parameter CHANNELS = 'd1,
    parameter [8*32-1:0] RTI_STRING = "0",  // Run-time DFU interface string
    parameter [8*32-1:0] SN_STRING = "0",  // Run-time/DFU Mode Device Serial Number
    parameter [8*128-1:0] ALT_STRINGS = "0",  // concatenated strings separated by "\000" or by "\n"
    parameter TRANSFER_SIZE = 'd64,
    parameter POLLTIMEOUT = 'd10,  // ms
    parameter MS20 = 1,  // if 0 disable run-time MS20, enable otherwire
    parameter WCID = 1,  // if 0 disable DFU Mode WCID, enable otherwire
    parameter MAXPACKETSIZE = 'd8,
    parameter BIT_SAMPLES = 'd4,
    parameter USE_APP_CLK = 0,
    parameter APP_CLK_FREQ = 12
)  // app_clk frequency in MHz
(
    input clk_i,
    // clk_i clock shall have a frequency of 12MHz*BIT_SAMPLES
    input rstn_i,
    // While rstn_i is low (active low), the module shall be reset

    // ---- to/from Application ------------------------------------
    input                   app_clk_i,
    output [8*CHANNELS-1:0] out_data_o,
    output [  CHANNELS-1:0] out_valid_o,
    // While out_valid_o is high, the out_data_o shall be valid and both
    //   out_valid_o and out_data_o shall not change until consumed.
    input  [  CHANNELS-1:0] out_ready_i,
    // When both out_valid_o and out_ready_i are high, the out_data_o shall
    //   be consumed.
    input  [8*CHANNELS-1:0] in_data_i,
    input  [  CHANNELS-1:0] in_valid_i,
    // While in_valid_i is high, in_data_i shall be valid.
    output [  CHANNELS-1:0] in_ready_o,
    // When both in_ready_o and in_valid_i are high, in_data_i shall
    //   be consumed.
    output [          10:0] frame_o,
    // frame_o shall be last recognized USB frame number sent by USB host.
    output                  configured_o,
    // While USB_DFU is in configured state, configured_o shall be high.
    output                  dfu_mode_o,
    // While USB_DFU is in DFU Mode, dfu_mode_o shall be high.
    output [           2:0] dfu_alt_o,
    // dfu_alt_o shall report the current alternate interface setting.
    output                  dfu_out_en_o,
    // While DFU is in dfuDNBUSY|dfuDNLOAD_SYNC|dfuDNLOAD_IDLE states, dfu_out_en_o shall be high.
    output                  dfu_in_en_o,
    // While DFU is in dfuUPLOAD_IDLE state, dfu_in_en_o shall be high.
    output [           7:0] dfu_out_data_o,
    output                  dfu_out_valid_o,
    // While dfu_out_valid_o is high, the dfu_out_data_o shall be valid and both
    //   dfu_out_valid_o and dfu_out_data_o shall not change until consumed.
    input                   dfu_out_ready_i,
    // When both dfu_out_valid_o and dfu_out_ready_i are high, the dfu_out_data_o shall
    //   be consumed.
    input  [           7:0] dfu_in_data_i,
    input                   dfu_in_valid_i,
    // While dfu_in_valid_i is high, dfu_in_data_i shall be valid.
    output                  dfu_in_ready_o,
    // When both dfu_in_ready_o and dfu_in_valid_i are high, dfu_in_data_i shall
    //   be consumed.
    output                  dfu_clear_status_o,
    // While DFU is in dfuIDLE state, dfu_clear_status_o shall be high.
    output [          15:0] dfu_blocknum_o,
    // dfu_blocknum_o shall report DFU_DNLOAD/DFU_UPLOAD block sequence number.
    input                   dfu_busy_i,
    // When DFU_DNLOAD request target is busy and needs time to be ready for next data, dfu_busy_i
    //   shall be high.
    input  [           3:0] dfu_status_i,
    // dfu_status_i shall report the status resulting from the execution of the most recent DFU request.

    // ---- to USB bus physical transmitters/receivers --------------
    output dp_pu_o,
    output tx_en_o,
    output dp_tx_o,
    output dn_tx_o,
    input  dp_rx_i,
    input  dn_rx_i
);

    function integer ceil_log2;
        input [31:0] arg;
        integer i;
        begin
            ceil_log2 = 0;
            for (i = 0; i < 32; i = i + 1) begin
                if (arg > (1 << i)) ceil_log2 = ceil_log2 + 1;
            end
        end
    endfunction

    reg  [1:0] rstn_sq;

    wire       rstn;

    assign rstn = rstn_sq[0];

    always @(posedge clk_i or negedge rstn_i) begin
        if (~rstn_i) begin
            rstn_sq <= 2'd0;
        end else begin
            rstn_sq <= {1'b1, rstn_sq[1]};
        end
    end

    reg [ceil_log2(BIT_SAMPLES)-1:0] clk_cnt_q;
    reg                              clk_gate_q;

    always @(posedge clk_i or negedge rstn) begin
        if (~rstn) begin
            clk_cnt_q  <= 'd0;
            clk_gate_q <= 1'b0;
        end else begin
            if ({1'b0, clk_cnt_q} == BIT_SAMPLES - 1) begin
                clk_cnt_q  <= 'd0;
                clk_gate_q <= 1'b1;
            end else begin
                clk_cnt_q  <= clk_cnt_q + 1;
                clk_gate_q <= 1'b0;
            end
        end
    end

    reg                   dfu_clear_status_q;

    wire [8*CHANNELS-1:0] fifo2app_out_data;
    wire [  CHANNELS-1:0] fifo2app_out_valid;
    wire [  CHANNELS-1:0] fifo2app_in_ready;
    wire dfu_mode, dfu_upload, dfu_dnload;
    wire                dfu_busy_s;
    wire                dfu_status_s;
    wire                dfu_mode_s;
    wire                dfu_out_en_s;
    wire                dfu_in_en_s;
    wire                dfu_clear_status;
    wire                dfu_clear_status_s;
    wire [CHANNELS-1:0] fifo_out_empty;
    wire                bus_reset;

    assign dfu_mode_o         = dfu_mode_s;
    assign dfu_out_en_o       = dfu_out_en_s;
    assign dfu_in_en_o        = dfu_in_en_s;
    assign dfu_clear_status_o = dfu_clear_status_s;
    assign dfu_out_data_o     = fifo2app_out_data[7:0];
    assign out_data_o         = fifo2app_out_data;
    assign dfu_out_valid_o    = (dfu_dnload) ? fifo2app_out_valid[0] : 1'b0;
    assign out_valid_o        = (~dfu_mode_s) ? fifo2app_out_valid : 'd0;
    assign dfu_in_ready_o     = (dfu_upload) ? fifo2app_in_ready[0] : 1'b0;
    assign in_ready_o         = (~dfu_mode_s) ? fifo2app_in_ready : 'd0;

    generate
        if (USE_APP_CLK == 0) begin : u_sync_app
            reg dfu_busy_q;
            reg dfu_status_q;

            assign dfu_busy_s         = dfu_busy_q;
            assign dfu_status_s       = dfu_status_q;
            assign dfu_mode_s         = dfu_mode;
            assign dfu_out_en_s       = dfu_dnload | ~fifo_out_empty[0];
            assign dfu_in_en_s        = dfu_upload;
            assign dfu_clear_status_s = dfu_clear_status_q;

            always @(posedge clk_i or negedge rstn) begin
                if (~rstn) begin
                    dfu_busy_q   <= 1'b0;
                    dfu_status_q <= 1'b0;
                end else begin
                    if (clk_gate_q) begin
                        dfu_busy_q   <= dfu_busy_i;
                        dfu_status_q <= |dfu_status_i;
                    end
                end
            end
        end else begin : u_async_app
            reg  [1:0] dfu_busy_sq;
            reg  [1:0] dfu_status_sq;
            reg  [1:0] app_rstn_sq;
            reg  [1:0] dfu_mode_sq;
            reg  [1:0] dfu_out_en_sq;
            reg  [1:0] dfu_in_en_sq;
            reg  [1:0] dfu_clear_status_sq;

            wire       app_rstn;

            assign dfu_busy_s         = dfu_busy_sq[0];
            assign dfu_status_s       = dfu_status_sq[0];
            assign app_rstn           = app_rstn_sq[0];
            assign dfu_mode_s         = dfu_mode_sq[0];
            assign dfu_out_en_s       = dfu_out_en_sq[0];
            assign dfu_in_en_s        = dfu_in_en_sq[0];
            assign dfu_clear_status_s = dfu_clear_status_sq[0];

            always @(posedge clk_i or negedge rstn) begin
                if (~rstn) begin
                    dfu_busy_sq   <= 2'b0;
                    dfu_status_sq <= 2'b0;
                end else begin
                    if (clk_gate_q) begin
                        dfu_busy_sq   <= {dfu_busy_i, dfu_busy_sq[1]};
                        dfu_status_sq <= {|dfu_status_i, dfu_status_sq[1]};
                    end
                end
            end

            always @(posedge app_clk_i or negedge rstn_i) begin
                if (~rstn_i) begin
                    app_rstn_sq <= 2'd0;
                end else begin
                    app_rstn_sq <= {1'b1, app_rstn_sq[1]};
                end
            end

            always @(posedge app_clk_i or negedge app_rstn) begin
                if (~app_rstn) begin
                    dfu_mode_sq         <= 2'd0;
                    dfu_out_en_sq       <= 2'd0;
                    dfu_in_en_sq        <= 2'd0;
                    dfu_clear_status_sq <= 2'd0;
                end else begin
                    dfu_mode_sq         <= {dfu_mode, dfu_mode_sq[1]};
                    dfu_out_en_sq       <= {dfu_dnload | ~fifo_out_empty[0], dfu_out_en_sq[1]};
                    dfu_in_en_sq        <= {dfu_upload, dfu_in_en_sq[1]};
                    dfu_clear_status_sq <= {dfu_clear_status_q, dfu_clear_status_sq[1]};
                end
            end
        end
    endgenerate

    always @(posedge clk_i or negedge rstn) begin
        if (~rstn) begin
            dfu_clear_status_q <= 1'b0;
        end else begin
            if (clk_gate_q)
                dfu_clear_status_q <= (dfu_clear_status | dfu_clear_status_q) &
                    dfu_status_s & ~bus_reset;
        end
    end

    localparam [3:0] ENDP_CTRL = 'd0;

    reg  [           7:0] sie2i_in_data;
    reg                   sie2i_in_valid;
    reg                   sie2i_out_nak;

    wire [           3:0] endp;
    wire                  dfu_fifo;
    wire [           7:0] ctrl_in_data;
    wire [8*CHANNELS-1:0] fifo_in_data;
    wire                  ctrl_in_valid;
    wire [  CHANNELS-1:0] fifo_in_valid;
    wire [  CHANNELS-1:0] fifo_out_nak;
    wire [  CHANNELS-1:0] fifo_in_full;

    always @(*) begin : u_mux
        integer j;

        sie2i_in_data = (endp == ENDP_CTRL && dfu_fifo == 1'b1) ? fifo_in_data[7:0] : ctrl_in_data;
        sie2i_in_valid = (endp == ENDP_CTRL && dfu_fifo == 1'b1 && dfu_upload == 1'b1) ?
            (fifo_in_valid[0] & (fifo_in_full[0] | dfu_status_s)) : (endp == ENDP_CTRL) ?
            ctrl_in_valid : 1'b0;
        sie2i_out_nak = (endp == ENDP_CTRL && dfu_fifo == 1'b1) ? fifo_out_nak[0] : 1'b0;
        for (j = 0; j < CHANNELS; j = j + 1) begin
            if (endp == 2 * j[2:0] + 1 && dfu_mode == 1'b0) begin
                sie2i_in_data  = fifo_in_data[8*j+:8];
                sie2i_in_valid = fifo_in_valid[j];
                sie2i_out_nak  = fifo_out_nak[j];
            end
        end
    end

    wire [ 6:0] addr;
    wire [ 7:0] sie_out_data;
    wire        sie_out_valid;
    wire        sie_in_req;
    wire        sie_out_err;
    wire        setup;
    wire [15:0] in_bulk_endps;
    wire [15:0] out_bulk_endps;
    wire [15:0] in_int_endps;
    wire [15:0] out_int_endps;
    wire [15:0] in_toggle_reset;
    wire [15:0] out_toggle_reset;
    wire        sie_in_ready;
    wire        sie_in_data_ack;
    wire        sie_out_ready;
    wire        usb_en;
    wire        usb_detach;
    wire sie2i_in_zlp, ctrl_in_zlp;
    wire sie2i_in_nak;
    wire sie2i_stall, ctrl_stall;

    assign sie2i_in_zlp = (endp == ENDP_CTRL) ? ctrl_in_zlp : 1'b0;
    assign sie2i_in_nak = (endp == ENDP_CTRL && dfu_fifo == 1'b1 && dfu_upload) ?
        ~(fifo_in_full[0] | dfu_status_s) : in_int_endps[endp];
    assign sie2i_stall = (endp == ENDP_CTRL) ? ctrl_stall : 1'b0;

    sie #(
        .IN_CTRL_MAXPACKETSIZE(MAXPACKETSIZE),
        .IN_BULK_MAXPACKETSIZE(MAXPACKETSIZE),
        .BIT_SAMPLES          (BIT_SAMPLES)
    ) u_sie (
        .bus_reset_o       (bus_reset),
        .dp_pu_o           (dp_pu_o),
        .tx_en_o           (tx_en_o),
        .dp_tx_o           (dp_tx_o),
        .dn_tx_o           (dn_tx_o),
        .endp_o            (endp),
        .frame_o           (frame_o),
        .out_data_o        (sie_out_data),
        .out_valid_o       (sie_out_valid),
        .out_err_o         (sie_out_err),
        .in_req_o          (sie_in_req),
        .setup_o           (setup),
        .out_ready_o       (sie_out_ready),
        .in_ready_o        (sie_in_ready),
        .in_data_ack_o     (sie_in_data_ack),
        .in_bulk_endps_i   (in_bulk_endps),
        .out_bulk_endps_i  (out_bulk_endps),
        .in_int_endps_i    (in_int_endps),
        .out_int_endps_i   (out_int_endps),
        .in_iso_endps_i    (16'b0),
        .out_iso_endps_i   (16'b0),
        .clk_i             (clk_i),
        .rstn_i            (rstn),
        .clk_gate_i        (clk_gate_q),
        .usb_en_i          (usb_en),
        .usb_detach_i      (usb_detach),
        .dp_rx_i           (dp_rx_i),
        .dn_rx_i           (dn_rx_i),
        .addr_i            (addr),
        .in_valid_i        (sie2i_in_valid),
        .in_data_i         (sie2i_in_data),
        .in_zlp_i          (sie2i_in_zlp),
        .out_nak_i         (sie2i_out_nak),
        .in_nak_i          (sie2i_in_nak),
        .stall_i           (sie2i_stall),
        .in_toggle_reset_i (in_toggle_reset),
        .out_toggle_reset_i(out_toggle_reset)
    );

    wire ctrl2i_in_req, ctrl2i_out_ready, ctrl2i_in_ready;
    wire [         3:0] dfu_status;
    wire                dfu_done;
    wire [CHANNELS-1:0] fifo_in_empty;

    assign ctrl2i_in_req = (endp == ENDP_CTRL) ? sie_in_req : 1'b0;
    assign ctrl2i_out_ready = (endp == ENDP_CTRL) ? sie_out_ready : 1'b0;
    assign ctrl2i_in_ready = (endp == ENDP_CTRL) ? sie_in_ready : 1'b0;
    assign dfu_status = (dfu_status_s) ? ((&dfu_status_i) ? 4'h0 : dfu_status_i) :
        4'h0;  // if END operation (4'hF) report status OK
    assign dfu_done = dfu_status_s & fifo_in_empty[0];

    ctrl_endp_dfu #(
        .VENDORID              (VENDORID),
        .PRODUCTID             (PRODUCTID),
        .CHANNELS              (CHANNELS),
        .RTI_STRING            (RTI_STRING),
        .SN_STRING             (SN_STRING),
        .ALT_STRINGS           (ALT_STRINGS),
        .TRANSFER_SIZE         (TRANSFER_SIZE),
        .POLLTIMEOUT           (POLLTIMEOUT),
        .MS20                  (MS20),
        .WCID                  (WCID),
        .CTRL_MAXPACKETSIZE    (MAXPACKETSIZE),
        .IN_BULK_MAXPACKETSIZE (MAXPACKETSIZE),
        .OUT_BULK_MAXPACKETSIZE(MAXPACKETSIZE)
    ) u_ctrl_endp_dfu (
        .configured_o      (configured_o),
        .usb_en_o          (usb_en),
        .usb_detach_o      (usb_detach),
        .dfu_mode_o        (dfu_mode),
        .dfu_alt_o         (dfu_alt_o),
        .dfu_upload_o      (dfu_upload),
        .dfu_dnload_o      (dfu_dnload),
        .dfu_fifo_o        (dfu_fifo),
        .dfu_clear_status_o(dfu_clear_status),
        .dfu_blocknum_o    (dfu_blocknum_o),
        .addr_o            (addr),
        .in_data_o         (ctrl_in_data),
        .in_zlp_o          (ctrl_in_zlp),
        .in_valid_o        (ctrl_in_valid),
        .stall_o           (ctrl_stall),
        .in_bulk_endps_o   (in_bulk_endps),
        .out_bulk_endps_o  (out_bulk_endps),
        .in_int_endps_o    (in_int_endps),
        .out_int_endps_o   (out_int_endps),
        .in_toggle_reset_o (in_toggle_reset),
        .out_toggle_reset_o(out_toggle_reset),
        .clk_i             (clk_i),
        .rstn_i            (rstn),
        .clk_gate_i        (clk_gate_q),
        .bus_reset_i       (bus_reset),
        .dfu_status_i      (dfu_status),
        .dfu_busy_i        (dfu_busy_s),
        .dfu_done_i        (dfu_done),
        .out_data_i        (sie_out_data),
        .out_valid_i       (sie_out_valid),
        .out_err_i         (sie_out_err),
        .in_req_i          (ctrl2i_in_req),
        .setup_i           (setup),
        .in_data_ack_i     (sie_in_data_ack),
        .out_ready_i       (ctrl2i_out_ready),
        .in_ready_i        (ctrl2i_in_ready)
    );

    reg                   fifo_rstn_q;

    wire [  CHANNELS-1:0] app2fifo_out_ready;
    wire [8*CHANNELS-1:0] app2fifo_in_data;
    wire [  CHANNELS-1:0] app2fifo_in_valid;

    always @(posedge clk_i or negedge rstn) begin
        if (~rstn) fifo_rstn_q <= 'd0;
        else
            fifo_rstn_q <= ~(
                dfu_mode & ~dfu_upload & ~((dfu_dnload | ~fifo_out_empty[0]) & ~dfu_clear_status));
    end

    generate
        if (CHANNELS > 1) begin : u_channels
            assign app2fifo_out_ready = (dfu_mode_s == 1'b0) ?
                out_ready_i : {out_ready_i[CHANNELS-1:1], dfu_out_ready_i & dfu_dnload};
            assign app2fifo_in_data = (dfu_mode_s == 1'b0) ?
                in_data_i : {in_data_i[8*CHANNELS-1:8], dfu_in_data_i};
            assign app2fifo_in_valid = (dfu_mode_s == 1'b0) ?
                in_valid_i : {in_valid_i[CHANNELS-1:1], dfu_in_valid_i & dfu_upload};
        end else begin : u_single_channel
            assign app2fifo_out_ready = (dfu_mode_s == 1'b0) ? out_ready_i :
                dfu_out_ready_i & dfu_dnload;
            assign app2fifo_in_data = (dfu_mode_s == 1'b0) ? in_data_i : dfu_in_data_i;
            assign
                app2fifo_in_valid = (dfu_mode_s == 1'b0) ? in_valid_i : dfu_in_valid_i & dfu_upload;
        end
    endgenerate

    genvar i;

    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin : u_fifo_endps
            wire fifo2i_in_req, fifo2i_out_ready, fifo2i_in_ready;

            assign fifo2i_in_req = ((endp == 2 * i + 1 && dfu_mode == 1'b0) ||
                                    (endp == ENDP_CTRL && dfu_fifo == 1'b1)) ? sie_in_req : 1'b0;
            assign
                fifo2i_out_ready = ((endp == 2 * i + 1 && dfu_mode == 1'b0) ||
                                    (endp == ENDP_CTRL && dfu_fifo == 1'b1)) ? sie_out_ready : 1'b0;
            assign fifo2i_in_ready = ((endp == 2 * i + 1 && dfu_mode == 1'b0) || (
                                      endp == ENDP_CTRL && dfu_fifo == 1'b1)) ? sie_in_ready : 1'b0;

            fifo #(
                .IN_MAXPACKETSIZE (MAXPACKETSIZE),
                .OUT_MAXPACKETSIZE(MAXPACKETSIZE),
                .USE_APP_CLK      (USE_APP_CLK),
                .APP_CLK_FREQ     (APP_CLK_FREQ)
            ) u_fifo (
                .in_data_o      (fifo_in_data[8*i+:8]),
                .in_valid_o     (fifo_in_valid[i]),
                .app_in_ready_o (fifo2app_in_ready[i]),
                .out_nak_o      (fifo_out_nak[i]),
                .app_out_valid_o(fifo2app_out_valid[i]),
                .app_out_data_o (fifo2app_out_data[8*i+:8]),
                .clk_i          (clk_i),
                .app_clk_i      (app_clk_i),
                .rstn_i         (fifo_rstn_q),
                .clk_gate_i     (clk_gate_q),
                .bus_reset_i    (bus_reset),
                .in_empty_o     (fifo_in_empty[i]),
                .in_full_o      (fifo_in_full[i]),
                .out_empty_o    (fifo_out_empty[i]),
                .out_data_i     (sie_out_data),
                .out_valid_i    (sie_out_valid),
                .out_err_i      (sie_out_err),
                .in_req_i       (fifo2i_in_req),
                .in_data_ack_i  (sie_in_data_ack),
                .app_in_data_i  (app2fifo_in_data[8*i+:8]),
                .app_in_valid_i (app2fifo_in_valid[i]),
                .out_ready_i    (fifo2i_out_ready),
                .in_ready_i     (fifo2i_in_ready),
                .app_out_ready_i(app2fifo_out_ready[i])
            );
        end
    endgenerate
endmodule
