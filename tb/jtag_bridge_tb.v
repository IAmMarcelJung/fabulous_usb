`timescale 1ns / 1ps

module jtag_bridge_tb ();
    // Clock and reset
    reg        clk_i;
    reg        rst_n_i;

    // USB to JTAG signals
    reg  [7:0] from_usb_data_i;
    reg        from_usb_valid_i;
    wire       from_usb_ready_o;

    // JTAG signals
    wire       tck_o;
    wire       tms_o;
    wire       tdi_o;
    wire       trst_o;
    wire       srst_o;
    reg        tdo_i;

    // JTAG to USB signals
    wire [7:0] to_usb_data_o;
    wire       to_usb_valid_o;
    reg        to_usb_ready_i;

    // LED signal
    wire       bitbang_led_o;

    // Main testbench sequence
    reg  [7:0] response;

    // Instantiate the DUT (Device Under Test)
    jtag_bridge dut (
        .clk_i           (clk_i),
        .rst_n_i         (rst_n_i),
        .from_usb_data_i (from_usb_data_i),
        .from_usb_valid_i(from_usb_valid_i),
        .from_usb_ready_o(from_usb_ready_o),
        .tck_o           (tck_o),
        .tms_o           (tms_o),
        .tdi_o           (tdi_o),
        .trst_o          (trst_o),
        .srst_o          (srst_o),
        .tdo_i           (tdo_i),
        .to_usb_data_o   (to_usb_data_o),
        .to_usb_valid_o  (to_usb_valid_o),
        .to_usb_ready_i  (to_usb_ready_i),
        .bitbang_led_o   (bitbang_led_o)
    );

    // Clock generation (50MHz)
    initial begin
        clk_i = 0;
        forever #10 clk_i = ~clk_i;  // 20ns period
    end

    // Task to send a command to the JTAG bridge
    task send_command;
        input [7:0] command;
        begin
            wait (from_usb_ready_o == 1);
            @(posedge clk_i);
            from_usb_data_i  = command;
            from_usb_valid_i = 1;
            @(posedge clk_i);
            // wait (from_usb_ready_o == 0);
            from_usb_valid_i = 0;
            @(posedge clk_i);
        end
    endtask

    // Task to read data from JTAG bridge
    task read_response;
        output [7:0] response;
        begin
            to_usb_ready_i = 1;
            wait (to_usb_valid_o == 1);
            response = to_usb_data_o;
            @(posedge clk_i);
            to_usb_ready_i = 0;
            @(posedge clk_i);
            to_usb_ready_i = 1;
        end
    endtask

    // Task to verify JTAG signals
    task check_jtag_signals;
        input expected_tck;
        input expected_tms;
        input expected_tdi;
        begin
            @(posedge clk_i);
            if ({tck_o, tms_o, tdi_o} !== {expected_tck, expected_tms, expected_tdi}) begin
                $display("Error: JTAG signals mismatch at %0t", $time);
                $display("Expected: tck=%0b, tms=%0b, tdi=%0b", expected_tck, expected_tms,
                         expected_tdi);
                $display("Got: tck=%0b, tms=%0b, tdi=%0b", tck_o, tms_o, tdi_o);
                $finish;
            end
        end
    endtask

    task send_read_command_and_read_response;
        input [7:0] expected_response;

        begin
            send_command("R");
            read_response(expected_response);
            $display("Response numeric value = %d (0x%h)", response, response);
            if (response !== expected_response) begin
                $display("Error: Expected response %c, got '%c' at %0t", expected_response,
                         response, $time);
                $finish;
            end
        end
    endtask


    initial begin
        // Initialize signals
        rst_n_i          = 0;
        from_usb_data_i  = 0;
        from_usb_valid_i = 0;
        tdo_i            = 0;
        to_usb_ready_i   = 1;

        // Apply reset
        #100;
        rst_n_i = 1;
        #100;

        $display("Test 1: Set JTAG outputs using command '0'");
        send_command("0");
        check_jtag_signals(0, 0, 0);

        $display("Test 2: Set JTAG outputs using command '1'");
        send_command("1");
        check_jtag_signals(0, 0, 1);

        $display("Test 3: Set JTAG outputs using command '2'");
        send_command("2");
        check_jtag_signals(0, 1, 0);

        $display("Test 4: Set JTAG outputs using command '3'");
        send_command("3");
        check_jtag_signals(0, 1, 1);
        //
        $display("Test 5: Set JTAG outputs using command '4'");
        send_command("4");
        check_jtag_signals(1, 0, 0);

        $display("Test 6: Set JTAG outputs using command '5'");
        send_command("5");
        check_jtag_signals(1, 0, 1);

        $display("Test 7: Set JTAG outputs using command '6'");
        send_command("6");
        check_jtag_signals(1, 1, 0);

        $display("Test 8: Set JTAG outputs using command '7'");
        send_command("7");
        check_jtag_signals(1, 1, 1);


        $display("Test 9: Turn on LED using command 'B'");
        send_command("B");
        #20;
        if (bitbang_led_o !== 1'b1) begin
            $display("Error: LED did not turn on at %0t", $time);
            $finish;
        end

        $display("Test 10: Turn off LED using command 'b'");
        send_command("b");
        #20;
        if (bitbang_led_o !== 1'b0) begin
            $display("Error: LED did not turn off at %0t", $time);
            $finish;
        end

        $display("Test 11: Set reset signals using command 't'");
        send_command("t");
        #20;
        if ({trst_o, srst_o} !== 2'b10) begin
            $display("Error: Reset signals not set correctly at %0t", $time);
            $finish;
        end

        $display("Test 12: Read TDO value when low");
        tdo_i = 0;
        send_read_command_and_read_response("0");

        $display("Test 13: Read TDO value when high");
        tdo_i = 1;
        send_read_command_and_read_response("1");

        $display("Test 14: Verify back-to-back command handling");
        send_command("1");
        check_jtag_signals(0, 0, 1);
        send_command("4");
        check_jtag_signals(1, 0, 0);

        $display("Test 15: Verify read command handshaking");
        tdo_i = 1;

        send_read_command_and_read_response("1");

        // Ensure response valid is deasserted
        if (to_usb_valid_o !== 1'b0) begin
            $display("Error: to_usb_valid_o should be 0 after reading at %0t", $time);
            $finish;
        end

        // Send another read command
        tdo_i = 0;

        send_read_command_and_read_response("0");

        $display("All tests passed successfully!");
        #100;
        $finish;
    end

    initial begin
`ifdef TOP_MODULE
        $dumpfile(`DUMP_FILE);
        $dumpvars(0, `TOP_MODULE);
`endif
    end

endmodule
