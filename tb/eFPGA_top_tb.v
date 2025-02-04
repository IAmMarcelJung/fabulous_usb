`timescale 1ps / 1ps
module eFPGA_top_tb;
    wire [7:0] I_top;
    wire [7:0] T_top;
    reg  [7:0] O_top = 0;
    wire [15:0] A_cfg, B_cfg;

    reg         CLK = 1'b0;
    reg         resetn = 1'b1;
    reg         SelfWriteStrobe = 1'b0;
    reg  [31:0] SelfWriteData = 1'b0;
    reg         Rx = 1'b1;
    wire        ComActive;
    wire        ReceiveLED;
    reg         s_clk = 1'b0;
    reg         s_data = 1'b0;

    // Instantiate both the fabric and the reference DUT
    eFPGA_top top_i (
        .I_top          (I_top),
        .T_top          (T_top),
        .O_top          (O_top),
        .A_config_C     (A_cfg),
        .B_config_C     (B_cfg),
        .CLK            (CLK),
        .resetn         (resetn),
        .SelfWriteStrobe(SelfWriteStrobe),
        .SelfWriteData  (SelfWriteData),
        .Rx             (Rx),
        .ComActive      (ComActive),
        .ReceiveLED     (ReceiveLED),
        .s_clk          (s_clk),
        .s_data         (s_data)
    );


    wire [7:0] I_top_gold, oeb_gold, T_top_gold;
    counter dut_i (
        .clk   (CLK),
        .io_out(I_top_gold),
        .io_oeb(oeb_gold),
        .io_in (O_top)
    );

    assign T_top_gold = ~oeb_gold;

    localparam MAX_BITBYTES = 16384;
    reg  [7:0] bitstream[0:MAX_BITBYTES-1];

    wire [7:0] test;

    assign test = bitstream[1];

    always #5000 CLK = (CLK === 1'b0);

    integer i;
    reg     have_errors = 1'b0;
    initial begin
`ifdef CREATE_FST
        $dumpfile("./build/eFPGA_top_tb.fst");
        $dumpvars(0, eFPGA_top_tb);
`endif
`ifndef EMULATION
        $readmemh("./build/counter.hex", bitstream);
        #100;
        resetn = 1'b0;
        #10000;
        resetn = 1'b1;
        #10000;
        repeat (20) @(posedge CLK);
        #2500;
        for (i = 0; i < MAX_BITBYTES; i = i + 4) begin
            SelfWriteData <= {bitstream[i], bitstream[i+1], bitstream[i+2], bitstream[i+3]};
            repeat (2) @(posedge CLK);
            SelfWriteStrobe <= 1'b1;
            @(posedge CLK);
            SelfWriteStrobe <= 1'b0;
            repeat (2) @(posedge CLK);
        end
`endif
        repeat (100) @(posedge CLK);
        O_top = 8'b00000001;  // reset
        repeat (5) @(posedge CLK);
        O_top = 8'b0;
        for (i = 0; i < 100; i = i + 1) begin
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
