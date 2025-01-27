`timescale 1ps / 1ps
// verilator lint_off DECLFILENAME
// verilator lint_off UNOPTFLAT
module clk_buf (
    input  A,
    output X
);
    assign X = A;
endmodule

module break_comb_loop (
               input  A,
    (* keep *) output X
);
    assign X = A;
endmodule

// verilator lint_on DECLFILENAME
// verilator lint_on UNOPTFLAT
