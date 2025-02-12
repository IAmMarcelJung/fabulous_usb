`timescale 1ps / 1ps
module top_basys3 #(
    parameter NUM_OF_ANODES     = 4,
    parameter NUM_USED_IOS      = 8,
    parameter NUM_USED_LEDS     = 4,
    parameter NUM_USED_SWITCHES = 4
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
    output [NUM_OF_ANODES-1:0] an,         // 7 segment anodes
    inout                      dp_io,      // USB+
    inout                      dn_io,      // USB-
    output                     dp_pu_o,    // USB 1.5kOhm Pullup EN
    output                     led_o,
    output                     sck_o,
    output                     cs_o,
    input                      poci_i,
    output                     pico_o
);

    localparam LED_FIRST_IO = NUM_USED_SWITCHES;
    localparam LED_LAST_IO = LED_FIRST_IO + NUM_USED_LEDS - 1;

    // DFU related parameters
    localparam CHANNELS = 'd1;
    localparam BIT_SAMPLES = 'd4;
    localparam TRANSFER_SIZE = 'd256;
    localparam POLLTIMEOUT = 'd10;  // ms
    localparam MS20 = 1;
    localparam WCID = 1;
    //BlockRAM ports

    wire                    reset_n;
    wire [NUM_USED_IOS-1:0] I_top;
    wire [NUM_USED_IOS-1:0] O_top;
    wire [NUM_USED_IOS-1:0] T_top;
    wire                    clk_system;
    wire                    clk_usb;
    wire                    locked;

    assign reset_n = !reset & locked;

    // verilator lint_off GENUNNAMED
    genvar i;
    generate
        for (i = 0; i < NUM_USED_IOS; i = i + 1) begin : gen_tristate_outputs
            assign user_io[i] = T_top[i] ? I_top[i] : 1'bz;
        end
    endgenerate
    // verilator lint_on GENUNNAMED

    assign O_top[NUM_USED_SWITCHES-1:0]    = user_io[NUM_USED_SWITCHES-1:0];
    assign O_top[LED_LAST_IO:LED_FIRST_IO] = user_io[LED_LAST_IO:LED_FIRST_IO];

    // turn off 7 segment display
    assign an                              = {NUM_OF_ANODES{1'b1}};

    reg [29:0] ctr;

    pll_48_12_5_MHz pll_48_12_5_MHz_inst (
        .clk_in1     (clk),         // 100 MHz input clock
        .reset       (reset),       // Reset signal to the clocking wizard
        .clk_12_5_MHz(clk_system),  // 12.5 MHz output clock
        .clk_48_MHz  (clk_usb),     // 48 MHz output clock
        .locked      (locked)       // Locked output signal
    );

    always @(posedge clk_system) ctr <= ctr + 1'b1;
    assign heartbeat = ctr[25];

    top top_inst (
        .clk_system_i(clk_system),
        .clk_usb_i   (clk_usb),
        .reset_n_i   (reset_n),
        .Rx          (Rx),
        .ReceiveLED  (ReceiveLED),
        .I_top       (I_top),
        .O_top       (O_top),
        .T_top       (T_top),
        .dp_io       (dp_io),
        .dn_io       (dn_io),
        .dp_pu_o     (dp_pu_o),
        .usb_check_o (led_o),
        .sck_o       (sck_o),
        .cs_o        (cs_o),
        .poci_i      (poci_i),
        .pico_o      (pico_o)
    );

endmodule
