`timescale 1ps / 1ps
module top_tb;
    reg  [ 7:0] O_top;
    wire [ 7:0] I_top;
    wire [ 7:0] T_top;

    reg         CLK = 1'b0;
    reg         reset_n = 1'b0;
    reg         Rx = 1'b1;
    wire        ReceiveLED;
    reg         s_clk = 1'b0;
    reg         s_data = 1'b0;
    wire [ 3:0] an;
    wire [ 3:0] an_gold = 4'b1111;
    wire        heartbeat;
    wire        heartbeat_gold;
    reg  [25:0] ctr;
    localparam NUM_USED_IOS = 8;
    localparam CLOCK_FREQUENCY = 100_000_000;
    localparam UART_BAUD_RATE = 20_000_000;

    // Instantiate both the fabric and the reference DUT
    top #(
        .UART_BAUD_RATE (UART_BAUD_RATE),
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
    ) top_i (
        .I_top       (I_top),
        .O_top       (O_top),
        .T_top       (T_top),
        //Config related ports
        .clk_system_i(CLK),
        .reset_n_i   (reset_n),
        .Rx          (uart_serial),
        .ReceiveLED  (ReceiveLED)
    );

    always @(posedge CLK) ctr <= ctr + 1'b1;
    assign heartbeat_gold = ctr[25];

    wire [7:0] I_top_gold, oeb_gold, T_top_gold;
    counter dut_i (
        .clk   (CLK),
        .io_out(I_top_gold),
        .io_oeb(oeb_gold),
        .io_in (O_top)
    );

    assign T_top_gold = ~oeb_gold;

    localparam CLKS_PER_BIT = CLOCK_FREQUENCY / UART_BAUD_RATE;
    reg        uart_enable;
    reg  [7:0] uart_byte;
    wire       uart_serial;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_inst (
        .i_Clock    (CLK),
        .i_Tx_DV    (uart_enable),
        .i_Tx_Byte  (uart_byte),
        .o_Tx_Serial(uart_serial)
    );

    localparam MAX_BITBYTES = 16384;
    reg  [7:0] bitstream  [0:MAX_BITBYTES-1];
    reg  [7:0] desync_flag[             0:3];

    wire [7:0] test;

    assign test = bitstream[1];

    always #5000 CLK = (CLK === 1'b0);

    integer i;
    reg     have_errors = 1'b0;
    initial begin
`ifdef CREATE_FST
        $dumpfile("./build/top_tb.fst");
        $dumpvars(0, top_tb);
`endif
`ifndef EMULATION
        $readmemh("./build/counter.hex", bitstream);
        #100;
        uart_enable    = 1'b0;
        reset_n        = 1'b1;
        uart_byte      = 8'h0;
        O_top          = 8'b00000011;
        desync_flag[3] = 8'h00;
        desync_flag[2] = 8'h00;
        desync_flag[1] = 8'h10;
        desync_flag[0] = 8'h00;
        #10000;

        reset_n = 1'b0;
        #10000;
        reset_n = 1'b1;
        #10000;
        repeat (20) @(posedge CLK);
        #2500;
        for (i = 0; i < MAX_BITBYTES; i = i + 1) begin
            uart_enable = 1'b1;
            uart_byte   = bitstream[i];
            repeat (10 * CLKS_PER_BIT) @(posedge CLK);
            uart_enable = 1'b0;
            repeat (5) @(posedge CLK);
        end
`endif

        repeat (100) @(posedge CLK);
        O_top = 8'b00000001;  // reset_n
        repeat (5) @(posedge CLK);
        O_top = 8'b0;
        for (i = 0; i < 100; i = i + 1) begin
            repeat (1) @(posedge CLK);
            @(negedge CLK);
            $display("fabric(I_top) = 0x%X gold = 0x%X, fabric(T_top) = 0x%X gold = 0x%X", I_top,
                     I_top_gold, T_top, T_top_gold);
            if (I_top !== I_top_gold) have_errors = 1'b1;
            if (T_top !== T_top_gold) have_errors = 1'b1;
        end

        if (have_errors) $fatal;
        else $finish;
    end

endmodule
