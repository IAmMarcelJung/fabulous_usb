`timescale 1ps / 1ps

module usb_uart_bridge_tb;

    // Testbench Signals (inputs to DUT are regs, outputs are wires)
    reg            clk_system;
    reg            reset_n;
    wire    [ 7:0] in_data;
    wire           in_valid;
    reg            in_ready;
    reg     [ 7:0] out_data;
    reg            out_valid;
    wire           out_ready;
    reg     [ 7:0] bitstream              [0:MAX_BITBYTES-1];
    wire           word_write_strobe;
    wire    [31:0] write_data;
    wire    [31:0] write_data_gold_next;
    reg     [31:0] write_data_gold;
    reg     [ 7:0] write_data_gold_array  [             3:0];
    reg            start_assertion = 1'b0;
    integer        current_byte_pos;

    localparam MAX_BITBYTES = 16384;
    localparam PREAMBLE_SIZE = 16;
    // Instantiate the DUT
    usb_uart_bridge dut (
        .clk_i              (clk_system),
        .reset_n_i          (reset_n),
        .in_data_o          (in_data),
        .in_valid_o         (in_valid),
        .in_ready_i         (in_ready),
        .out_data_i         (out_data),
        .out_valid_i        (out_valid),
        .out_ready_o        (out_ready),
        .word_write_strobe_o(word_write_strobe),
        .write_data_o       (write_data)
    );

    // Clock Generation: 100 MHz clock (10 ns period)
    initial begin
        clk_system = 1'b0;
        forever #5000 clk_system = ~clk_system;
    end

    integer i;
    integer timeout_counter;

    // Reset and stimulus initialization
    initial begin
`ifdef TOP_MODULE
        $dumpfile(`DUMP_FILE);
        $dumpvars(0, `TOP_MODULE);
`endif
        // $dumpfile("./build/usb_uart_bridge.fst");
        // $dumpvars(0, usb_uart_bridge_tb);
        $readmemh("./build/counter.hex", bitstream);
        // Initialize all inputs to safe values
        reset_n   = 1'b0;
        in_ready  = 1'b0;
        out_data  = 8'd0;
        out_valid = 1'b0;

        // Apply reset for 20 ns
        #20000;
        reset_n = 1'b1;
        #20000;  // Wait a couple of clock cycles after reset


        // Load bitstream
        for (i = 0; i < MAX_BITBYTES; i = i + 1) begin
            @(posedge clk_system);
            out_data        = bitstream[i];
            out_valid       = 1'b1;

            // Implement timeout using a loop
            timeout_counter = 100;  // Set timeout limit
            while (out_ready !== 1'b1 && timeout_counter > 0) begin
                #10000;  // Wait for one clock cycle per iteration
                timeout_counter = timeout_counter - 1;
                $display("%0d", timeout_counter);
            end

            // Check if timeout occurred
            if (timeout_counter <= 0) begin
                $display("FAIL: Timeout waiting for out_ready_o at iteration %0d!", i);
                $finish;  // Halt simulation
            end

            if (i >= PREAMBLE_SIZE) begin
                start_assertion  = 1'b1;
                current_byte_pos = (i - PREAMBLE_SIZE) % 4;

                if (current_byte_pos == 0) write_data_gold = write_data_gold_next;
                write_data_gold_array[current_byte_pos] = bitstream[i];

                // // Ignore the first value
                // if (i > PREAMBLE_SIZE + 4) begin
                //     $display("write_data: %0x, write_data_gold: %0x", write_data, write_data_gold);
                //     if (write_data !== write_data_gold) begin
                //         $display("FAIL: Mismatch at iteration %0d!", i);
                //         $finish;  // Halt simulation
                //     end
                // end
            end
            @(posedge clk_system);
            out_valid = 1'b0;
            repeat (5) @(posedge clk_system);

        end

        // Finish simulation after a while
        #10000;
        $display("SUCCESS: Simulation finished!", i);
        $finish;
    end

    // Monitor word_write_strobe and perform comparison
    always @(posedge clk_system) begin
        if (word_write_strobe && start_assertion) begin
            $display("write_data: %0x, write_data_gold: %0x", write_data, write_data_gold);
            if (write_data !== write_data_gold) begin
                $display("FAIL: Mismatch at iteration %0d!", i);
                $finish;  // Halt simulation
            end
        end
    end

    assign write_data_gold_next = {
        write_data_gold_array[0],
        write_data_gold_array[1],
        write_data_gold_array[2],
        write_data_gold_array[3]
    };


endmodule
