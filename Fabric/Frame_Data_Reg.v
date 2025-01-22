`timescale 1ps / 1ps
module Frame_Data_Reg (
    FrameData_I,
    FrameData_O,
    RowSelect,
    CLK
);
    parameter FRAME_BITS_PER_ROW = 32;
    parameter ROW_SELECT_WIDTH = 5;
    parameter ROW = 1;
    input [FRAME_BITS_PER_ROW-1:0] FrameData_I;
    output reg [FRAME_BITS_PER_ROW-1:0] FrameData_O;
    input [ROW_SELECT_WIDTH-1:0] RowSelect;
    input CLK;

    always @(posedge CLK) begin
        if (RowSelect == ROW) FrameData_O <= FrameData_I;
    end  //CLK
endmodule
