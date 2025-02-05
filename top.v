`timescale 1ns / 1ps
module top #(
    parameter NUMBER_OF_ROWS     = 4,
    parameter NUMBER_OF_COLS     = 5,
    parameter FRAME_BITS_PER_ROW = 32,
    parameter MAX_FRAMES_PER_COL = 20,
    parameter DESYNC_FLAG        = 20,
    parameter FRAME_SELECT_WIDTH = 5,
    parameter ROW_SELECT_WIDTH   = 5,
    parameter UART_BAUD_RATE     = 115_200,
    parameter CLOCK_FREQUENCY    = 12_500_000

) (

    //Config related ports
    input  clk_system_i,
    input  clk_usb_i,
    input  reset_n_i,
    input  Rx,
    output ReceiveLED,

    // Fabric IOs
    output [(NUMBER_OF_ROWS * 2)-1:0] I_top,
    input  [(NUMBER_OF_ROWS * 2)-1:0] O_top,
    output [(NUMBER_OF_ROWS * 2)-1:0] T_top,


    // JTAG port
    // input  tms,
    // input  tdi,
    // output tdo,
    // input  tck,

    inout  dp_io,        // USB+
    inout  dn_io,        // USB-
    output dp_pu_o,      // USB 1.5kOhm Pullup EN
    output usb_check_o,
    output sck_o,
    output cs_o,
    input  poci_i,
    output pico_o
);


    // DFU related parameters
    localparam CHANNELS = 'd1;
    localparam BIT_SAMPLES = 'd4;
    localparam TRANSFER_SIZE = 'd256;
    localparam POLLTIMEOUT = 'd10;  // ms
    localparam MS20 = 1;
    localparam WCID = 1;
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

    //JTAG related signals
    // wire [                           NUM_USED_IOS-1:0] I_out;
    // wire [                           NUM_USED_IOS-1:0] O_in;
    // wire [                                       31:0] JTAGWriteData;
    // wire                                               JTAGWriteStrobe;
    // wire                                               JTAGActive;

    wire                                               boot;
    wire [                                       31:0] efpga_write_data;
    wire                                               efpga_write_strobe;
    wire                                               efpga_reset_n;

    assign efpga_reset_n = reset_n_i & !boot;

    // tap #(
    //     .BS_REG_IN_LEN (NUM_USED_IOS),
    //     .BS_REG_OUT_LEN(NUM_USED_IOS)
    // ) Inst_jtag (
    //     .tck           (tck),
    //     .tms           (tms),
    //     .tdi           (tdi),
    //     .tdo           (tdo),
    //     .trst          (reset_n),
    //     // verilator lint_off PINCONNECTEMPTY
    //     // TODO: connect the correct signals
    //     .pins_in       (),
    //     .pins_out      (),
    //     .logic_pins_out(),
    //     .logic_pins_in (),
    //     // verilator lint_on PINCONNECTEMPTY
    //     .active        (JTAGActive),
    //     .config_data   (JTAGWriteData),
    //     .config_strobe (JTAGWriteStrobe)
    // );
    //



    eFPGA_top #(
        .NUMBER_OF_ROWS    (NUMBER_OF_ROWS),
        .NUMBER_OF_COLS    (NUMBER_OF_COLS),
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .MAX_FRAMES_PER_COL(MAX_FRAMES_PER_COL),
        .DESYNC_FLAG       (DESYNC_FLAG),
        .FRAME_SELECT_WIDTH(FRAME_SELECT_WIDTH),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .UART_BAUD_RATE    (UART_BAUD_RATE),
        .CLOCK_FREQUENCY   (CLOCK_FREQUENCY)
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
        // verilator lint_off PINCONNECTEMPTY
        .s_clk          (),
        .s_data         (),
        .ComActive      (),
        // verilator lint_on PINCONNECTEMPTY
        .Rx             (Rx),
        .ReceiveLED     (ReceiveLED)
    );

    controller #(
        .USE_SYSTEM_CLK      (0),
        .SYSTEM_CLK_FREQUENCY(12_500_000)
    ) controller_inst (
        .clk_system_i        (clk_system_i),
        .reset_n_i           (reset_n_i),
        .boot_o              (boot),
        .clk_usb_i           (clk_usb_i),
        .dp_io               (dp_io),
        .dn_io               (dn_io),
        .dp_pu_o             (dp_pu_o),
        .usb_check_o         (usb_check_o),
        .sck_o               (sck_o),
        .cs_o                (cs_o),
        .poci_i              (poci_i),
        .pico_o              (pico_o),
        .efpga_write_data_o  (efpga_write_data),
        .efpga_write_strobe_o(efpga_write_strobe)
    );


endmodule
