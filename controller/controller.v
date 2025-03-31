`timescale 1ps / 1ps
module controller #(
    parameter USE_SYSTEM_CLK       = 1,
    parameter SYSTEM_CLK_FREQUENCY = 12,
    parameter MAX_PACKETSIZE       = 8
) (
    input clk_system_i,
    input reset_n_i,

    // USB related signals
    input  clk_usb_i,
    output dp_tx_o,    // USB+
    input  dp_rx_i,    // USB+
    output dn_tx_o,    // USB-
    input  dn_rx_i,    // USB-
    output dp_pu_o,    // USB 1.5kOhm Pullup EN
    output tx_en_o,

    // JTAG related signals
    output tms_o,
    output tck_o,
    output tdi_o,
    input  tdo_i,
    output srst_o,
    output trst_o,

    // Debug signals
`ifdef DEBUG
    output        usb_check_o,          // Output to check if the USB connection is working
    output        jtag_led,
    input  [29:0] ctr,
`endif
    // eFPGA related signals
    output [31:0] efpga_write_data_o,
    output        efpga_write_strobe_o,

    input  [7:0] from_efpga_data_i,
    input        from_efpga_valid_i,
    output       from_efpga_ready_o,
    output [7:0] to_efpga_data_o,
    output       to_efpga_valid_o,
    input        to_efpga_ready_i

);
    // USB related definitions
    localparam EFPGA_CONFIG = 0, EFPGA_USER_DESIGN = 1, JTAG = 2;
    localparam EFPGA_LSB = EFPGA_CONFIG * 8;
    localparam EFPGA_MSB = EFPGA_CONFIG * 8 + 7;
    localparam EFPGA_USER_DESIGN_LSB = EFPGA_USER_DESIGN * 8;
    localparam EFPGA_USER_DESIGN_MSB = EFPGA_USER_DESIGN * 8 + 7;
    localparam JTAG_LSB = JTAG * 8;
    localparam JTAG_MSB = JTAG * 8 + 7;
    localparam CHANNELS = 'd3;
    localparam BIT_SAMPLES = 'd4;

    // PHY signals
    wire                    dp_pu;
    wire                    dp_tx;
    wire                    dp_rx;
    wire                    dn_tx;
    wire                    dn_rx;
    wire                    tx_en;

    // Registers for phy signals to decouple the macro
    // reg                     dp_tx_r;
    // reg                     dp_pu_r;
    // reg                     dn_tx_r;
    // reg                     dp_rx_r;
    // reg                     dn_rx_r;
    // reg                     tx_en_r;

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

    // NOTE: Just used for testing the manta communication
    // TODO: remove
    // manta manta_inst (
    //     .clk           (clk_system_i),
    //     .rst           (!reset_n_i),
    //     .receive_data  (out_data[MANTA_MSB:MANTA_LSB]),
    //     .receive_ready (out_ready[MANTA]),
    //     .receive_valid (out_valid[MANTA]),
    //     .transmit_data (in_data[MANTA_MSB:MANTA_LSB]),
    //     .transmit_ready(in_ready[MANTA]),
    //     .transmit_valid(in_valid[MANTA]),
    //     .ctr           (ctr)
    // );
    // manta manta_inst (
    //     .clk           (clk),
    //     .rst           (rst),
    //     .from_usb_data (from_usb_data),
    //     .from_usb_ready(from_usb_ready),
    //     .from_usb_valid(from_usb_valid),
    //     .to_usb_data   (to_usb_data),
    //     .to_usb_ready  (to_usb_ready),
    //     .to_usb_valid  (to_usb_valid),
    //     .usb_tx        (usb_tx),
    //     .jtag_tck      (jtag_tck),
    //     .jtag_tdo      (jtag_tdo),
    //     .jtag_tms      (jtag_tms),
    //     .jtag_tdi      (jtag_tdi)
    // );

    // assign dn_tx_o = dn_tx_r;
    // assign dp_tx_o = dp_tx_r;
    // assign dp_pu_o = dp_pu_r;
    // assign tx_en_o = tx_en_r;
    // assign dp_rx   = dp_rx_r;
    // assign dn_rx   = dn_rx_r;
    //

    assign dn_tx_o = dn_tx;
    assign dp_tx_o = dp_tx;
    assign dp_pu_o = dp_pu;
    assign tx_en_o = tx_en;
    assign dp_rx = dp_rx_i;
    assign dn_rx = dn_rx_i;

    assign in_data[EFPGA_USER_DESIGN_MSB:EFPGA_USER_DESIGN_LSB] = from_efpga_data_i;
    assign in_valid[EFPGA_USER_DESIGN] = from_efpga_valid_i;
    assign from_efpga_ready_o = in_ready[EFPGA_USER_DESIGN];


    assign to_efpga_data_o = out_data[EFPGA_USER_DESIGN_MSB:EFPGA_USER_DESIGN_LSB];
    assign to_efpga_valid_o = out_valid[EFPGA_USER_DESIGN];
    assign out_ready[EFPGA_USER_DESIGN] = to_efpga_ready_i;


    // NOTE:: With the registered values communication sometimes did not work
    // correctly
    //
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


`ifdef DEBUG
    assign usb_check_o = (configured) ? frame[9] : ~&frame[4:3];
