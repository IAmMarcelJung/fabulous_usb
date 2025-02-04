`timescale 1ps / 1ps
module Frame_Select (
    FrameStrobe_I,
    FrameStrobe_O,
    FrameSelect,
    FrameStrobe
);
    parameter MAX_FRAMES_PER_COL = 20;
    parameter FRAME_SELECT_WIDTH = 5;
    parameter COL = 18;
    input [MAX_FRAMES_PER_COL-1:0] FrameStrobe_I;
    output reg [MAX_FRAMES_PER_COL-1:0] FrameStrobe_O;
    input [FRAME_SELECT_WIDTH-1:0] FrameSelect;
    input FrameStrobe;

    //FrameStrobe_O = 0;
    always @(*) begin
        if (FrameStrobe && (FrameSelect == COL)) FrameStrobe_O = FrameStrobe_I;
        else FrameStrobe_O = 'd0;
    end
endmodule
