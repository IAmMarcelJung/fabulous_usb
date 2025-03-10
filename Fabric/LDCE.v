// Yosys techmap: Replace LDCE latches with FDCE flip-flops
module LDCE (
    input  D,
    input  E,
    output Q
);
    wire clk_48_MHz;
    (* keep *) FDCE _TECHMAP_REPLACE_ (
        .D  (D),
        .C  (clk_48_MHz),
        .CE (E),
        .CLR(1'b0),
        .Q  (Q)
    );
endmodule
