`timescale 1ps / 1ps

module config_usb_cdc_tb;

    reg         clk_system;
    wire        reset_n;
    wire [ 7:0] in_data;
    wire        in_valid;
    reg         in_ready;
    wire [ 7:0] out_data;
    wire        out_valid;
    wire        out_ready;
    wire        word_write_strobe;
    wire [31:0] write_data;

    localparam MAX_BITBYTES = 16384;
    localparam PREAMBLE_SIZE = 16;
    // Instantiate the DUT
    config_usb_cdc dut (
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

    // Instantiate the module containing utility used in the testbench
    tb_utils #(
        .MAX_BITBYTES(MAX_BITBYTES)
    ) tb_utils_inst (
        .clk_i              (clk_system),
        .reset_n_o          (reset_n),
        .out_data_o         (out_data),
        .out_valid_o        (out_valid),
        .out_ready          (out_ready),
        .write_data_i       (write_data),
        .word_write_strobe_i(word_write_strobe)
    );

    // Clock Generation: 100 MHz clock (10 ns period)
    initial begin
        clk_system = 1'b0;
        forever #5000 clk_system = ~clk_system;
    end

    initial begin
        tb_utils_inst.monitor_write_data();
    end

    initial begin
`ifdef TOP_MODULE
        $dumpfile(`DUMP_FILE);
        $dumpvars(0, `TOP_MODULE);
`endif
        in_ready = 1'b0;  // Signal is not used, just set to zero
        tb_utils_inst.dump_arrays();

        tb_utils_inst.load_bitstream("./build/counter.hex");

        tb_utils_inst.simulate_usb_bitstream_output(0);
        tb_utils_inst.simulate_usb_bitstream_output(1);
        tb_utils_inst.simulate_usb_bitstream_output(5);

        // Wait another clock cycle
        #10000;
        $display("SUCCESS: Simulation finished!");
        $finish;
    end
endmodule

