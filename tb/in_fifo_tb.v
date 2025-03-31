`timescale 1ns / 1ps
module in_fifo_tb ();
    // Testbench signals
    reg clk_i, app_clk_i, rstn_i, app_rstn_i, clk_gate_i;
    reg in_req_i, in_ready_i, in_data_ack_i;
    wire [7:0] in_data_o;
    wire in_valid_o, app_in_ready_o;

    // Input data simulation
    reg     [7:0] test_data  [0:7];
    integer       data_index;

    // Instantiate DUT
    in_fifo #(
        .IN_MAXPACKETSIZE(8),
        .USE_APP_CLK     (1),
        .APP_CLK_FREQ    (12)
    ) dut (
        .clk_i         (clk_i),
        .rstn_i        (rstn_i),
        .app_clk_i     (app_clk_i),
        .app_rstn_i    (app_rstn_i),
        .clk_gate_i    (clk_gate_i),
        .in_req_i      (in_req_i),
        .in_ready_i    (in_ready_i),
        .in_data_ack_i (in_data_ack_i),
        .in_data_o     (in_data_o),
        .in_valid_o    (in_valid_o),
        // Simulate input data
        .app_in_data_i (test_data[data_index]),
        .app_in_valid_i(1'b1),
        .app_in_ready_o(app_in_ready_o)
    );

    // 48 MHz clock generation (48 MHz = 20.833 ns period)
    initial begin
        clk_i = 0;
        forever #10.416 clk_i = ~clk_i;
    end

    // 12 MHz clock generation (12 MHz = 83.333 ns period)
    initial begin
        app_clk_i = 0;
        forever #41.667 app_clk_i = ~app_clk_i;
    end

    // Reset task
    task reset_dut;
        begin
            rstn_i                                = 0;
            app_rstn_i                            = 0;
            {in_req_i, in_ready_i, in_data_ack_i} = 0;
            clk_gate_i                            = 0;
            #20 rstn_i = 1;
            #20 app_rstn_i = 1;
        end
    endtask

    // Input data task
    task input_data;
        input integer num_bytes;
        integer i;
        begin
            data_index = 0;
            for (i = 0; i < num_bytes; i = i + 1) begin
                in_ready_i = 1;
                @(posedge app_clk_i);
                // wait (app_in_ready_o);
                @(posedge app_clk_i);
                data_index = data_index + 1;
            end
        end
    endtask

    // Read data task
    task read_data;
        input integer num_bytes;
        integer i;
        begin
            for (i = 0; i < num_bytes; i = i + 1) begin
                @(posedge clk_i);
                in_ready_i = 1;
                clk_gate_i = 1;
                @(posedge clk_i);
                in_ready_i = 0;
                clk_gate_i = 0;

                if (in_valid_o) begin
                    $display("Output data [%0d]: %h", i, in_data_o);
                end
            end
        end
    endtask

    // Test sequence
    initial begin
        // Initialize test data
        test_data[0] = 8'h87;
        test_data[1] = 8'h65;
        test_data[2] = 8'h43;
        test_data[3] = 8'h21;
        test_data[4] = 8'h87;
        test_data[5] = 8'h65;
        test_data[6] = 8'h43;
        test_data[7] = 8'h21;

        // Reset DUT
        reset_dut();

        // Input test data
        input_data(8);

        // Read output data
        read_data(16);
        input_data(8);
        read_data(8);

        #2000 $finish;
    end

    // Waveform dumping
    initial begin
`ifdef TOP_MODULE
        $dumpfile(`DUMP_FILE);
        $dumpvars(0, `TOP_MODULE);
`endif
    end
endmodule
