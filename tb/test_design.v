module test_design (
    input  wire       clk,
    input  wire [7:0] io_in,
    output wire [7:0] io_out,
    io_oeb
);
    wire        rst = io_in[0];
    reg  [15:0] ctr;

    always @(posedge clk) begin
        if (rst) ctr <= 16'd0;
        else ctr <= ctr + 1'b1;
    end

    assign io_out = {ctr[4], io_in[2], io_in[1], rst, 4'bxxxx};
    assign io_oeb = 8'b00001111;
endmodule
