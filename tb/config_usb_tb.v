`timescale 1ps / 1ps

module config_usb_tb;

    // Parameters
    parameter BUFFER_SIZE = 512;

    // Testbench Signals (inputs to DUT are regs, outputs are wires)
    reg            clk_system;
    wire           reset_n;
    reg            dfu_mode;
    reg     [ 2:0] dfu_alt;
    reg            dfu_out_en;
    reg            dfu_in_en;
    wire    [ 7:0] dfu_in_data;
    wire           dfu_in_valid;
    wire           dfu_in_ready;
    wire    [ 7:0] dfu_out_data;
    wire           dfu_out_valid;
    wire           dfu_out_ready;
    reg            dfu_clear_status;
    wire           dfu_busy;
    wire    [ 3:0] dfu_status;
    reg            heartbeat;
    reg     [ 7:0] bitstream            [0:MAX_BITBYTES-1];
    wire           word_write_strobe;
    wire    [31:0] write_data;
    wire    [31:0] write_data_gold_next;
    reg     [31:0] write_data_gold;
    reg     [ 7:0] write_data_gold_array[             3:0];
    integer        current_byte_pos;

    localparam MAX_BITBYTES = 16384;
    // localparam PREAMBLE_SIZE = 16;

    // Instantiate the DUT
    config_usb #(
        .BUFFER_SIZE(BUFFER_SIZE)
    ) dut (
        .clk_i              (clk_system),
        .reset_n_i          (reset_n),
        .dfu_mode_i         (dfu_mode),
        .dfu_alt_i          (dfu_alt),
        .dfu_out_en_i       (dfu_out_en),
        .dfu_in_en_i        (dfu_in_en),
        .dfu_in_data_o      (dfu_in_data),
        .dfu_in_valid_o     (dfu_in_valid),
        .dfu_in_ready_i     (dfu_in_ready),
        .dfu_out_data_i     (dfu_out_data),
        .dfu_out_valid_i    (dfu_out_valid),
        .dfu_out_ready_o    (dfu_out_ready),
        .dfu_clear_status_i (dfu_clear_status),
        .dfu_busy_o         (dfu_busy),
        .dfu_status_o       (dfu_status),
        .heartbeat_i        (heartbeat),
        .word_write_strobe_o(word_write_strobe),
        .write_data_o       (write_data)
    );

    // Instantiate the module containing utility used in the testbench
    tb_utils #(
        .MAX_BITBYTES(MAX_BITBYTES)
    ) tb_utils_inst (
        .clk_i              (clk_system),
        .reset_n_o          (reset_n),
        .out_data_o         (dfu_out_data),
        .out_valid_o        (dfu_out_valid),
        .out_ready          (dfu_out_ready),
        .write_data_i       (write_data),
        .word_write_strobe_i(word_write_strobe)
    );

    // Clock Generation: 100 MHz clock (10 ns period)
    initial begin
        clk_system = 1'b0;
        forever #5000 clk_system = ~clk_system;
    end

    // Heartbeat Generator (toggles every 50 ns)
    initial begin
        heartbeat = 1'b0;
        forever #50000 heartbeat = ~heartbeat;
    end

    initial begin
        tb_utils_inst.monitor_write_data();
    end

    // integer i;
    // integer timeout_counter;

    // Reset and stimulus initialization
    initial begin
        $dumpfile("./build/config_usb_tb.fst");
        $dumpvars(0, config_usb_tb);

        // $readmemh("./build/counter.hex", bitstream);
        tb_utils_inst.dump_arrays();
        tb_utils_inst.load_bitstream("./build/counter.hex");

        reset_dfu_signals();
        repeat (5) @(posedge clk_system);
        set_dfu_signals();

        tb_utils_inst.simulate_usb_bitstream_output(0);

        // Load bitstream
        // for (i = 0; i < MAX_BITBYTES; i = i + 1) begin
        //     @(posedge clk_system);
        //     dfu_out_data    = bitstream[i];
        //     dfu_out_valid   = 1'b1;
        //
        //     // Implement timeout using a loop
        //     timeout_counter = 100;  // Set timeout limit
        //     while (dfu_out_ready !== 1'b1 && timeout_counter > 0) begin
        //         #10000;  // Wait for 10 clock cylces per iteration
        //         timeout_counter = timeout_counter - 1;
        //         $display("%0d", timeout_counter);
        //     end
        //
        //     // Check if timeout occurred
        //     if (timeout_counter <= 0) begin
        //         $display("FAIL: Timeout waiting for dfu_out_ready_o at iteration %0d!", i);
        //         $finish;  // Halt simulation
        //     end
        //
        //     if (i >= PREAMBLE_SIZE) begin
        //         current_byte_pos = (i - PREAMBLE_SIZE) % 4;
        //
        //         if (current_byte_pos == 0) write_data_gold = write_data_gold_next;
        //         write_data_gold_array[current_byte_pos] = bitstream[i];
        //
        //         // Ignore the first value
        //         if (i > PREAMBLE_SIZE + 4 && word_write_strobe) begin
        //             $display("write_data: %0x, write_data_gold: %0x", write_data, write_data_gold);
        //             if (write_data !== write_data_gold) begin
        //                 $display("FAIL: Mismatch at iteration %0d!", i);
        //                 $finish;  // Halt simulation
        //             end
        //         end
        //     end
        //     // @(posedge clk_system);
        //     // dfu_out_valid = 1'b0;
        //
        // end

        // De-assert DFU mode signals after the transfers
        @(posedge clk_system);
        reset_dfu_signals();


        // Finish simulation after a while
        #10000;
        $display("SUCCESS: Simulation finished!");
        $finish;
    end

    assign write_data_gold_next = {
        write_data_gold_array[0],
        write_data_gold_array[1],
        write_data_gold_array[2],
        write_data_gold_array[3]
    };

    task reset_dfu_signals;
        begin
            dfu_mode         = 1'b0;
            dfu_alt          = 3'b000;
            dfu_out_en       = 1'b0;
            dfu_in_en        = 1'b0;
            dfu_clear_status = 1'b0;
        end
    endtask

    task set_dfu_signals;
        begin
            // Set correct dfu settings
            dfu_mode   = 1'b1;
            dfu_alt    = 3'b010;
            dfu_out_en = 1'b1;
            dfu_in_en  = 1'b1;
        end
    endtask


endmodule
