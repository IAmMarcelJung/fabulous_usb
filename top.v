`timescale 1ns / 1ps
module top #(
    parameter NUMBER_OF_ROWS     = 4,
    parameter NUMBER_OF_COLS     = 5,
    parameter FRAME_BITS_PER_ROW = 32,
    parameter MAX_FRAMES_PER_COL = 20,
    parameter DESYNC_FLAG        = 20,
    parameter FRAME_SELECT_WIDTH = 5,
    parameter ROW_SELECT_WIDTH   = 5,
    parameter NUM_USED_IOS       = 8,
    parameter NUM_USED_LEDS      = 4,
    parameter NUM_USED_SWITCHES  = 4,
    parameter NUM_OF_ANODES      = 4,
    parameter UART_BAUD_RATE     = 115_200,
    parameter CLOCK_FREQUENCY    = 12_500_000

) (
    //External IO port
    inout [NUM_USED_IOS-1:0] user_io,

    //Config related ports
    input  clk,
    input  reset,
    input  Rx,
    output ReceiveLED,

    // JTAG port
    // input  tms,
    // input  tdi,
    // output tdo,
    // input  tck,

    output                     heartbeat,
    output [NUM_OF_ANODES-1:0] an          // 7 segment anodes
);

    localparam LED_FIRST_IO = NUM_USED_SWITCHES;
    localparam LED_LAST_IO = LED_FIRST_IO + NUM_USED_LEDS - 1;
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
    wire                                               resetn;

    //JTAG related signals
    // wire [                           NUM_USED_IOS-1:0] I_out;
    // wire [                           NUM_USED_IOS-1:0] O_in;
    // wire [                                       31:0] JTAGWriteData;
    // wire                                               JTAGWriteStrobe;
    // wire                                               JTAGActive;

    wire [                           NUM_USED_IOS-1:0] I_top;
    wire [                           NUM_USED_IOS-1:0] O_top;
    wire [                           NUM_USED_IOS-1:0] T_top;
    wire                                               clk_efpga;

    assign resetn = !reset;

    // verilator lint_off GENUNNAMED
    genvar i;
    generate
        for (i = 0; i < NUM_USED_IOS; i = i + 1) begin : gen_tristate_outputs
            if (i >= LED_FIRST_IO) assign user_io[i] = T_top[i] ? I_top[i] : 1'bz;
            else assign user_io[i] = 1'bz;
        end
    endgenerate
    // verilator lint_on GENUNNAMED

    assign O_top[NUM_USED_SWITCHES-1:0]    = user_io[NUM_USED_SWITCHES-1:0];
    assign O_top[LED_LAST_IO:LED_FIRST_IO] = user_io[LED_LAST_IO:LED_FIRST_IO];

    // turn off 7 segment display
    assign an                              = {NUM_OF_ANODES{1'b1}};

    // tap #(
    //     .BS_REG_IN_LEN (NUM_USED_IOS),
    //     .BS_REG_OUT_LEN(NUM_USED_IOS)
    // ) Inst_jtag (
    //     .tck           (tck),
    //     .tms           (tms),
    //     .tdi           (tdi),
    //     .tdo           (tdo),
    //     .trst          (resetn),
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
    reg [29:0] ctr;

    pll_12_5_MHz pll_12_5_MHz_inst (
        .clk_in1     (clk),        // 100 MHz input clock
        .reset       (reset),      // Reset signal to the clocking wizard
        .clk_12_5_MHz(clk_efpga),  // 12 MHz output clock
        // verilator lint_off PINCONNECTEMPTY
        .locked      ()            // Locked output signal
        // verilator lint_on PINCONNECTEMPTY
    );

    always @(posedge clk_efpga) ctr <= ctr + 1'b1;
    assign heartbeat = ctr[25];

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
        .CLK           (clk_efpga),
        .resetn        (resetn),
        // verilator lint_on PINCONNECTEMPTY

        //Config related ports
        // verilator lint_off PINCONNECTEMPTY
        .SelfWriteStrobe(),
        .SelfWriteData  (),
        .s_clk          (),
        .s_data         (),
        .ComActive      (),
        // verilator lint_on PINCONNECTEMPTY
        .Rx             (Rx),
        .ReceiveLED     (ReceiveLED)
    );


endmodule
