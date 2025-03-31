`timescale 1ps / 1ps
module top_debug_and_boot_system #(
    parameter NUMBER_OF_ROWS         = 4,
    parameter NUMBER_OF_COLS         = 5,
    parameter FRAME_BITS_PER_ROW     = 32,
    parameter MAX_FRAMES_PER_COL     = 20,
    parameter DESYNC_FLAG            = 20,
    parameter FRAME_SELECT_WIDTH     = 5,
    parameter ROW_SELECT_WIDTH       = 5,
    parameter UART_BAUD_RATE         = 115_200,
    parameter FABRIC_CLOCK_FREQUENCY = 12_000_000

) (

    //Config related ports
    input clk_system_i,
    input clk_usb_i,
    input reset_n_i,
    // input  Rx,
    // output ReceiveLED,
    // input  s_clk_i,
    // input  s_data_i,

    // Fabric IOs
    output [(NUMBER_OF_ROWS * 2)-1:0] I_top,
    input  [(NUMBER_OF_ROWS * 2)-1:0] O_top,
    output [(NUMBER_OF_ROWS * 2)-1:0] T_top,


    // USB signals
    input  dp_rx_i,  // USB+ RX
    output dp_tx_o,  // USB+ TX
    input  dn_rx_i,  // USB- RX
    output dn_tx_o,  // USB- TX
    output dp_pu_o,  // USB 1.5kOhm Pullup EN
    output tx_en_o,

`ifdef DEBUG
    // NOTE: just for testing
    input  [29:0] ctr,
    output        jtag_led,
    output        usb_check_o,
