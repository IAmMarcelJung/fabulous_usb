`timescale 1ps / 1ps
module top_tb;
    wire [ 7:0] user_io;
    wire [ 7:0] user_io_gold;
    reg  [ 7:0] O_top;

    reg         CLK = 1'b0;
    reg         reset = 1'b0;
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
        .user_io   (user_io),
        //Config related ports
        .clk       (CLK),
        .reset     (reset),
        .Rx        (uart_serial),
        .ReceiveLED(ReceiveLED),

        .heartbeat(heartbeat),
        .an       (an)          // 7 segment anodes
    );
    assign user_io[3:0]      = O_top[3:0];
    assign user_io_gold[3:0] = O_top[3:0];

    always @(posedge CLK) ctr <= ctr + 1'b1;
    assign heartbeat_gold = ctr[25];

    wire [7:0] I_top_gold, oeb_gold;
    test_design dut_i (
        .clk   (CLK),
        .io_out(I_top_gold),
        .io_oeb(oeb_gold),
        .io_in (O_top)
    );

    genvar user_io_num;
    generate
        for (
            user_io_num = 0; user_io_num < NUM_USED_IOS; user_io_num = user_io_num + 1
        ) begin : g_tristate_outputs
            if (user_io_num >= 4)
                assign user_io_gold[user_io_num] = oeb_gold[user_io_num] ? 1'bz :
                    I_top_gold[user_io_num];
            else assign user_io_gold[user_io_num] = 1'bz;
        end
    endgenerate
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
        $readmemh("./build/test_design.hex", bitstream);
        #100;
        uart_enable    = 1'b0;
        reset          = 1'b1;
        uart_byte      = 8'h0;
        O_top          = 8'b00000011;
        desync_flag[3] = 8'h00;
        desync_flag[2] = 8'h00;
        desync_flag[1] = 8'h10;
        desync_flag[0] = 8'h00;
        #10000;
        reset = 1'b0;  // Make sure we get a falling edge

        repeat (5) @(posedge CLK);
        reset = 1'b1;
        repeat (5) @(posedge CLK);
        reset = 1'b0;
        repeat (5) @(posedge CLK);
        reset = 1'b1;
        repeat (20) @(posedge CLK);
        reset = 1'b0;
        repeat (5) @(posedge CLK);
        for (i = 0; i < MAX_BITBYTES; i = i + 1) begin
            uart_enable = 1'b1;
            uart_byte   = bitstream[i];
            repeat (10 * CLKS_PER_BIT) @(posedge CLK);
            uart_enable = 1'b0;
            repeat (5) @(posedge CLK);
        end
        // // Desync flag
        // for (i = 0; i < 12; i = i + 1) begin
        //     uart_enable = 1'b1;
        //     uart_byte   = 8'b0;
        //     repeat (10 * CLKS_PER_BIT) @(posedge CLK);
        //     uart_enable = 1'b0;
        //     repeat (5) @(posedge CLK);
        // end
        // // Desync flag
        // for (i = 0; i < 4; i = i + 1) begin
        //     uart_enable = 1'b1;
        //     uart_byte   = desync_flag[i];
        //     repeat (10 * CLKS_PER_BIT) @(posedge CLK);
        //     uart_enable = 1'b0;
        //     repeat (5) @(posedge CLK);
        // end
`endif

        repeat (5) @(posedge CLK);
        O_top = 8'b00000010;
        repeat (5) @(posedge CLK);
        O_top = 8'b00000011;
        repeat (5) @(posedge CLK);
        O_top = 8'b00000010;
        for (i = 0; i < 100; i = i + 1) begin
            O_top[1] = ~O_top[2];
            repeat (1) @(posedge CLK);
            O_top[2] = ~O_top[1];
            @(negedge CLK);
            $display("fabric(user_io) = 0x%X gold = 0x%X,", user_io, user_io_gold);
            if (user_io !== user_io_gold) have_errors = 1'b1;
            if (heartbeat !== heartbeat_gold) begin
                have_errors = 1'b1;
                $display("heartbeat = 0x%X gold = 0x%X", heartbeat, heartbeat_gold);
            end
            if (an !== an_gold) begin
                have_errors = 1'b1;
                $display("an = 0x%X gold = 0x%X", an, an_gold);
            end
        end

        if (have_errors) $fatal;
        else $finish;
    end

endmodule
