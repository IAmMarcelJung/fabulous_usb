module ibex_jtag_usb_top #(
    parameter SRAMInitFile = ""
) (
    input             clk,
    input             IO_RST,
    input       [3:0] sw,
    input       [3:0] btn,
    output      [3:0] led,
    input             uart_rx,
    output            uart_tx,
    output      [3:0] an,
    output            configured,
    // Only used for debugging
    output            tms_o,
    output            tdi_o,
    output            tdo_o,
    output            tck_o,
    output            jtag_led,
    inout  wire       dp_io,       // USB D+
    inout  wire       dn_io,       // USB D-
    output wire       dp_pu_o
);

    localparam CHANNELS = 32'd3;
    localparam EFPGA = 0, MANTA = 1, JTAG = 2;
    localparam JTAG_LSB = JTAG * 8;
    localparam JTAG_MSB = JTAG * 8 + 7;
    localparam BIT_SAMPLES = 'd4;
    wire clk_system, clk_usb;
    wire tck, tms, tdi, tdo, trst, srst;

    assign tck_o = tck;
    assign tms_o = tms;
    assign tdi_o = tdi;
    assign tdo_o = tdo;


    wire [8*CHANNELS-1:0] out_data;
    wire [8*CHANNELS-1:0] in_data;
    wire [  CHANNELS-1:0] out_valid;
    wire [  CHANNELS-1:0] in_valid;
    wire [  CHANNELS-1:0] in_ready;
    wire [  CHANNELS-1:0] out_ready;
    wire [          10:0] frame;

    wire                  dp_pu;
    wire                  tx_en;
    wire                  dp_tx;
    wire                  dn_tx;

    wire                  dp_rx;
    wire                  dn_rx;

    wire                  rst;
    wire                  rst_n;

    wire                  locked;
    wire                  clk_48_MHz;
    wire                  clk_12_MHz;

    ibex_demo_wrapper ibex_demo_wrapper_inst (
        //input
        .clk_sys_i (clk_system),
        .rst_sys_ni(rst_n),
        .gp_i      ({sw, btn}),
        .uart_rx_i (uart_rx),

        //output
        .gp_o     (led),
        .pwm_o    (),
        .uart_tx_o(uart_tx),

        .spi_rx_i (),
        .spi_tx_o (),
        .spi_sck_o(),

        .trst_ni(!trst),
        .tms_i  (tms),
        .tck_i  (tck),
        .td_i   (tdi),
        .td_o   (tdo)
    );

    assign dn_io   = tx_en ? dn_tx : 1'bz;
    assign dp_io   = tx_en ? dp_tx : 1'bz;
    assign dn_rx   = dn_io;
    assign dp_rx   = dp_io;
    assign dp_pu_o = dp_pu ? 1'b1 : 1'bz;

    pll_48_12_MHz pll_48_12_MHz_inst (
        .clk_in1   (clk),         // 100 MHz input clock
        .reset     (IO_RST),      // Reset signal to the clocking wizard
        .clk_12_MHz(clk_system),  // 12 MHz output clock
        .clk_48_MHz(clk_usb),     // 48 MHz output clock
        .locked    (locked)       // Locked output signal
    );

    usb_cdc #(
        .VENDORID              (16'h1D50),
        .PRODUCTID             (16'h6130),
        .CHANNELS              (CHANNELS),
        .IN_BULK_MAXPACKETSIZE ('d64),
        .OUT_BULK_MAXPACKETSIZE('d64),
        .USE_APP_CLK           ('b1),
        .BIT_SAMPLES           (BIT_SAMPLES)
    ) usb_cdc_inst (
        .clk_i       (clk_usb),
        .rstn_i      (rst_n),
        .app_clk_i   (clk_system),
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

    jtag_bridge jtag_bridge_inst (
        .clk_i           (clk_system),
        .rst_n_i         (rst_n),
        .from_usb_data_i (out_data[JTAG_MSB:JTAG_LSB]),
        .from_usb_valid_i(out_valid[JTAG]),
        .from_usb_ready_o(out_ready[JTAG]),
        .tck_o           (tck),
        .tms_o           (tms),
        .tdi_o           (tdi),
        .tdo_i           (tdo),
        .trst_o          (trst),
        .srst_o          (srst),
        .to_usb_data_o   (in_data[JTAG_MSB:JTAG_LSB]),
        .to_usb_valid_o  (in_valid[JTAG]),
        .to_usb_ready_i  (in_ready[JTAG]),
        .bitbang_led_o   (jtag_led)
    );

    // assign rst_n = !IO_RST & locked & !srst;
    assign rst_n = !IO_RST & locked;
    // Turn off the 7-segment display
    assign an    = 4'b1111;

endmodule

