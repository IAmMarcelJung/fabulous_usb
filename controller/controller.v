`timescale 1ps / 1ps
module controller #(
    parameter USE_SYSTEM_CLK       = 1,
    parameter SYSTEM_CLK_FREQUENCY = 12
) (
    input  clk_system_i,
    input  reset_n_i,
    output boot_o,

    // USB related signals
    input  clk_usb_i,
    output dp_tx_o,    // USB+
    input  dp_rx_i,    // USB+
    output dn_tx_o,    // USB-
    input  dn_rx_i,    // USB-
    output dp_pu_o,    // USB 1.5kOhm Pullup EN
    output tx_en_o,

    // SPI flash related signals
    output sck_o,
    output cs_o,
    input  poci_i,
    output pico_o,

    // Debug signals
`ifdef DEBUG
    output        usb_check_o,          // Output to check if the USB connection is working
`endif
    // eFPGA related signals
    output [31:0] efpga_write_data_o,
    output        efpga_write_strobe_o
);
    // USB related definitions
    localparam CHANNELS = 'd1;
    localparam BIT_SAMPLES = 'd4;

    // PHY signals
    wire                    dp_pu;
    wire                    dp_tx;
    wire                    dn_tx;
    wire                    tx_en;

    // Registers for phy signals to decouple the macro
    reg                     dp_tx_r;
    reg                     dp_pu_r;
    reg                     dn_tx_r;
    reg                     dp_rx_r;
    reg                     dn_rx_r;
    reg                     tx_en_r;

    // CDC signals
    wire [(CHANNELS*8)-1:0] out_data;
    wire [    CHANNELS-1:0] out_valid;
    wire [    CHANNELS-1:0] out_ready;
    wire [(CHANNELS*8)-1:0] in_data;
    wire [    CHANNELS-1:0] in_valid;
    wire [    CHANNELS-1:0] in_ready;


    // status signals
    wire [            10:0] frame;
    wire                    configured;



    assign dn_tx_o = dn_tx_r;
    assign dp_tx_o = dp_tx_r;
    assign dp_pu_o = dp_pu_r;
    assign tx_en_o = tx_en_r;

    assign dn_tx_o = dn_tx;
    assign dp_tx_o = dp_tx;
    assign dp_pu_o = dp_pu;
    assign tx_en_o = tx_en;

    // TODO: set an actual value
    assign boot_o  = 1'b0;
    assign sck_o   = 1'b0;
    assign sck_o   = 1'b0;
    assign cs_o    = 1'b0;
    assign pico_o  = 1'b0;



    // always @(posedge clk_system_i, negedge reset_n_i) begin
    //     if (!reset_n_i) begin
    //         dp_tx_r <= 1'b0;
    //         dn_tx_r <= 1'b0;
    //         dp_pu_r <= 1'b0;
    //         dp_rx_r <= 1'b0;
    //         dn_rx_r <= 1'b0;
    //         tx_en_r <= 1'b0;
    //     end else begin
    //         dp_tx_r <= dp_tx;
    //         dn_tx_r <= dn_tx;
    //         dp_pu_r <= dp_pu;
    //         dp_rx_r <= dp_rx_i;
    //         dn_rx_r <= dn_rx_i;
    //         tx_en_r <= tx_en;
    //     end
    // end

`ifdef USB_DFU

