`timescale 1ps / 1ps

module phy_rx_tb;
    parameter BIT_SAMPLES = 4;
    parameter CLOCK_FREQ = 48_000_000;  // Clock frequency in Hz
    localparam CLK_PERIOD = (1_000_000_000_000 / CLOCK_FREQ);  // Half period in ps
    localparam USB_BIT_PERIOD = 4 * CLK_PERIOD;  // 12 MHz bit period

    // DUT signals
    reg        clk_i;
    reg        app_clk;
    reg        rstn_i;
    reg        clk_gate_i;
    reg        rx_en_i;
    reg        usb_detach_i;
    reg        dp_rx_i;
    reg        dn_rx_i;

    wire [7:0] rx_data_o;
    wire       rx_valid_o;
    wire       rx_err_o;
    wire       bus_reset_o;
    wire       rx_ready_o;
    wire       dp_pu_o;

    // Clock generation
    always #(CLK_PERIOD / 2) clk_i = ~clk_i;
    always #(USB_BIT_PERIOD / 2) app_clk = ~app_clk;

    // Instantiate DUT
    phy_rx #(
        .BIT_SAMPLES(BIT_SAMPLES)
    ) dut (
        .clk_i       (clk_i),
        .rstn_i      (rstn_i),
        .clk_gate_i  (clk_gate_i),
        .rx_en_i     (rx_en_i),
        .usb_detach_i(usb_detach_i),
        .dp_rx_i     (dp_rx_i),
        .dn_rx_i     (dn_rx_i),
        .rx_data_o   (rx_data_o),
        .rx_valid_o  (rx_valid_o),
        .rx_err_o    (rx_err_o),
        .bus_reset_o (bus_reset_o),
        .rx_ready_o  (rx_ready_o),
        .dp_pu_o     (dp_pu_o)
    );


    // Counter for clock gating
    reg [$clog2(BIT_SAMPLES)-1:0] gate_counter;

    // Taken from /controller/usb_cdc/usb_cdc.v
    // Generate clk_gate_i using a counter
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            gate_counter <= 0;
            clk_gate_i   <= 0;
        end else begin
            if ({1'b0, gate_counter} == BIT_SAMPLES - 1) begin
                gate_counter <= 0;
                clk_gate_i   <= 1;
            end else begin
                gate_counter <= gate_counter + 1;
                clk_gate_i   <= 0;
            end
        end
    end
    reg different;

    // Task to send a single USB bit (NRZI encoding)
    task send_usb_bit;
        input integer value;
        begin
            if (value) begin
                different = 1'b0;
                // No transition (same as previous state)
                #(USB_BIT_PERIOD);
            end else begin
                // Toggle state
                different = 1'b1;
                dp_rx_i   = ~dp_rx_i;
                dn_rx_i   = ~dn_rx_i;
                #(USB_BIT_PERIOD);
            end
        end
    endtask

    // Task to send a SYNC pattern (KJKJKJKK -> 00000001 in NRZI)
    task send_sync_packet;
        begin
            send_usb_bit(0);
            send_usb_bit(0);
            send_usb_bit(0);
            send_usb_bit(0);
            send_usb_bit(0);
            send_usb_bit(0);
            send_usb_bit(0);
            send_usb_bit(1);
        end
    endtask

    // Task to send a byte with bit stuffing
    task send_byte;
        input [7:0] data;
        integer       i;
        reg     [2:0] ones_count;
        begin
            ones_count = 0;

            for (i = 0; i < 8; i = i + 1) begin
                if (ones_count == 6) begin
                    // Insert stuff bit (0)
                    send_usb_bit(0);
                    ones_count = 0;
                end

                send_usb_bit(data[i]);

                if (data[i] == 1) ones_count = ones_count + 1;
                else ones_count = 0;
            end
        end
    endtask

    // Task to send EOP (End of Packet)
    task send_eop;
        begin
            // Single-Ended Zero (SE0) for 2 bit times
            dp_rx_i = 0;
            dn_rx_i = 0;
            #(2 * USB_BIT_PERIOD);

            // J state for 1 bit time
            dp_rx_i = 1;
            dn_rx_i = 0;
            #(USB_BIT_PERIOD);
        end
    endtask

    task set_idle;
        begin
            dp_rx_i = 1;
            dn_rx_i = 0;
        end
    endtask

    // Task to send a complete DATA0 packet with payload
    task send_data0_packet;
        input [7:0] byte1;
        input [7:0] byte2;
        input [7:0] byte3;
        begin
            // Send SYNC
            send_sync_packet();

            // Send PID (DATA0 = 0x03)
            send_byte(8'h03);  // DATA0 PID

            // Send payload
            send_byte(byte1);
            send_byte(byte2);
            send_byte(byte3);

            // Send EOP
            send_eop();
            set_idle();
        end
    endtask

    // Monitor for received data
    always @(posedge app_clk) begin
        if (rx_valid_o && rx_ready_o) begin
            $display("Time %t: Received data: 0x%h", $time, rx_data_o);
        end
        if (rx_err_o) begin
            $display("Time %t: Error detected!", $time);
        end
    end

    // Test sequence
    initial begin
        // Initialize inputs
        clk_i        = 0;
        app_clk      = 0;
        rstn_i       = 0;
        rx_en_i      = 0;
        usb_detach_i = 0;
        set_idle();
        // Reset assertion
        #(20 * CLK_PERIOD) rstn_i = 1;  // Deassert reset after 20 clock cycles

        // Enable reception
        #(20 * CLK_PERIOD) rx_en_i = 1;


        // wait a bit more than 16 ms to go to the attached and then into the enabled state
        #16500000000
`ifdef TOP_MODULE
        $dumpfile(`DUMP_FILE);
        $dumpvars(0, `TOP_MODULE);
`endif

        #(20 * CLK_PERIOD)
        // Send a DATA0 packet with example payload
        send_data0_packet(
            8'hA5, 8'h5A, 8'hF0);


        // Check if data is valid
        #(10 * USB_BIT_PERIOD);

        #(20 * CLK_PERIOD)
        // Send a DATA0 packet with example payload
        send_data0_packet(
            8'hA5, 8'h5A, 8'hF0);


        // Check if data is valid
        #(10 * USB_BIT_PERIOD);
        $finish;

    end

endmodule
