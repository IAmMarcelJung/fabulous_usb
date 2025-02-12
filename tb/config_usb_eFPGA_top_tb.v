`timescale 1ps / 1ps
module config_usb_eFPGA_top_tb;
    // Parameters
    parameter BUFFER_SIZE = 512;

    wire [7:0] I_top;
    wire [7:0] T_top;
    reg  [7:0] O_top = 0;
    wire [15:0] A_cfg, B_cfg;

    wire        efpga_write_strobe;
    wire [31:0] efpga_write_data;
    reg         Rx = 1'b1;
    wire        ComActive;
    wire        ReceiveLED;
    reg         s_clk = 1'b0;
    reg         s_data = 1'b0;


    // Testbench Signals (inputs to DUT are regs, outputs are wires)
    reg         clk;
    reg         reset_n;
    reg         dfu_mode_i;
    reg  [ 2:0] dfu_alt_i;
    reg         dfu_out_en_i;
    reg         dfu_in_en_i;
    wire [ 7:0] dfu_in_data_o;
    wire        dfu_in_valid_o;
    reg         dfu_in_ready_i;
    reg  [ 7:0] dfu_out_data_i;
    reg         dfu_out_valid_i;
    wire        dfu_out_ready_o;
    reg         dfu_clear_status_i;
    wire        dfu_busy_o;
    wire [ 3:0] dfu_status_o;
    reg         heartbeat_i;
    reg  [ 7:0] bitstream          [0:MAX_BITBYTES-1];

    localparam MAX_BITBYTES = 16384;
    // Instantiate the DUT
    config_usb #(
        .BUFFER_SIZE(BUFFER_SIZE)
    ) dut (
        .clk_i              (clk),
        .reset_n_i          (reset_n),
        .dfu_mode_i         (dfu_mode_i),
        .dfu_alt_i          (dfu_alt_i),
        .dfu_out_en_i       (dfu_out_en_i),
        .dfu_in_en_i        (dfu_in_en_i),
        .dfu_in_data_o      (dfu_in_data_o),
        .dfu_in_valid_o     (dfu_in_valid_o),
        .dfu_in_ready_i     (dfu_in_ready_i),
        .dfu_out_data_i     (dfu_out_data_i),
        .dfu_out_valid_i    (dfu_out_valid_i),
        .dfu_out_ready_o    (dfu_out_ready_o),
        .dfu_clear_status_i (dfu_clear_status_i),
        .dfu_busy_o         (dfu_busy_o),
        .dfu_status_o       (dfu_status_o),
        .heartbeat_i        (heartbeat_i),
        .word_write_strobe_o(efpga_write_strobe),
        .write_data_o       (efpga_write_data)
    );

    // Instantiate both the fabric and the reference DUT
    eFPGA_top top_i (
        .I_top           (I_top),
        .T_top           (T_top),
        .O_top           (O_top),
        .A_config_C      (A_cfg),
        .B_config_C      (B_cfg),
        .CLK             (clk),
        .resetn          (reset_n),
        .SelfWriteStrobe (efpga_write_strobe),
        .efpga_write_data(efpga_write_data),
        .Rx              (Rx),
        .ComActive       (ComActive),
        .ReceiveLED      (ReceiveLED),
        .s_clk           (s_clk),
        .s_data          (s_data)
    );


    wire [7:0] I_top_gold, oeb_gold, T_top_gold;
    counter counter_i (
        .clk   (clk),
        .io_out(I_top_gold),
        .io_oeb(oeb_gold),
        .io_in (O_top)
    );

    assign T_top_gold = ~oeb_gold;


    always #5000 clk = (clk === 1'b0);

    integer i;
    integer timeout_counter;
    reg     have_errors = 1'b0;
    initial begin
        $dumpfile("./build/config_usb_eFPGA_top_tb.fst");
        $dumpvars(0, config_usb_eFPGA_top_tb);
        $readmemh("./build/counter.hex", bitstream);
        dfu_mode_i         = 1'b0;
        dfu_alt_i          = 3'b000;
        dfu_out_en_i       = 1'b0;
        dfu_in_en_i        = 1'b0;
        dfu_in_ready_i     = 1'b0;
        dfu_out_data_i     = 8'd0;
        dfu_out_valid_i    = 1'b0;
        dfu_clear_status_i = 1'b0;
        #100000;
        reset_n = 1'b0;
        #10000;
        reset_n = 1'b1;
        #10000;
        repeat (20) @(posedge clk);
        #20000;

        dfu_mode_i   = 1'b1;
        dfu_alt_i    = 3'b010;
        dfu_out_en_i = 1'b1;
        dfu_in_en_i  = 1'b1;

        // Load bitstream
        for (i = 0; i < MAX_BITBYTES; i = i + 1) begin
            @(posedge clk);
            dfu_out_data_i  = bitstream[i];
            dfu_out_valid_i = 1'b1;

            // Implement timeout using a loop
            timeout_counter = 100;  // Set timeout limit
            while (dfu_out_ready_o !== 1'b1 && timeout_counter > 0) begin
                #10000;  // Wait for 10 clock cylces per iteration
                timeout_counter = timeout_counter - 1;
                $display("%0d", timeout_counter);
            end


            // Check if timeout occurred
            if (timeout_counter <= 0) begin
                $display("FAIL: Timeout waiting for dfu_out_ready_o at iteration %0d!", i);
                $finish;  // Halt simulation
            end

            @(posedge clk);
            dfu_out_valid_i = 1'b0;
        end


        repeat (100) @(posedge clk);
        O_top = 8'b00000001;  // reset
        repeat (5) @(posedge clk);
        O_top = 8'b0;
        for (i = 0; i < 100; i = i + 1) begin
            @(negedge clk);
            $display("fabric(I_top) = 0x%X gold = 0x%X, fabric(T_top) = 0x%X gold = 0x%X", I_top,
                     I_top_gold, T_top, T_top_gold);
            if (I_top !== I_top_gold) have_errors = 1'b1;
            if (T_top !== T_top_gold) have_errors = 1'b1;
        end

        if (have_errors) $fatal;
        else $finish;
    end

endmodule
