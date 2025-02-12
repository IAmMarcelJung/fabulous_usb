`timescale 1ps / 1ps
module in_fifo_lte_12_MHz #(
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
    reg [            2:0] app_clk_sq;  // BIT_SAMPLES >= 4
    reg [           15:0] app_in_data_q;
    reg [1:0] app_in_valid_q, app_in_valid_qq, app_in_valid_qqq;
    reg app_in_first_q, app_in_first_qq, app_in_first_qqq;
    reg [1:0] app_in_consumed_q, app_in_consumed_qq;
    reg app_in_ready_q;

    assign app_in_ready_o        = app_in_ready_q;
    assign app_in_buffer_empty_o = ~|app_in_valid_qqq;
    assign in_last_q_o           = in_last_q;
    assign in_last_qq_o          = in_last_qq;
    assign in_fifo_o             = in_fifo_q;

    always @(posedge clk_i or negedge reset_n_i) begin
        if (~reset_n_i) begin
            in_fifo_q          <= {IN_LENGTH{8'd0}};
            in_last_q          <= 'd0;
            in_last_qq         <= 'd0;
            app_clk_sq         <= 3'b000;
            app_in_valid_qq    <= 2'b00;
            app_in_valid_qqq   <= 2'b00;
            app_in_first_qq    <= 1'b0;
            app_in_first_qqq   <= 1'b0;
            app_in_consumed_q  <= 2'b00;
            app_in_consumed_qq <= 2'b00;
            app_in_ready_q     <= 1'b0;
        end else begin
            app_clk_sq <= {app_clk_i, app_clk_sq[2:1]};
            if (app_clk_sq[1:0] == 2'b10) begin
                app_in_ready_q     <= |(~(app_in_valid_q & ~app_in_consumed_q));
                app_in_consumed_q  <= 2'b00;
                app_in_consumed_qq <= app_in_consumed_q;
                app_in_valid_qq    <= app_in_valid_q & ~app_in_consumed_q;
                if (^app_in_consumed_q) app_in_first_qq <= app_in_consumed_q[0];
                else app_in_first_qq <= app_in_first_q;
            end
            if (clk_gate_i) begin
                if (app_in_first_qqq == 1'b0) in_fifo_q[{in_last_q, 3'd0}+:8] <= app_in_data_q[7:0];
                else in_fifo_q[{in_last_q, 3'd0}+:8] <= app_in_data_q[15:8];
                app_in_valid_qqq <= app_in_valid_qq;
                app_in_first_qqq <= app_in_first_qq;
                if (app_clk_sq[1:0] == 2'b10) begin
                    app_in_valid_qqq <= app_in_valid_q & ~app_in_consumed_q;
                    if (^app_in_consumed_q) app_in_first_qqq <= app_in_consumed_q[0];
                    else app_in_first_qqq <= app_in_first_q;
                end
                if (~in_full_i & |app_in_valid_qqq) begin
                    if (app_in_first_qqq == 1'b0) begin
                        app_in_valid_qq[0]   <= 1'b0;
                        app_in_valid_qqq[0]  <= 1'b0;
                        app_in_first_qq      <= 1'b1;
                        app_in_first_qqq     <= 1'b1;
                        app_in_consumed_q[0] <= 1'b1;
                    end else begin
                        app_in_valid_qq[1]   <= 1'b0;
                        app_in_valid_qqq[1]  <= 1'b0;
                        app_in_first_qq      <= 1'b0;
                        app_in_first_qqq     <= 1'b0;
                        app_in_consumed_q[1] <= 1'b1;
                    end
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

    always @(posedge app_clk_i or negedge app_reset_n_i) begin
        if (~app_reset_n_i) begin
            app_in_data_q  <= 16'd0;
            app_in_valid_q <= 2'b00;
            app_in_first_q <= 1'b0;
        end else begin
            app_in_valid_q <= app_in_valid_q & ~app_in_consumed_qq;
            if (^app_in_consumed_qq) app_in_first_q <= app_in_consumed_qq[0];
            if (app_in_valid_i & app_in_ready_q) begin
                if (~(app_in_valid_q[0] & ~app_in_consumed_qq[0])) begin
                    app_in_data_q[7:0] <= app_in_data_i;
                    app_in_valid_q[0]  <= 1'b1;
                    app_in_first_q     <= app_in_valid_q[1] & ~app_in_consumed_qq[1];
                end else if (~(app_in_valid_q[1] & ~app_in_consumed_qq[1])) begin
                    app_in_data_q[15:8] <= app_in_data_i;
                    app_in_valid_q[1]   <= 1'b1;
                    app_in_first_q      <= ~(app_in_valid_q[0] & ~app_in_consumed_qq[0]);
                end
            end
        end
    end

endmodule
