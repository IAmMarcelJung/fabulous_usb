module prim_clock_inv #(
    parameter HasScanMode = 1'b0,  // Enables scan mode logic
    parameter NoFpgaBufG  = 1'b0   // Disables BUFG if set
) (
    input  wire clk_i,      // Input clock
    output wire clk_no,     // Inverted clock output
    input  wire scanmode_i  // Scan mode signal
);

    wire clk_inv;

    assign clk_inv = scanmode_i ? clk_i : ~clk_i;  // Bypass inversion in scan mode

    generate
        if (NoFpgaBufG) begin : g_no_buf
            // Direct assignment without global clock buffer (not recommended)
            assign clk_no = clk_inv;
        end else begin : g_buf
            // Use BUFG to ensure correct FPGA clock routing
            BUFG bufg_inst (
                .I(clk_inv),
                .O(clk_no)
            );
        end
    endgenerate
endmodule
