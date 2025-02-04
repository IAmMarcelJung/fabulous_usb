`timescale 1ps / 1ps
module eFPGA_Config (
    CLK,
    resetn,
    Rx,
    ComActive,
    ReceiveLED,
    SelfWriteData,
    SelfWriteStrobe,
    ConfigWriteData,
    ConfigWriteStrobe,
    FrameAddressRegister,
    LongFrameStrobe,
    RowSelect
    // JTAGActive,
    // JTAGWriteData,
    // JTAGWriteStrobe,
    // tck
);
    parameter NUMBER_OF_ROWS = 16;
    parameter ROW_SELECT_WIDTH = 5;
    parameter FRAME_BITS_PER_ROW = 32;
    parameter DESYNC_FLAG = 20;
    parameter UART_BAUD_RATE = 115_200;
    parameter CLOCK_FREQUENCY = 100_000_000;
    input CLK;
    input resetn;
    // UART configuration port
    input Rx;
    output ComActive;
    output ReceiveLED;
    // CPU configuration port
    input [32-1:0] SelfWriteData;  // configuration data write port
    input SelfWriteStrobe;  // must decode address and write enable

    output [32-1:0] ConfigWriteData;
    output ConfigWriteStrobe;

    output [FRAME_BITS_PER_ROW-1:0] FrameAddressRegister;
    output LongFrameStrobe;
    output [ROW_SELECT_WIDTH-1:0] RowSelect;

    // JTAG signals
    // input [31:0] JTAGWriteData;
    // input JTAGWriteStrobe;
    // input JTAGActive;
    // input tck;


    // verilator lint_off UNUSEDSIGNAL
    wire [ 7:0] Command;
    // verilator lint_on UNUSEDSIGNAL
    wire [31:0] UART_WriteData;
    wire        UART_WriteStrobe;
    wire [31:0] UART_WriteData_Mux;
    wire        UART_WriteStrobe_Mux;
    wire        UART_ComActive;
    wire        UART_LED;


    // wire [31:0] JTAGWriteData_Mux;
    // wire        JTAGWriteStrobe_Mux;

    wire        FSM_Reset;
    wire        config_clk;

    config_UART #(
        .BAUD_RATE      (UART_BAUD_RATE),
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY)

    ) INST_config_UART (
        .CLK        (CLK),
        .resetn     (resetn),
        .Rx         (Rx),
        .WriteData  (UART_WriteData),
        .ComActive  (UART_ComActive),
        .WriteStrobe(UART_WriteStrobe),
        .Command    (Command),
        .ReceiveLED (UART_LED)
    );


    // ComActive is used to switch between (bitbang+internal) port or UART (UART has therefore higher priority
    assign UART_WriteData_Mux   = UART_ComActive ? UART_WriteData : SelfWriteData;
    assign UART_WriteStrobe_Mux = UART_ComActive ? UART_WriteStrobe : SelfWriteStrobe;

    // assign JTAGWriteData_Mux    = JTAGActive ? JTAGWriteData : UART_WriteData_Mux;
    // assign JTAGWriteStrobe_Mux  = JTAGActive ? JTAGWriteStrobe : UART_WriteStrobe_Mux;

    // assign ConfigWriteData      = JTAGWriteData_Mux;
    // assign ConfigWriteStrobe    = JTAGWriteStrobe_Mux;
    assign ConfigWriteData      = UART_WriteData_Mux;
    assign ConfigWriteStrobe    = UART_WriteStrobe_Mux;

    assign FSM_Reset            = UART_ComActive;
    // assign config_clk           = JTAGActive ? tck : CLK;
    assign config_clk           = CLK;

    assign ComActive            = UART_ComActive;
    // assign ReceiveLED           = JTAGWriteStrobe ^ UART_LED;
    assign ReceiveLED           = UART_LED;

    ConfigFSM #(
        .NUMBER_OF_ROWS    (NUMBER_OF_ROWS),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .DESYNC_FLAG       (DESYNC_FLAG)
    ) ConfigFSM_inst (
        .CLK                 (config_clk),
        .resetn              (resetn),
        .WriteData           (ConfigWriteData),
        .WriteStrobe         (ConfigWriteStrobe),
        .FSM_Reset           (FSM_Reset),
        //outputs
        .FrameAddressRegister(FrameAddressRegister),
        .LongFrameStrobe     (LongFrameStrobe),
        .RowSelect           (RowSelect)
    );

endmodule
