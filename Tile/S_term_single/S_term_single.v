`timescale 1ps / 1ps
// verilator lint_off ASCRANGE
// verilator lint_off UNOPTFLAT
module S_term_single #(
`ifdef EMULATION
    parameter [639:0] Emulate_Bitstream = 640'b0,
`endif
    parameter         MaxFramesPerCol   = 20
) (
    //Side.NORTH
    output [3:0]
        N1BEG,  //Port(Name=N1BEG, IO=OUTPUT, XOffset=0, YOffset=-1, WireCount=4, Side=NORTH)
    output [7:0]
        N2BEG,  //Port(Name=N2BEG, IO=OUTPUT, XOffset=0, YOffset=-1, WireCount=8, Side=NORTH)
    output [7:0]
        N2BEGb,  //Port(Name=N2BEGb, IO=OUTPUT, XOffset=0, YOffset=-1, WireCount=8, Side=NORTH)
    output [15:0]
        N4BEG,  //Port(Name=N4BEG, IO=OUTPUT, XOffset=0, YOffset=-4, WireCount=4, Side=NORTH)
    output [15:0]
        NN4BEG,  //Port(Name=NN4BEG, IO=OUTPUT, XOffset=0, YOffset=-4, WireCount=4, Side=NORTH)
    output [0:0] Co,  //Port(Name=Co, IO=OUTPUT, XOffset=0, YOffset=-1, WireCount=1, Side=NORTH)
    input [3:0] S1END,  //Port(Name=S1END, IO=INPUT, XOffset=0, YOffset=1, WireCount=4, Side=NORTH)
    input [7:0] S2MID,  //Port(Name=S2MID, IO=INPUT, XOffset=0, YOffset=1, WireCount=8, Side=NORTH)
    input [7:0] S2END,  //Port(Name=S2END, IO=INPUT, XOffset=0, YOffset=1, WireCount=8, Side=NORTH)
    input [15:0] S4END,  //Port(Name=S4END, IO=INPUT, XOffset=0, YOffset=4, WireCount=4, Side=NORTH)
    input [15:0]
        SS4END,  //Port(Name=SS4END, IO=INPUT, XOffset=0, YOffset=4, WireCount=4, Side=NORTH)
    //Tile IO ports from BELs
    input UserCLK,
    output UserCLKo,
    input [MaxFramesPerCol -1:0] FrameStrobe,
    output [MaxFramesPerCol -1:0] FrameStrobe_O
    //global
);
    //signal declarations
    //BEL ports (e.g., slices)
    //Jump wires
    //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)

    //Connection for outgoing wires
    wire [MaxFramesPerCol-1:0] FrameStrobe_i;
    wire [MaxFramesPerCol-1:0] FrameStrobe_O_i;

    assign FrameStrobe_O_i = FrameStrobe_i;

    my_buf strobe_inbuf_0 (
        .A(FrameStrobe[0]),
        .X(FrameStrobe_i[0])
    );

    my_buf strobe_inbuf_1 (
        .A(FrameStrobe[1]),
        .X(FrameStrobe_i[1])
    );

    my_buf strobe_inbuf_2 (
        .A(FrameStrobe[2]),
        .X(FrameStrobe_i[2])
    );

    my_buf strobe_inbuf_3 (
        .A(FrameStrobe[3]),
        .X(FrameStrobe_i[3])
    );

    my_buf strobe_inbuf_4 (
        .A(FrameStrobe[4]),
        .X(FrameStrobe_i[4])
    );

    my_buf strobe_inbuf_5 (
        .A(FrameStrobe[5]),
        .X(FrameStrobe_i[5])
    );

    my_buf strobe_inbuf_6 (
        .A(FrameStrobe[6]),
        .X(FrameStrobe_i[6])
    );

    my_buf strobe_inbuf_7 (
        .A(FrameStrobe[7]),
        .X(FrameStrobe_i[7])
    );

    my_buf strobe_inbuf_8 (
        .A(FrameStrobe[8]),
        .X(FrameStrobe_i[8])
    );

    my_buf strobe_inbuf_9 (
        .A(FrameStrobe[9]),
        .X(FrameStrobe_i[9])
    );

    my_buf strobe_inbuf_10 (
        .A(FrameStrobe[10]),
        .X(FrameStrobe_i[10])
    );

    my_buf strobe_inbuf_11 (
        .A(FrameStrobe[11]),
        .X(FrameStrobe_i[11])
    );

    my_buf strobe_inbuf_12 (
        .A(FrameStrobe[12]),
        .X(FrameStrobe_i[12])
    );

    my_buf strobe_inbuf_13 (
        .A(FrameStrobe[13]),
        .X(FrameStrobe_i[13])
    );

    my_buf strobe_inbuf_14 (
        .A(FrameStrobe[14]),
        .X(FrameStrobe_i[14])
    );

    my_buf strobe_inbuf_15 (
        .A(FrameStrobe[15]),
        .X(FrameStrobe_i[15])
    );

    my_buf strobe_inbuf_16 (
        .A(FrameStrobe[16]),
        .X(FrameStrobe_i[16])
    );

    my_buf strobe_inbuf_17 (
        .A(FrameStrobe[17]),
        .X(FrameStrobe_i[17])
    );

    my_buf strobe_inbuf_18 (
        .A(FrameStrobe[18]),
        .X(FrameStrobe_i[18])
    );

    my_buf strobe_inbuf_19 (
        .A(FrameStrobe[19]),
        .X(FrameStrobe_i[19])
    );

    my_buf strobe_outbuf_0 (
        .A(FrameStrobe_O_i[0]),
        .X(FrameStrobe_O[0])
    );

    my_buf strobe_outbuf_1 (
        .A(FrameStrobe_O_i[1]),
        .X(FrameStrobe_O[1])
    );

    my_buf strobe_outbuf_2 (
        .A(FrameStrobe_O_i[2]),
        .X(FrameStrobe_O[2])
    );

    my_buf strobe_outbuf_3 (
        .A(FrameStrobe_O_i[3]),
        .X(FrameStrobe_O[3])
    );

    my_buf strobe_outbuf_4 (
        .A(FrameStrobe_O_i[4]),
        .X(FrameStrobe_O[4])
    );

    my_buf strobe_outbuf_5 (
        .A(FrameStrobe_O_i[5]),
        .X(FrameStrobe_O[5])
    );

    my_buf strobe_outbuf_6 (
        .A(FrameStrobe_O_i[6]),
        .X(FrameStrobe_O[6])
    );

    my_buf strobe_outbuf_7 (
        .A(FrameStrobe_O_i[7]),
        .X(FrameStrobe_O[7])
    );

    my_buf strobe_outbuf_8 (
        .A(FrameStrobe_O_i[8]),
        .X(FrameStrobe_O[8])
    );

    my_buf strobe_outbuf_9 (
        .A(FrameStrobe_O_i[9]),
        .X(FrameStrobe_O[9])
    );

    my_buf strobe_outbuf_10 (
        .A(FrameStrobe_O_i[10]),
        .X(FrameStrobe_O[10])
    );

    my_buf strobe_outbuf_11 (
        .A(FrameStrobe_O_i[11]),
        .X(FrameStrobe_O[11])
    );

    my_buf strobe_outbuf_12 (
        .A(FrameStrobe_O_i[12]),
        .X(FrameStrobe_O[12])
    );

    my_buf strobe_outbuf_13 (
        .A(FrameStrobe_O_i[13]),
        .X(FrameStrobe_O[13])
    );

    my_buf strobe_outbuf_14 (
        .A(FrameStrobe_O_i[14]),
        .X(FrameStrobe_O[14])
    );

    my_buf strobe_outbuf_15 (
        .A(FrameStrobe_O_i[15]),
        .X(FrameStrobe_O[15])
    );

    my_buf strobe_outbuf_16 (
        .A(FrameStrobe_O_i[16]),
        .X(FrameStrobe_O[16])
    );

    my_buf strobe_outbuf_17 (
        .A(FrameStrobe_O_i[17]),
        .X(FrameStrobe_O[17])
    );

    my_buf strobe_outbuf_18 (
        .A(FrameStrobe_O_i[18]),
        .X(FrameStrobe_O[18])
    );

    my_buf strobe_outbuf_19 (
        .A(FrameStrobe_O_i[19]),
        .X(FrameStrobe_O[19])
    );

    clk_buf inst_clk_buf (
        .A(UserCLK),
        .X(UserCLKo)
    );


    //BEL component instantiations
    S_term_single_switch_matrix Inst_S_term_single_switch_matrix (
        .S1END0  (S1END[0]),
        .S1END1  (S1END[1]),
        .S1END2  (S1END[2]),
        .S1END3  (S1END[3]),
        .S2MID0  (S2MID[0]),
        .S2MID1  (S2MID[1]),
        .S2MID2  (S2MID[2]),
        .S2MID3  (S2MID[3]),
        .S2MID4  (S2MID[4]),
        .S2MID5  (S2MID[5]),
        .S2MID6  (S2MID[6]),
        .S2MID7  (S2MID[7]),
        .S2END0  (S2END[0]),
        .S2END1  (S2END[1]),
        .S2END2  (S2END[2]),
        .S2END3  (S2END[3]),
        .S2END4  (S2END[4]),
        .S2END5  (S2END[5]),
        .S2END6  (S2END[6]),
        .S2END7  (S2END[7]),
        .S4END0  (S4END[0]),
        .S4END1  (S4END[1]),
        .S4END2  (S4END[2]),
        .S4END3  (S4END[3]),
        .S4END4  (S4END[4]),
        .S4END5  (S4END[5]),
        .S4END6  (S4END[6]),
        .S4END7  (S4END[7]),
        .S4END8  (S4END[8]),
        .S4END9  (S4END[9]),
        .S4END10 (S4END[10]),
        .S4END11 (S4END[11]),
        .S4END12 (S4END[12]),
        .S4END13 (S4END[13]),
        .S4END14 (S4END[14]),
        .S4END15 (S4END[15]),
        .SS4END0 (SS4END[0]),
        .SS4END1 (SS4END[1]),
        .SS4END2 (SS4END[2]),
        .SS4END3 (SS4END[3]),
        .SS4END4 (SS4END[4]),
        .SS4END5 (SS4END[5]),
        .SS4END6 (SS4END[6]),
        .SS4END7 (SS4END[7]),
        .SS4END8 (SS4END[8]),
        .SS4END9 (SS4END[9]),
        .SS4END10(SS4END[10]),
        .SS4END11(SS4END[11]),
        .SS4END12(SS4END[12]),
        .SS4END13(SS4END[13]),
        .SS4END14(SS4END[14]),
        .SS4END15(SS4END[15]),
        .N1BEG0  (N1BEG[0]),
        .N1BEG1  (N1BEG[1]),
        .N1BEG2  (N1BEG[2]),
        .N1BEG3  (N1BEG[3]),
        .N2BEG0  (N2BEG[0]),
        .N2BEG1  (N2BEG[1]),
        .N2BEG2  (N2BEG[2]),
        .N2BEG3  (N2BEG[3]),
        .N2BEG4  (N2BEG[4]),
        .N2BEG5  (N2BEG[5]),
        .N2BEG6  (N2BEG[6]),
        .N2BEG7  (N2BEG[7]),
        .N2BEGb0 (N2BEGb[0]),
        .N2BEGb1 (N2BEGb[1]),
        .N2BEGb2 (N2BEGb[2]),
        .N2BEGb3 (N2BEGb[3]),
        .N2BEGb4 (N2BEGb[4]),
        .N2BEGb5 (N2BEGb[5]),
        .N2BEGb6 (N2BEGb[6]),
        .N2BEGb7 (N2BEGb[7]),
        .N4BEG0  (N4BEG[0]),
        .N4BEG1  (N4BEG[1]),
        .N4BEG2  (N4BEG[2]),
        .N4BEG3  (N4BEG[3]),
        .N4BEG4  (N4BEG[4]),
        .N4BEG5  (N4BEG[5]),
        .N4BEG6  (N4BEG[6]),
        .N4BEG7  (N4BEG[7]),
        .N4BEG8  (N4BEG[8]),
        .N4BEG9  (N4BEG[9]),
        .N4BEG10 (N4BEG[10]),
        .N4BEG11 (N4BEG[11]),
        .N4BEG12 (N4BEG[12]),
        .N4BEG13 (N4BEG[13]),
        .N4BEG14 (N4BEG[14]),
        .N4BEG15 (N4BEG[15]),
        .NN4BEG0 (NN4BEG[0]),
        .NN4BEG1 (NN4BEG[1]),
        .NN4BEG2 (NN4BEG[2]),
        .NN4BEG3 (NN4BEG[3]),
        .NN4BEG4 (NN4BEG[4]),
        .NN4BEG5 (NN4BEG[5]),
        .NN4BEG6 (NN4BEG[6]),
        .NN4BEG7 (NN4BEG[7]),
        .NN4BEG8 (NN4BEG[8]),
        .NN4BEG9 (NN4BEG[9]),
        .NN4BEG10(NN4BEG[10]),
        .NN4BEG11(NN4BEG[11]),
        .NN4BEG12(NN4BEG[12]),
        .NN4BEG13(NN4BEG[13]),
        .NN4BEG14(NN4BEG[14]),
        .NN4BEG15(NN4BEG[15]),
        .Co0     (Co[0])
    );

endmodule
// verilator lint_on ASCRANGE
// verilator lint_on UNOPTFLAT
