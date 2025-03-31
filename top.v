`timescale 1ps / 1ps
module top #(
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
    input  clk_system_i,
    input  clk_usb_i,
    input  reset_n_i,
    input  Rx,
    output ReceiveLED,
    input  s_clk_i,
    input  s_data_i,

    // Fabric IOs
    output [(NUMBER_OF_ROWS * 2)-1:0] I_top,
    input  [(NUMBER_OF_ROWS * 2)-1:0] O_top,
    output [(NUMBER_OF_ROWS * 2)-1:0] T_top,

`ifdef JTAG
    // JTAG port
    input  tms,
    input  tdi,
    output tdo,
    input  tck,
`endif

    input  dp_rx_i,      // USB+ RX
    output dp_tx_o,      // USB+ TX
    input  dn_rx_i,      // USB- RX
    output dn_tx_o,      // USB- TX
    output dp_pu_o,      // USB 1.5kOhm Pullup EN
    output tx_en_o,
    output usb_check_o,
    output sck_o,
    output cs_o,
    input  poci_i,
    output pico_o

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

    assign efpga_reset_n = reset_n_i;

`ifdef JTAG
    //JTAG related signals
    wire [NUM_OF_FABRIC_IOS-1:0] I_out;
    wire [NUM_OF_FABRIC_IOS-1:0] O_in;
    wire [                 31:0] JTAGWriteData;
    wire                         JTAGWriteStrobe;
    wire                         JTAGActive;

    tap #(
        .bsregInLen (NUM_OF_FABRIC_IOS),
        .bsregOutLen(NUM_OF_FABRIC_IOS)
    ) Inst_jtag (
        .tck           (tck),
        .tms           (tms),
        .tdi           (tdi),
        .tdo           (tdo),
        .trst          (efpga_reset_n),
        .pins_in       (O_in),
        .pins_out      (I_out),
        .logic_pins_in (O_in),
        .logic_pins_out(I_out),
        .active        (JTAGActive),
        .config_data   (JTAGWriteData),
        .config_strobe (JTAGWriteStrobe)
    );
`endif

`ifdef JTAG
    assign efpga_write_data   = JTAGActive ? JTAGWriteData : usb_write_data;
    assign efpga_write_strobe = JTAGActive ? JTAGWriteStrobe : usb_write_strobe;
`else
    assign efpga_write_data   = usb_write_data;
    assign efpga_write_strobe = usb_write_strobe;
`endif

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
        .I_top         (I_top),
        .O_top         (O_top),
        .T_top         (T_top),
        .CLK           (clk_system_i),
        .resetn        (efpga_reset_n),
        // verilator lint_on PINCONNECTEMPTY

        //Config related ports
        .SelfWriteStrobe(efpga_write_strobe),
        .SelfWriteData  (efpga_write_data),
        .s_clk_i        (s_clk_i),
        .s_data_i       (s_data_i),
        // verilator lint_off PINCONNECTEMPTY
        .ComActive      (),
        // verilator lint_on PINCONNECTEMPTY
        .Rx             (Rx),
        .ReceiveLED     (ReceiveLED)
    );

    controller #(
        .USE_SYSTEM_CLK      (1),
        .SYSTEM_CLK_FREQUENCY(FABRIC_CLOCK_FREQUENCY / 1_000_000),
        .MAX_PACKETSIZE      (64)
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
        .sck_o               (sck_o),
        .cs_o                (cs_o),
        .poci_i              (poci_i),
        .pico_o              (pico_o),
`ifdef DEBUG
        .usb_check_o         (usb_check_o),
`endif
        .efpga_write_data_o  (usb_write_data),
        .efpga_write_strobe_o(usb_write_strobe)
    );


endmodule
