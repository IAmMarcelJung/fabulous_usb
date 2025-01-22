`timescale 1ps / 1ps
module bsr_cell (  // BC_1 with resetn and enable
    input  resetn,
    enableIn,
    enableOut,
    mode,
    clkDR,
    shiftDR,
    updateDR,
    data_pin,
    prevCell,
    output nextCell,
    data_pout
);

    wire s1;
    reg  s2;
    reg  s3;

    initial begin
        s2 = 1'b0;
        s3 = 1'b0;
    end

    assign nextCell = (resetn == 1'b1) ? s2 : 1'b0;

    // select input for shift register stage
    assign s1 = (shiftDR == 1'b0 & enableIn == 1'b1) ? data_pin : prevCell;

    // select input for parallel output
    assign data_pout = (mode == 1'b0 & enableOut == 1'b1) ?
        data_pin : (mode == 1'b1 & enableOut == 1'b1) ? s3 : 1'b0;

    always @(negedge resetn, negedge clkDR) begin
        if (resetn == 1'b0) s2 <= 1'b0;
        else s2 <= s1;
    end

    always @(negedge resetn, posedge updateDR) begin
        if (resetn == 1'b0) s3 <= 1'b0;
        else s3 <= s2;
    end
endmodule