`endif
    usb_cdc #(
        // TODO: Change PID and VID if manufactured
        .VENDORID              (16'h1D50),
        .PRODUCTID             (16'h6130),
        .CHANNELS              (CHANNELS),
        .IN_BULK_MAXPACKETSIZE (MAX_PACKETSIZE),
        .OUT_BULK_MAXPACKETSIZE(MAX_PACKETSIZE),
        .BIT_SAMPLES           (BIT_SAMPLES),
        .USE_APP_CLK           (USE_SYSTEM_CLK),
        .APP_CLK_FREQ          (SYSTEM_CLK_FREQUENCY)
    ) usb_cdc_inst (
        .clk_i       (clk_usb_i),
        .rstn_i      (reset_n_i),
        .app_clk_i   (clk_system_i),
        .out_data_o  (out_data),
        .out_valid_o (out_valid),
        .out_ready_i (out_ready),
        .in_data_i   (in_data),
        .in_valid_i  (in_valid),
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

    config_usb_cdc config_usb_cdc_inst (
        .clk_i              (clk_system_i),
        .reset_n_i          (reset_n_i),
        .in_data_o          (in_data[EFPGA_MSB:EFPGA_LSB]),
        .in_valid_o         (in_valid[EFPGA_CONFIG]),
        .in_ready_i         (in_ready[EFPGA_CONFIG]),
        .out_data_i         (out_data[EFPGA_MSB:EFPGA_LSB]),
        .out_valid_i        (out_valid[EFPGA_CONFIG]),
        .out_ready_o        (out_ready[EFPGA_CONFIG]),
        .word_write_strobe_o(efpga_write_strobe_o),
        .write_data_o       (efpga_write_data_o)
    );

    jtag_bridge jtag_bridge_inst (
        .clk_i        (clk_system_i),
        .rst_n_i      (reset_n_i),
`ifdef DEBUG
        .bitbang_led_o(jtag_led),
`else
        .bitbang_led_o(),
`endif

        .from_usb_data_i (out_data[JTAG_MSB:JTAG_LSB]),
        .from_usb_valid_i(out_valid[JTAG]),
        .from_usb_ready_o(out_ready[JTAG]),
        .tck_o           (tck_o),
        .tms_o           (tms_o),
        .tdi_o           (tdi_o),
        .tdo_i           (tdo_i),
        .trst_o          (trst_o),
        .srst_o          (srst_o),
        .to_usb_data_o   (in_data[JTAG_MSB:JTAG_LSB]),
        .to_usb_valid_o  (in_valid[JTAG]),
        .to_usb_ready_i  (in_ready[JTAG])
    );

endmodule
