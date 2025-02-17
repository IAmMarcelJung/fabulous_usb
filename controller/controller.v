`timescale 1ps / 1ps
module controller #(
    parameter USE_SYSTEM_CLK       = 0,
    parameter SYSTEM_CLK_FREQUENCY = 12
) (
    input  clk_system_i,
    input  reset_n_i,
    output boot_o,

    // USB related signals
    input  clk_usb_i,
    inout  dp_io,       // USB+
    inout  dn_io,       // USB-
    output dp_pu_o,     // USB 1.5kOhm Pullup EN
    output usb_check_o, // Output to check if the USB connection is working

    // SPI flash related signals
    output sck_o,
    output cs_o,
    input  poci_i,
    output pico_o,

    // eFPGA related signals
    output [31:0] efpga_write_data_o,
    output        efpga_write_strobe_o,

    // Debug signal
    output usb_led_o
);

    // USB related definitions
    localparam CHANNELS = 'd1;
    localparam BIT_SAMPLES = 'd4;
    localparam TRANSFER_SIZE = 'd256;
    localparam POLLTIMEOUT = 'd10;  // ms
    localparam MS20 = 1;
    localparam WCID = 1;

    localparam BUFFER_SIZE = 'd512;

    // PHY signals
    wire        dp_pu;
    wire        dp_rx;
    wire        dn_rx;
    wire        dp_tx;
    wire        dn_tx;
    wire        tx_en;

    // CDC signals
    wire [ 7:0] out_data;
    wire        out_valid;
    wire        out_ready;
    wire [ 7:0] in_data;
    wire        in_valid;
    wire        in_ready;

    // DFU signals
    wire [ 2:0] dfu_alt;
    wire        dfu_out_en;
    wire        dfu_in_en;
    wire [ 7:0] dfu_out_data;
    wire        dfu_out_valid;
    wire        dfu_in_ready;
    wire [ 7:0] dfu_in_data;
    wire        dfu_in_valid;
    wire        dfu_out_ready;
    wire        dfu_clear_status;
    wire        dfu_busy;
    wire [ 3:0] dfu_status;
    wire        dfu_mode;

    // status signals
    wire [10:0] frame;
    wire        configured;


    assign dn_io       = (tx_en) ? dn_tx : 1'bz;
    assign dp_io       = (tx_en) ? dp_tx : 1'bz;
    assign dn_rx       = dn_io;
    assign dp_rx       = dp_io;
    assign dp_pu_o     = (dp_pu) ? 1'b1 : 1'bz;

    assign usb_check_o = (configured) ? ((dfu_mode) ? frame[8] : frame[9]) : ~&frame[4:3];


    // app u_app (
    //     .clk_i             (clk_system_i),
    //     .rstn_i            (reset_n_i),
    //     .out_data_i        (out_data),
    //     .out_valid_i       (out_valid),
    //     .in_ready_i        (in_ready),
    //     .out_ready_o       (out_ready),
    //     .in_data_o         (in_data),
    //     .in_valid_o        (in_valid),
    //     .dfu_mode_i        (dfu_mode),
    //     .dfu_alt_i         (dfu_alt),
    //     .dfu_out_en_i      (dfu_out_en),
    //     .dfu_in_en_i       (dfu_in_en),
    //     .dfu_out_data_i    (dfu_out_data),
    //     .dfu_out_valid_i   (dfu_out_valid),
    //     .dfu_out_ready_o   (dfu_out_ready),
    //     .dfu_in_data_o     (dfu_in_data),
    //     .dfu_in_valid_o    (dfu_in_valid),
    //     .dfu_in_ready_i    (dfu_in_ready),
    //     .dfu_clear_status_i(dfu_clear_status),
    //     .dfu_busy_o        (dfu_busy),
    //     .dfu_status_o      (dfu_status),
    //     .heartbeat_i       (configured & frame[0]),
    //     .boot_o            (boot_o),
    //     .sck_o             (sck_o),
    //     .csn_o             (cs_o),
    //     .mosi_o            (pico_o),
    //     .miso_i            (poci_i)
    // );
    // config_usb #(
    //     .BUFFER_SIZE(BUFFER_SIZE)
    // ) config_usb_inst (
    //     .clk_i              (clk_system_i),
    //     .reset_n_i          (reset_n_i),
    //     .dfu_mode_i         (dfu_mode),
    //     .dfu_alt_i          (dfu_alt),
    //     .dfu_out_en_i       (dfu_out_en),
    //     .dfu_in_en_i        (dfu_in_en),
    //     .dfu_in_data_o      (dfu_in_data),
    //     .dfu_in_valid_o     (dfu_in_valid),
    //     .dfu_in_ready_i     (dfu_in_ready),
    //     .dfu_out_data_i     (dfu_out_data),
    //     .dfu_out_valid_i    (dfu_out_valid),
    //     .dfu_out_ready_o    (dfu_out_ready),
    //     .dfu_clear_status_i (dfu_clear_status),
    //     .dfu_busy_o         (dfu_busy),
    //     .dfu_status_o       (dfu_status),
    //     .heartbeat_i        (configured & frame[0]),
    //     .word_write_strobe_o(efpga_write_strobe_o),
    //     .write_data_o       (efpga_write_data_o)
    // );
    //
    //
    // usb_dfu #(
    //     .VENDORID     (16'h1D50),
    //     .PRODUCTID    (16'h6130),
    //     .CHANNELS     (CHANNELS),
    //     .RTI_STRING   ("USB_DFU"),
    //     .SN_STRING    ("00"),
    //     .ALT_STRINGS  ("RD/WR\nRD ALL\nBOOT"),
    //     .TRANSFER_SIZE(TRANSFER_SIZE),
    //     .POLLTIMEOUT  (POLLTIMEOUT),
    //     .MS20         (MS20),
    //     .WCID         (WCID),
    //     .MAXPACKETSIZE('d8),
    //     .BIT_SAMPLES  (BIT_SAMPLES),
    //     .USE_APP_CLK  (USE_SYSTEM_CLK),
    //     .APP_CLK_FREQ (SYSTEM_CLK_FREQUENCY)
    // ) usb_dfu_inst (
    //     .frame_o           (frame),
    //     .configured_o      (configured),
    //     .app_clk_i         (clk_system_i),
    //     .clk_i             (clk_usb_i),
    //     .rstn_i            (reset_n_i),
    //     .out_ready_i       (in_ready),
    //     .in_data_i         (out_data),
    //     .in_valid_i        (out_valid),
    //     .dp_rx_i           (dp_rx),
    //     .dn_rx_i           (dn_rx),
    //     .out_data_o        (in_data),
    //     .out_valid_o       (out_valid),
    //     .in_ready_o        (in_ready),
    //     .dfu_mode_o        (dfu_mode),
    //     .dfu_alt_o         (dfu_alt),
    //     .dfu_out_en_o      (dfu_out_en),
    //     .dfu_in_en_o       (dfu_in_en),
    //     .dfu_out_data_o    (dfu_out_data),
    //     .dfu_out_valid_o   (dfu_out_valid),
    //     .dfu_out_ready_i   (dfu_out_ready),
    //     .dfu_in_data_i     (dfu_in_data),
    //     .dfu_in_valid_i    (dfu_in_valid),
    //     .dfu_in_ready_o    (dfu_in_ready),
    //     .dfu_clear_status_o(dfu_clear_status),
    //     /* verilator lint_off PINCONNECTEMPTY */
    //     .dfu_blocknum_o    (),
    //     /* verilator lint_on PINCONNECTEMPTY */
    //     .dfu_busy_i        (dfu_busy),
    //     .dfu_status_i      (dfu_status),
    //     .dp_pu_o           (dp_pu),
    //     .tx_en_o           (tx_en),
    //     .dp_tx_o           (dp_tx),
    //     .dn_tx_o           (dn_tx)
    // );


    usb_cdc #(
        .VENDORID              (16'h1D50),
        .PRODUCTID             (16'h6130),
        .CHANNELS              (CHANNELS),
        .IN_BULK_MAXPACKETSIZE ('d8),
        .OUT_BULK_MAXPACKETSIZE('d8),
        .BIT_SAMPLES           (BIT_SAMPLES),
        .USE_APP_CLK           (USE_SYSTEM_CLK),
        .APP_CLK_FREQ          (SYSTEM_CLK_FREQUENCY)
    ) usb_cdc (
        .clk_i       (clk_usb_i),
        .rstn_i      (reset_n_i),
        .app_clk_i   (clk_system_i),
        .out_data_o  (out_data),
        .out_valid_o (out_valid),
        .out_ready_i (out_ready),
        // .out_ready_i (in_ready),
        .in_data_i   (in_data),
        // .in_data_i   (out_data),
        .in_valid_i  (in_valid),
        // .in_valid_i  (out_valid),
        .in_ready_o  (in_ready),
        .frame_o     (frame),
        .configured_o(configured),
        .dp_pu_o     (dp_pu),
        .tx_en_o     (tx_en),
        .dp_tx_o     (dp_tx),
        .dn_tx_o     (dn_tx),
        .dp_rx_i     (dp_rx),
        .dn_rx_i     (dn_rx)
    );

    config_usb_cdc config_usb_cdc (
        .clk_i              (clk_system_i),
        .reset_n_i          (reset_n_i),
        .in_data_o          (in_data),
        .in_valid_o         (in_valid),
        .in_ready_i         (in_ready),
        .out_data_i         (out_data),
        .out_valid_i        (out_valid),
        .out_ready_o        (out_ready),
        .word_write_strobe_o(efpga_write_strobe_o),
        .write_data_o       (efpga_write_data_o),
        .usb_led_o          (usb_led_o)
    );

endmodule
