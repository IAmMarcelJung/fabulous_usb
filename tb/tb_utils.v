module tb_utils #(
    parameter MAX_BITBYTES = 16384
) (
    input             clk_i,
    input      [31:0] write_data_i,
    input             word_write_strobe_i,
    input             out_ready,
    output            reset_n_o,
    output reg [ 7:0] out_data_o,
    output reg        out_valid_o
);
    localparam PREAMBLE_SIZE = 16;
    // Declare bitstream as a global variable within the module
    reg  [ 7:0] bitstream              [0:MAX_BITBYTES-1];
    reg  [31:0] write_data_gold_stored [             1:0];
    wire [31:0] write_data_gold_next;
    reg  [ 7:0] write_data_gold_bytes  [             3:0];
    reg         start_assertion = 1'b0;
    reg         reset_n;
    assign reset_n_o = reset_n;

    // Used to be able to see the arrays in the waveform
    task dump_arrays;
        integer byte_index;
        begin
            for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
            $dumpvars(0, write_data_gold_bytes[byte_index]);
            for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
            $dumpvars(0, write_data_gold_stored[byte_index]);
        end
    endtask

    // Task to load bitstream from a specified file
    task load_bitstream;
        // 128 characters should be enough
        input reg [8*128:0] filename;
        begin
            $readmemh(filename, bitstream);
            $display("Bistream loaded!");
        end
    endtask

    task simulate_usb_bitstream_output;
        input integer wait_cylces;

        integer i, timeout_counter;
        integer current_byte_pos;
        integer wait_cycle_index;

        begin
            start_assertion  = 1'b0;
            reset_n          = 1'b0;
            out_data_o       = 8'd0;
            out_valid_o      = 1'b0;
            wait_cycle_index = 0;
            timeout_counter  = 100;
            current_byte_pos = 0;

            // Apply reset for 20 ns
            #20000;
            reset_n = 1'b1;
            #20000;  // Wait a couple of clock cycles after reset

            // Load bitstream
            for (i = 0; i < MAX_BITBYTES; i = i + 1) begin
                @(posedge clk_i);
                out_data_o      = bitstream[i];
                out_valid_o     = 1'b1;

                timeout_counter = 100;
                while (out_ready !== 1'b1 && timeout_counter > 0) begin
                    #10000;
                    timeout_counter = timeout_counter - 1;
                    $display("%0d", timeout_counter);
                end

                if (timeout_counter <= 0) begin
                    $display("FAIL: Timeout waiting for out_ready at iteration %0d!", i);
                    $finish;
                end
                current_byte_pos                        = i % 4;
                write_data_gold_bytes[current_byte_pos] = bitstream[i];
                if (i > PREAMBLE_SIZE) begin
                    start_assertion = 1'b1;  // Start the assertion after the preamble
                end
                write_data_gold_stored[i%2] = write_data_gold_next;

                for (
                    wait_cycle_index = 0;
                    wait_cycle_index < wait_cylces;
                    wait_cycle_index = wait_cycle_index + 1
                ) begin
                    @(posedge clk_i);
                    out_valid_o = 1'b0;
                end
            end
        end
    endtask

    task monitor_write_data;
        begin
            forever begin
                @(posedge clk_i);
                if (word_write_strobe_i && start_assertion) begin
                    $display("write_data: %0x, write_data_gold: %0x", write_data_i,
                             write_data_gold_stored[1]);
                    if (write_data_i !== write_data_gold_stored[1]) begin
                        $display("FAIL: Mismatch detected!");
                        #100000;  // Wait for one clock cycle to observe signals
                        $finish;
                    end
                end
            end
        end
    endtask
    assign write_data_gold_next = {
        write_data_gold_bytes[0],
        write_data_gold_bytes[1],
        write_data_gold_bytes[2],
        write_data_gold_bytes[3]
    };

endmodule
