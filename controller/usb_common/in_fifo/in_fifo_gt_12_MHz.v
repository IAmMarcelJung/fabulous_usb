`timescale 1ps / 1ps

module in_fifo_gt_12_MHz #(
    parameter IN_MAX_PACKET_SIZE = 'd8
) (
    input                                          clk_i,
    input                                          reset_n_i,
    input                                          app_clk_i,
    input                                          app_reset_n_i,
    input                                          clk_gate_i,
    input                                          in_full_i,
    input                                          in_ready_i,
    input  [                                  7:0] app_in_data_i,
    input                                          app_in_valid_i,
    output                                         app_in_ready_o,
    output [             8*IN_MAX_PACKET_SIZE-1:0] in_fifo_o,
    output [ceil_log2(IN_MAX_PACKET_SIZE + 1)-1:0] in_last_q_o,
    output [ceil_log2(IN_MAX_PACKET_SIZE + 1)-1:0] in_last_qq_o,
    output                                         app_in_buffer_empty_o
);
    function integer ceil_log2;
        input [31:0] arg;
        integer i;
        begin
            ceil_log2 = 0;
            for (i = 0; i < 32; i = i + 1) begin
                if (arg > (1 << i)) ceil_log2 = ceil_log2 + 1;
            end
        end
    endfunction
    localparam IN_LENGTH = IN_MAX_PACKET_SIZE +
        'd1;  // the contents of the last addressed byte is meaningless

    reg [ceil_log2(IN_LENGTH)-1:0] in_last_q, in_last_qq;
    reg [8*IN_LENGTH-1:0] in_fifo_q;
    reg [            1:0] app_in_valid_sq;
    reg [            7:0] app_in_data_q;
    reg app_in_valid_q, app_in_valid_qq;
    reg app_in_ready_q;

    assign app_in_buffer_empty_o = ~app_in_valid_qq;
    assign in_last_q_o           = in_last_q;
    assign in_last_qq_o          = in_last_qq;
    assign in_fifo_o             = in_fifo_q;

    always @(posedge clk_i or negedge reset_n_i) begin
        if (~reset_n_i) begin
            in_fifo_q       <= {IN_LENGTH{8'd0}};
            in_last_q       <= 'd0;
            app_in_valid_sq <= 2'd0;
            app_in_valid_qq <= 1'b0;
            app_in_ready_q  <= 1'b0;
        end else begin
            app_in_valid_sq <= {app_in_valid_q, app_in_valid_sq[1]};
            if (~app_in_valid_sq[0]) app_in_ready_q <= 1'b1;
            if (clk_gate_i) begin
                in_fifo_q[{in_last_q, 3'd0}+:8] <= app_in_data_q;
                app_in_valid_qq                 <= app_in_valid_sq[0] & app_in_ready_q;
                if (~in_full_i & app_in_valid_qq) begin
                    app_in_valid_qq <= 1'b0;
                    app_in_ready_q  <= 1'b0;
                    if (in_last_q == IN_LENGTH - 1) begin
                        in_last_q <= 'd0;
                        if (in_ready_i) in_last_qq <= 'd0;
                    end else begin
                        in_last_q <= in_last_q + 1;
                        if (in_ready_i) in_last_qq <= in_last_q + 1;
                    end
                end else begin
                    if (in_ready_i) in_last_qq <= in_last_q;
                end
            end
        end
    end

    reg [1:0] app_in_ready_sq;

    assign app_in_ready_o = app_in_ready_sq[0] & ~app_in_valid_q;

    always @(posedge app_clk_i or negedge app_reset_n_i) begin
        if (~app_reset_n_i) begin
            app_in_data_q   <= 8'd0;
            app_in_valid_q  <= 1'b0;
            app_in_ready_sq <= 2'b00;
        end else begin
            app_in_ready_sq <= {app_in_ready_q, app_in_ready_sq[1]};
            if (~app_in_ready_sq[0]) app_in_valid_q <= 1'b0;
            else if (app_in_valid_i & ~app_in_valid_q) begin
                app_in_data_q  <= app_in_data_i;
                app_in_valid_q <= 1'b1;
            end
        end
    end
endmodule