`endif

    // SOC signals
    input  [3:0] sw,
    input  [3:0] btn,
    output [3:0] led,
    input        uart_rx,
    output       uart_tx
    // output sck_o,
    // output cs_o,
    // input  poci_i,
    // output pico_o

);

    // Each W_IO tile has two IOs
    localparam NUM_OF_FABRIC_IOS = NUMBER_OF_ROWS * 2;

    //BlockRAM ports

    wire [                                     64-1:0] RAM2FAB_D_I;
    wire [                                     64-1:0] FAB2RAM_D_O;
    wire [                                     32-1:0] FAB2RAM_A_O;
    // verilator lint_off UNUSEDSIGNAL
    // Parts of the signal are unused
    wire [                                     16-1:0] FAB2RAM_C_O;
    // verilator lint_off UNUSEDSIGNAL

    //Signal declarations
    wire [    (NUMBER_OF_ROWS*FRAME_BITS_PER_ROW)-1:0] FrameRegister;
    wire [    (MAX_FRAMES_PER_COL*NUMBER_OF_COLS)-1:0] FrameSelect;
    wire [(FRAME_BITS_PER_ROW*(NUMBER_OF_ROWS+2))-1:0] FrameData;
    // verilator lint_off UNUSEDSIGNAL
    // Parts of the signal are unused
    wire [                     FRAME_BITS_PER_ROW-1:0] FrameAddressRegister;
    // verilator lint_off UNUSEDSIGNAL
    wire                                               LongFrameStrobe;
    wire [                                       31:0] LocalWriteData;
    wire                                               LocalWriteStrobe;
    wire [                       ROW_SELECT_WIDTH-1:0] RowSelect;

    wire [                                       31:0] usb_write_data;
    wire                                               usb_write_strobe;
    wire [                                       31:0] efpga_write_data;
    wire                                               efpga_write_strobe;
    wire                                               efpga_reset_n;

    wire [                                        7:0] from_efpga_data;
    wire                                               from_efpga_valid;
    wire                                               from_efpga_ready;
    wire [                                        7:0] to_efpga_data;
    wire                                               to_efpga_valid;
    wire                                               to_efpga_ready;

    // JTAG signals
    wire tck, tms, tdi, tdo, trst, srst;

    assign efpga_reset_n      = reset_n_i;

    assign efpga_write_data   = usb_write_data;
    assign efpga_write_strobe = usb_write_strobe;


    // manta manta_inst (
    //     .clk(clk_system_i),
    //     .rst(!reset_n_i),
    //     .rx (uart_rx),
    //     .tx (uart_tx),
    //     .ctr(ctr)
    // );


    eFPGA_top #(
        .NUMBER_OF_ROWS    (NUMBER_OF_ROWS),
        .NUMBER_OF_COLS    (NUMBER_OF_COLS),
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .MAX_FRAMES_PER_COL(MAX_FRAMES_PER_COL),
        .DESYNC_FLAG       (DESYNC_FLAG),
        .FRAME_SELECT_WIDTH(FRAME_SELECT_WIDTH),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .UART_BAUD_RATE    (UART_BAUD_RATE),
        .CLOCK_FREQUENCY   (FABRIC_CLOCK_FREQUENCY)
    ) eFPGA_top_inst (

        // verilator lint_off PINCONNECTEMPTY
        .A_config_C    (),
        .B_config_C    (),
        .Config_accessC(),
        // verilator lint_on PINCONNECTEMPTY
        .I_top         (I_top),
        .O_top         (O_top),
        .T_top         (T_top),
        .CLK           (clk_system_i),
        .resetn        (efpga_reset_n),

        //Config related ports
        .SelfWriteStrobe   (efpga_write_strobe),
        .SelfWriteData     (efpga_write_data),
        // verilator lint_off PINCONNECTEMPTY
        .s_clk_i           (),
        .s_data_i          (),
        .ComActive         (),
        .Rx                (),
        .ReceiveLED        (),
        .to_efpga_data_i   (to_efpga_data),
        .to_efpga_valid_i  (to_efpga_valid),
        .to_efpga_ready_o  (to_efpga_ready),
        .from_efpga_data_o (from_efpga_data),
        .from_efpga_valid_o(from_efpga_valid),
        .from_efpga_ready_i(from_efpga_ready)
        // verilator lint_on PINCONNECTEMPTY
    );

    ibex_demo_wrapper ibex_demo_wrapper_inst (
        //input
        .clk_sys_i (clk_system_i),
        .rst_sys_ni(reset_n_i),
        .gp_i      ({sw, btn}),
        // .uart_rx_i (uart_rx),
        .uart_rx_i (1'b0),

        //output
        .gp_o(led),
        // .uart_tx_o(uart_tx),

        // Unused
        // verilator lint_off PINCONNECTEMPTY
        .pwm_o    (),
        .spi_rx_i (),
        .spi_tx_o (),
        .spi_sck_o(),
        // verilator lint_on PINCONNECTEMPTY

        .trst_ni(!trst),
        .tms_i  (tms),
        .tck_i  (tck),
        .td_i   (tdi),
        .td_o   (tdo)
    );

    controller #(
        .USE_SYSTEM_CLK      (1),
        .SYSTEM_CLK_FREQUENCY(FABRIC_CLOCK_FREQUENCY / 1_000_000),
        .MAX_PACKETSIZE      (32)
    ) controller_inst (
        .clk_system_i        (clk_system_i),
        .reset_n_i           (reset_n_i),
        .clk_usb_i           (clk_usb_i),
        .dp_tx_o             (dp_tx_o),
        .dp_rx_i             (dp_rx_i),
        .dn_tx_o             (dn_tx_o),
        .dn_rx_i             (dn_rx_i),
        .dp_pu_o             (dp_pu_o),
        .tx_en_o             (tx_en_o),
        .tms_o               (tms),
        .tck_o               (tck),
        .tdi_o               (tdi),
        .tdo_i               (tdo),
        .srst_o              (),
        .trst_o              (trst_o),
`ifdef DEBUG
        .usb_check_o         (usb_check_o),
        .jtag_led            (jtag_led),
        .ctr                 (ctr),
`endif
        .efpga_write_data_o  (usb_write_data),
        .efpga_write_strobe_o(usb_write_strobe),
        .from_efpga_data_i   (from_efpga_data),
        .from_efpga_valid_i  (from_efpga_valid),
        .from_efpga_ready_o  (from_efpga_ready),
        .to_efpga_data_o     (to_efpga_data),
        .to_efpga_valid_o    (to_efpga_valid),
        .to_efpga_ready_i    (to_efpga_ready)
    );


endmodule