`ifdef DEBUG
    assign usb_check_o = (configured) ? ((dfu_mode) ? frame[8] : frame[9]) : ~&frame[4:3];
`endif
    // DFU parameters
    localparam TRANSFER_SIZE = 'd256;
    localparam POLLTIMEOUT = 'd10;  // ms
    localparam MS20 = 1;
    localparam WCID = 1;
    localparam BUFFER_SIZE = 'd512;

    // DFU signals
    wire [                2:0] dfu_alt;
    wire                       dfu_out_en;
    wire                       dfu_in_en;
    wire [(CHANNELS*8) -1 : 0] dfu_out_data;
    wire [       CHANNELS-1:0] dfu_out_valid;
    wire [       CHANNELS-1:0] dfu_in_ready;
    wire [(CHANNELS*8) -1 : 0] dfu_in_data;
    wire [       CHANNELS-1:0] dfu_in_valid;
    wire [       CHANNELS-1:0] dfu_out_ready;
    wire                       dfu_clear_status;
    wire                       dfu_busy;
    wire [                3:0] dfu_status;
    wire                       dfu_mode;

    // DFU signals
    wire [                2:0] dfu_alt;
    wire                       dfu_out_en;
    wire                       dfu_in_en;
    wire [(CHANNELS*8) -1 : 0] dfu_out_data;
    wire [       CHANNELS-1:0] dfu_out_valid;
    wire [       CHANNELS-1:0] dfu_in_ready;
    wire [(CHANNELS*8) -1 : 0] dfu_in_data;
    wire [       CHANNELS-1:0] dfu_in_valid;
    wire [       CHANNELS-1:0] dfu_out_ready;
    wire                       dfu_clear_status;
    wire                       dfu_busy;
    wire [                3:0] dfu_status;
    wire                       dfu_mode;
    config_usb #(
        .BUFFER_SIZE(BUFFER_SIZE)
    ) config_usb_inst (
        .clk_i              (clk_system_i),
        .reset_n_i          (reset_n_i),
        .dfu_mode_i         (dfu_mode),
        .dfu_alt_i          (dfu_alt),
        .dfu_out_en_i       (dfu_out_en),
        .dfu_in_en_i        (dfu_in_en),
        .dfu_in_data_o      (dfu_in_data),
        .dfu_in_valid_o     (dfu_in_valid),
        .dfu_in_ready_i     (dfu_in_ready),
        .dfu_out_data_i     (dfu_out_data),
        .dfu_out_valid_i    (dfu_out_valid),
        .dfu_out_ready_o    (dfu_out_ready),
        .dfu_clear_status_i (dfu_clear_status),
        .dfu_busy_o         (dfu_busy),
        .dfu_status_o       (dfu_status),
        .heartbeat_i        (configured & frame[0]),
        .word_write_strobe_o(efpga_write_strobe_o),
        .write_data_o       (efpga_write_data_o)
    );


    usb_dfu #(
        .VENDORID     (16'h1D50),
        .PRODUCTID    (16'h6130),
        .CHANNELS     (CHANNELS),
        .RTI_STRING   ("USB_DFU"),
        .SN_STRING    ("00"),
        .ALT_STRINGS  ("RD/WR\nRD ALL\nBOOT"),
        .TRANSFER_SIZE(TRANSFER_SIZE),
        .POLLTIMEOUT  (POLLTIMEOUT),
        .MS20         (MS20),
        .WCID         (WCID),
        .MAXPACKETSIZE('d8),
        .BIT_SAMPLES  (BIT_SAMPLES),
        .USE_APP_CLK  (USE_SYSTEM_CLK),
        .APP_CLK_FREQ (SYSTEM_CLK_FREQUENCY)
    ) usb_dfu_inst (
        .frame_o           (frame),
        .configured_o      (configured),
        .app_clk_i         (clk_system_i),
        .clk_i             (clk_usb_i),
        .rstn_i            (reset_n_i),
        .out_ready_i       (in_ready),
        .in_data_i         (out_data),
        .in_valid_i        (out_valid),
        .dp_rx_i           (dp_rx_i),
        .dn_rx_i           (dn_rx_i),
        .out_data_o        (in_data),
        .out_valid_o       (out_valid),
        .in_ready_o        (in_ready),
        .dfu_mode_o        (dfu_mode),
        .dfu_alt_o         (dfu_alt),
        .dfu_out_en_o      (dfu_out_en),
        .dfu_in_en_o       (dfu_in_en),
        .dfu_out_data_o    (dfu_out_data),
        .dfu_out_valid_o   (dfu_out_valid),
        .dfu_out_ready_i   (dfu_out_ready),
        .dfu_in_data_i     (dfu_in_data),
        .dfu_in_valid_i    (dfu_in_valid),
        .dfu_in_ready_o    (dfu_in_ready),
        .dfu_clear_status_o(dfu_clear_status),
        /* verilator lint_off PINCONNECTEMPTY */
        .dfu_blocknum_o    (),
        /* verilator lint_on PINCONNECTEMPTY */
        .dfu_busy_i        (dfu_busy),
        .dfu_status_i      (dfu_status),
        .dp_pu_o           (dp_pu),
        .tx_en_o           (tx_en),
        .dp_tx_o           (dp_tx),
        .dn_tx_o           (dn_tx)
    );

`else

`ifdef DEBUG
    assign usb_check_o = (configured) ? frame[9] : ~&frame[4:3];
`endif
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
        .dp_rx_i     (dp_rx_i),
        .dn_rx_i     (dn_rx_i)
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
        .write_data_o       (efpga_write_data_o)
    );
`endif

endmodule
