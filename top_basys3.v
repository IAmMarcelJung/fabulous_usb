`timescale 1ps / 1ps
module top_basys3 #(
    parameter NUM_OF_ANODES     = 4,
    parameter NUM_USED_IOS      = 8,
    parameter NUM_USED_LEDS     = 5,
    parameter NUM_USED_SWITCHES = 3
) (
    //External IO port
    inout [NUM_USED_IOS-1:0] user_io,

    //Config related ports
    input  clk,
    input  reset,
    input  Rx,
    output ReceiveLED,
    input  s_clk_i,
    input  s_data_i,

    // JTAG port
`ifdef JTAG
    input  tms_i,
    input  tdi_i,
    output tdo_o,
    input  tck_i,
`endif

    output [NUM_OF_ANODES-1:0] an,         // 7 segment anodes
    inout                      dp_io,      // USB+
    inout                      dn_io,      // USB-
    output                     dp_pu_o,    // USB 1.5kOhm Pullup EN
`ifdef DEBUG
    output                     led_o,
    output                     heartbeat,
`endif
    output                     sck_o,
    output                     cs_o,
    input                      poci_i,
    output                     pico_o

);


    localparam LED_FIRST_IO = NUM_USED_SWITCHES;
    localparam LED_LAST_IO = LED_FIRST_IO + NUM_USED_LEDS - 1;

    // DFU related parameters
    localparam CHANNELS = 'd3
        ;  // Channel 1: eFPGA Config, CHANNEL 2: eFPGA Manta Logic Analyzer, Channel 3: Ibex JTAG
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

    wire                    dp_tx;
    wire                    dp_rx;
    wire                    dn_tx;
    wire                    dn_rx;
    wire                    tx_en;
    wire                    dp_pu;

    assign reset_n = !reset & locked;
    assign dp_io   = tx_en ? dp_tx : 1'bz;
    assign dn_io   = tx_en ? dn_tx : 1'bz;
    assign dp_pu_o = dp_pu ? 1'b1 : 1'bz;
    assign dp_rx   = dp_io;
    assign dn_rx   = dn_io;

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

    pll_48_24_MHz pll_48_24_MHz_int (
        .clk_in1   (clk),         // 100 MHz input clock
        .reset     (reset),       // Reset signal to the clocking wizard
        .clk_5_MHz (),            // 5 MHz output clock
        .clk_6_MHz (),            // 6 MHz output clock
        .clk_12_MHz(clk_system),  // 12 MHz output clock
        .clk_24_MHz(),            // 24 MHz output clock
        .clk_48_MHz(clk_usb),     // 48 MHz output clock
        .locked    (locked)       // Locked output signal
    );

    reg [29:0] ctr;
    always @(posedge clk_system) ctr <= ctr + 1'b1;
    assign heartbeat = ctr[23];

    top top_inst (
        .clk_system_i(clk_system),
        .clk_usb_i   (clk_usb),
        .reset_n_i   (reset_n),
        .Rx          (Rx),
        .ReceiveLED  (ReceiveLED),
        .s_clk_i     (s_clk_i),
        .s_data_i    (s_data_i),
        .I_top       (I_top),
        .O_top       (O_top),
        .T_top       (T_top),
        .dp_tx_o     (dp_tx),
        .dp_rx_i     (dp_rx),
        .dn_tx_o     (dn_tx),
        .dn_rx_i     (dn_rx),
        .dp_pu_o     (dp_pu),
        .tx_en_o     (tx_en),
`ifdef DEBUG
        .usb_check_o (led_o),
`endif
`ifdef JTAG
        .tms         (tms_i),
        .tdi         (tdi_i),
        .tdo         (tdo_o),
        .tck         (tck_i),
`endif
        .sck_o       (sck_o),
        .cs_o        (cs_o),
        .poci_i      (poci_i),
        .pico_o      (pico_o)
    );

endmodule
