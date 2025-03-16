module top_basys3 #(
    parameter SRAMInitFile = ""
) (
    // These inputs are defined in data/pins_basys3.xdc
    input             clk,
    input             IO_RST,
    input       [3:0] sw,
    input       [3:0] btn,
    output      [7:0] led,
    // input UART_RX,
    // output UART_TX,
    output      [3:0] an,
    output            configured,
    // Only used for debugging
    output            tms_o,
    output            tdi_o,
    output            tdo_o,
    output            tck_o,
    output            captured_tdo,
    output            jtag_led,
    inout  wire       dp_io,         // USB D+
    inout  wire       dn_io,         //USB D-
    output wire       dp_pu_o
);

    localparam CHANNELS = 32'd2;
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
    ) usb_cdc (
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
        .clk             (clk_system),
        .rst_n_i         (rst_n),
        .usb_data        (out_data),
        .usb_valid       (out_valid),
        .usb_data_ready_o(out_ready),
        .tck             (tck),
        .tms             (tms),
        .tdi             (tdi),
        .tdo             (tdo),
        .captured_tdo    (captured_tdo),
        .trst            (trst),
        .srst            (srst),
        .usb_out         (in_data),
        .usb_out_valid   (in_valid),
        .usb_out_ready_i (in_ready),
        .blink_led       (jtag_led)
    );

    assign rst_n = !IO_RST & locked;
    // assign io_rst_n = !IO_RST & locked & !srst;
    // Turn off the 7-segment display
    assign an    = 4'b1111;

endmodule

