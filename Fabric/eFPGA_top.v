`timescale 1ns / 1ps
module eFPGA_top #(
    parameter NUMBER_OF_ROWS     = 4,
    parameter NumberOfCols       = 5,
    parameter FRAME_BITS_PER_ROW = 32,
    parameter MaxFramesPerCol    = 20,
    parameter DESYNC_FLAG        = 20,
    parameter FrameSelectWidth   = 5,
    parameter ROW_SELECT_WIDTH   = 5,
    parameter NumUsedIOs         = 8,
    parameter NUM_OF_ANODES      = 4

) (
    //External IO port
    inout [NumUsedIOs-1:0] user_io,

    //Config related ports
    input  CLK,
    input  reset,
    input  Rx,
    output ReceiveLED,

    // JTAG port
    input  tms,
    input  tdi,
    output tdo,
    input  tck,

    output [NUM_OF_ANODES-1:0] an  // 7 segment anodes
);
    //BlockRAM ports

    wire [                                     64-1:0] RAM2FAB_D_I;
    wire [                                     64-1:0] FAB2RAM_D_O;
    wire [                                     32-1:0] FAB2RAM_A_O;
    // verilator lint_off UNUSEDSIGNAL
    // Parts of the signal are unused
    wire [                                     16-1:0] FAB2RAM_C_O;
    // verilator lint_off UNUSEDSIGNAL

    //Signal declarations
    wire [    (NUMBER_OF_ROWS*FRAME_BITS_PER_ROW)-1:0] FrameRegister;
    wire [         (MaxFramesPerCol*NumberOfCols)-1:0] FrameSelect;
    wire [(FRAME_BITS_PER_ROW*(NUMBER_OF_ROWS+2))-1:0] FrameData;
    // verilator lint_off UNUSEDSIGNAL
    // Parts of the signal are unused
    wire [                     FRAME_BITS_PER_ROW-1:0] FrameAddressRegister;
    // verilator lint_off UNUSEDSIGNAL
    wire                                               LongFrameStrobe;
    wire [                                       31:0] LocalWriteData;
    wire                                               LocalWriteStrobe;
    wire [                       ROW_SELECT_WIDTH-1:0] RowSelect;
    wire                                               resetn;

    //JTAG related signals
    wire [                             NumUsedIOs-1:0] I_out;
    wire [                             NumUsedIOs-1:0] O_in;
    wire [                                       31:0] JTAGWriteData;
    wire                                               JTAGWriteStrobe;
    wire                                               JTAGActive;

    wire [                             NumUsedIOs-1:0] I_top;
    wire [                             NumUsedIOs-1:0] O_top;
    wire [                             NumUsedIOs-1:0] T_top;

    assign resetn = !reset;

    genvar i;
    generate
        for (i = 0; i < NumUsedIOs; i = i + 1) begin : g_tristate_outputs
            assign user_io[i] = T_top[i] ? I_top[i] : 1'bz;
        end
    endgenerate

    // turn off 7 segment displancly
    assign O_top[NumUsedIOs-1:0] = user_io[NumUsedIOs-1:0];

    assign an                    = {NUM_OF_ANODES{1'b1}};

    tap #(
        .BS_REG_IN_LEN (NumUsedIOs),
        .BS_REG_OUT_LEN(NumUsedIOs)
    ) Inst_jtag (
        .tck           (tck),
        .tms           (tms),
        .tdi           (tdi),
        .tdo           (tdo),
        .trst          (resetn),
        // verilator lint_off PINCONNECTEMPTY
        // TODO: connect the correct signals
        .pins_in       (),
        .pins_out      (),
        .logic_pins_out(),
        .logic_pins_in (),
        // verilator lint_on PINCONNECTEMPTY
        .active        (JTAGActive),
        .config_data   (JTAGWriteData),
        .config_strobe (JTAGWriteStrobe)
    );

    eFPGA_Config #(
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .NUMBER_OF_ROWS    (NUMBER_OF_ROWS),
        .DESYNC_FLAG       (DESYNC_FLAG),
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW)
    ) eFPGA_Config_inst (
        .CLK                 (CLK),
        .resetn              (resetn),
        .Rx                  (Rx),
        .ReceiveLED          (ReceiveLED),
        // verilator lint_off PINCONNECTEMPTY
        .ComActive           (),
        .SelfWriteData       (),
        .SelfWriteStrobe     (),
        .ConfigWriteStrobe   (),
        // verilator lint_on PINCONNECTEMPTY
        .ConfigWriteData     (LocalWriteData),
        .FrameAddressRegister(FrameAddressRegister),
        .LongFrameStrobe     (LongFrameStrobe),
        .RowSelect           (RowSelect),
        .JTAGWriteData       (JTAGWriteData),
        .JTAGWriteStrobe     (JTAGWriteStrobe),
        .JTAGActive          (JTAGActive),
        .tck                 (tck)
    );


    Frame_Data_Reg #(
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .ROW               (1)
    ) inst_Frame_Data_Reg_0 (
        .FrameData_I(LocalWriteData),
        .FrameData_O(FrameRegister[0*FRAME_BITS_PER_ROW+FRAME_BITS_PER_ROW-1:0*FRAME_BITS_PER_ROW]),
        .RowSelect(RowSelect),
        .CLK(CLK)
    );

    Frame_Data_Reg #(
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .ROW               (2)
    ) inst_Frame_Data_Reg_1 (
        .FrameData_I(LocalWriteData),
        .FrameData_O(FrameRegister[1*FRAME_BITS_PER_ROW+FRAME_BITS_PER_ROW-1:1*FRAME_BITS_PER_ROW]),
        .RowSelect(RowSelect),
        .CLK(CLK)
    );

    Frame_Data_Reg #(
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .ROW               (3)
    ) inst_Frame_Data_Reg_2 (
        .FrameData_I(LocalWriteData),
        .FrameData_O(FrameRegister[2*FRAME_BITS_PER_ROW+FRAME_BITS_PER_ROW-1:2*FRAME_BITS_PER_ROW]),
        .RowSelect(RowSelect),
        .CLK(CLK)
    );

    Frame_Data_Reg #(
        .FRAME_BITS_PER_ROW(FRAME_BITS_PER_ROW),
        .ROW_SELECT_WIDTH  (ROW_SELECT_WIDTH),
        .ROW               (4)
    ) inst_Frame_Data_Reg_3 (
        .FrameData_I(LocalWriteData),
        .FrameData_O(FrameRegister[3*FRAME_BITS_PER_ROW+FRAME_BITS_PER_ROW-1:3*FRAME_BITS_PER_ROW]),
        .RowSelect(RowSelect),
        .CLK(CLK)
    );

    Frame_Select #(
        .MaxFramesPerCol (MaxFramesPerCol),
        .FrameSelectWidth(FrameSelectWidth),
        .Col             (0)
    ) inst_Frame_Select_0 (
        .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
        .FrameStrobe_O(FrameSelect[0*MaxFramesPerCol+MaxFramesPerCol-1:0*MaxFramesPerCol]),
        .FrameSelect(
            FrameAddressRegister[FRAME_BITS_PER_ROW-1:FRAME_BITS_PER_ROW-FrameSelectWidth]),
        .FrameStrobe(LongFrameStrobe)
    );

    Frame_Select #(
        .MaxFramesPerCol (MaxFramesPerCol),
        .FrameSelectWidth(FrameSelectWidth),
        .Col             (1)
    ) inst_Frame_Select_1 (
        .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
        .FrameStrobe_O(FrameSelect[1*MaxFramesPerCol+MaxFramesPerCol-1:1*MaxFramesPerCol]),
        .FrameSelect(
            FrameAddressRegister[FRAME_BITS_PER_ROW-1:FRAME_BITS_PER_ROW-FrameSelectWidth]),
        .FrameStrobe(LongFrameStrobe)
    );

    Frame_Select #(
        .MaxFramesPerCol (MaxFramesPerCol),
        .FrameSelectWidth(FrameSelectWidth),
        .Col             (2)
    ) inst_Frame_Select_2 (
        .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
        .FrameStrobe_O(FrameSelect[2*MaxFramesPerCol+MaxFramesPerCol-1:2*MaxFramesPerCol]),
        .FrameSelect(
            FrameAddressRegister[FRAME_BITS_PER_ROW-1:FRAME_BITS_PER_ROW-FrameSelectWidth]),
        .FrameStrobe(LongFrameStrobe)
    );

    Frame_Select #(
        .MaxFramesPerCol (MaxFramesPerCol),
        .FrameSelectWidth(FrameSelectWidth),
        .Col             (3)
    ) inst_Frame_Select_3 (
        .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
        .FrameStrobe_O(FrameSelect[3*MaxFramesPerCol+MaxFramesPerCol-1:3*MaxFramesPerCol]),
        .FrameSelect(
            FrameAddressRegister[FRAME_BITS_PER_ROW-1:FRAME_BITS_PER_ROW-FrameSelectWidth]),
        .FrameStrobe(LongFrameStrobe)
    );

    Frame_Select #(
        .MaxFramesPerCol (MaxFramesPerCol),
        .FrameSelectWidth(FrameSelectWidth),
        .Col             (4)
    ) inst_Frame_Select_4 (
        .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
        .FrameStrobe_O(FrameSelect[4*MaxFramesPerCol+MaxFramesPerCol-1:4*MaxFramesPerCol]),
        .FrameSelect(
            FrameAddressRegister[FRAME_BITS_PER_ROW-1:FRAME_BITS_PER_ROW-FrameSelectWidth]),
        .FrameStrobe(LongFrameStrobe)
    );


    eFPGA eFPGA_inst (
        // verilator lint_off PINCONNECTEMPTY
        .Tile_X0Y4_A_config_C_bit0    (),
        .Tile_X0Y4_A_config_C_bit1    (),
        .Tile_X0Y4_A_config_C_bit2    (),
        .Tile_X0Y4_A_config_C_bit3    (),
        .Tile_X0Y3_A_config_C_bit0    (),
        .Tile_X0Y3_A_config_C_bit1    (),
        .Tile_X0Y3_A_config_C_bit2    (),
        .Tile_X0Y3_A_config_C_bit3    (),
        .Tile_X0Y2_A_config_C_bit0    (),
        .Tile_X0Y2_A_config_C_bit1    (),
        .Tile_X0Y2_A_config_C_bit2    (),
        .Tile_X0Y2_A_config_C_bit3    (),
        .Tile_X0Y1_A_config_C_bit0    (),
        .Tile_X0Y1_A_config_C_bit1    (),
        .Tile_X0Y1_A_config_C_bit2    (),
        .Tile_X0Y1_A_config_C_bit3    (),
        .Tile_X0Y4_B_config_C_bit0    (),
        .Tile_X0Y4_B_config_C_bit1    (),
        .Tile_X0Y4_B_config_C_bit2    (),
        .Tile_X0Y4_B_config_C_bit3    (),
        .Tile_X0Y3_B_config_C_bit0    (),
        .Tile_X0Y3_B_config_C_bit1    (),
        .Tile_X0Y3_B_config_C_bit2    (),
        .Tile_X0Y3_B_config_C_bit3    (),
        .Tile_X0Y2_B_config_C_bit0    (),
        .Tile_X0Y2_B_config_C_bit1    (),
        .Tile_X0Y2_B_config_C_bit2    (),
        .Tile_X0Y2_B_config_C_bit3    (),
        .Tile_X0Y1_B_config_C_bit0    (),
        .Tile_X0Y1_B_config_C_bit1    (),
        .Tile_X0Y1_B_config_C_bit2    (),
        .Tile_X0Y1_B_config_C_bit3    (),
        .Tile_X4Y4_Config_accessC_bit0(),
        .Tile_X4Y4_Config_accessC_bit1(),
        .Tile_X4Y4_Config_accessC_bit2(),
        .Tile_X4Y4_Config_accessC_bit3(),
        .Tile_X4Y3_Config_accessC_bit0(),
        .Tile_X4Y3_Config_accessC_bit1(),
        .Tile_X4Y3_Config_accessC_bit2(),
        .Tile_X4Y3_Config_accessC_bit3(),
        .Tile_X4Y2_Config_accessC_bit0(),
        .Tile_X4Y2_Config_accessC_bit1(),
        .Tile_X4Y2_Config_accessC_bit2(),
        .Tile_X4Y2_Config_accessC_bit3(),
        .Tile_X4Y1_Config_accessC_bit0(),
        .Tile_X4Y1_Config_accessC_bit1(),
        .Tile_X4Y1_Config_accessC_bit2(),
        .Tile_X4Y1_Config_accessC_bit3(),
        // verilator lint_on PINCONNECTEMPTY
        .Tile_X4Y4_FAB2RAM_A0_O0      (FAB2RAM_A_O[0]),
        .Tile_X4Y4_FAB2RAM_A0_O1      (FAB2RAM_A_O[1]),
        .Tile_X4Y4_FAB2RAM_A0_O2      (FAB2RAM_A_O[2]),
        .Tile_X4Y4_FAB2RAM_A0_O3      (FAB2RAM_A_O[3]),
        .Tile_X4Y4_FAB2RAM_A1_O0      (FAB2RAM_A_O[4]),
        .Tile_X4Y4_FAB2RAM_A1_O1      (FAB2RAM_A_O[5]),
        .Tile_X4Y4_FAB2RAM_A1_O2      (FAB2RAM_A_O[6]),
        .Tile_X4Y4_FAB2RAM_A1_O3      (FAB2RAM_A_O[7]),
        .Tile_X4Y3_FAB2RAM_A0_O0      (FAB2RAM_A_O[8]),
        .Tile_X4Y3_FAB2RAM_A0_O1      (FAB2RAM_A_O[9]),
        .Tile_X4Y3_FAB2RAM_A0_O2      (FAB2RAM_A_O[10]),
        .Tile_X4Y3_FAB2RAM_A0_O3      (FAB2RAM_A_O[11]),
        .Tile_X4Y3_FAB2RAM_A1_O0      (FAB2RAM_A_O[12]),
        .Tile_X4Y3_FAB2RAM_A1_O1      (FAB2RAM_A_O[13]),
        .Tile_X4Y3_FAB2RAM_A1_O2      (FAB2RAM_A_O[14]),
        .Tile_X4Y3_FAB2RAM_A1_O3      (FAB2RAM_A_O[15]),
        .Tile_X4Y2_FAB2RAM_A0_O0      (FAB2RAM_A_O[16]),
        .Tile_X4Y2_FAB2RAM_A0_O1      (FAB2RAM_A_O[17]),
        .Tile_X4Y2_FAB2RAM_A0_O2      (FAB2RAM_A_O[18]),
        .Tile_X4Y2_FAB2RAM_A0_O3      (FAB2RAM_A_O[19]),
        .Tile_X4Y2_FAB2RAM_A1_O0      (FAB2RAM_A_O[20]),
        .Tile_X4Y2_FAB2RAM_A1_O1      (FAB2RAM_A_O[21]),
        .Tile_X4Y2_FAB2RAM_A1_O2      (FAB2RAM_A_O[22]),
        .Tile_X4Y2_FAB2RAM_A1_O3      (FAB2RAM_A_O[23]),
        .Tile_X4Y1_FAB2RAM_A0_O0      (FAB2RAM_A_O[24]),
        .Tile_X4Y1_FAB2RAM_A0_O1      (FAB2RAM_A_O[25]),
        .Tile_X4Y1_FAB2RAM_A0_O2      (FAB2RAM_A_O[26]),
        .Tile_X4Y1_FAB2RAM_A0_O3      (FAB2RAM_A_O[27]),
        .Tile_X4Y1_FAB2RAM_A1_O0      (FAB2RAM_A_O[28]),
        .Tile_X4Y1_FAB2RAM_A1_O1      (FAB2RAM_A_O[29]),
        .Tile_X4Y1_FAB2RAM_A1_O2      (FAB2RAM_A_O[30]),
        .Tile_X4Y1_FAB2RAM_A1_O3      (FAB2RAM_A_O[31]),
        .Tile_X4Y4_FAB2RAM_C_O0       (FAB2RAM_C_O[0]),
        .Tile_X4Y4_FAB2RAM_C_O1       (FAB2RAM_C_O[1]),
        .Tile_X4Y4_FAB2RAM_C_O2       (FAB2RAM_C_O[2]),
        .Tile_X4Y4_FAB2RAM_C_O3       (FAB2RAM_C_O[3]),
        .Tile_X4Y3_FAB2RAM_C_O0       (FAB2RAM_C_O[4]),
        .Tile_X4Y3_FAB2RAM_C_O1       (FAB2RAM_C_O[5]),
        .Tile_X4Y3_FAB2RAM_C_O2       (FAB2RAM_C_O[6]),
        .Tile_X4Y3_FAB2RAM_C_O3       (FAB2RAM_C_O[7]),
        .Tile_X4Y2_FAB2RAM_C_O0       (FAB2RAM_C_O[8]),
        .Tile_X4Y2_FAB2RAM_C_O1       (FAB2RAM_C_O[9]),
        .Tile_X4Y2_FAB2RAM_C_O2       (FAB2RAM_C_O[10]),
        .Tile_X4Y2_FAB2RAM_C_O3       (FAB2RAM_C_O[11]),
        .Tile_X4Y1_FAB2RAM_C_O0       (FAB2RAM_C_O[12]),
        .Tile_X4Y1_FAB2RAM_C_O1       (FAB2RAM_C_O[13]),
        .Tile_X4Y1_FAB2RAM_C_O2       (FAB2RAM_C_O[14]),
        .Tile_X4Y1_FAB2RAM_C_O3       (FAB2RAM_C_O[15]),
        .Tile_X4Y4_FAB2RAM_D0_O0      (FAB2RAM_D_O[0]),
        .Tile_X4Y4_FAB2RAM_D0_O1      (FAB2RAM_D_O[1]),
        .Tile_X4Y4_FAB2RAM_D0_O2      (FAB2RAM_D_O[2]),
        .Tile_X4Y4_FAB2RAM_D0_O3      (FAB2RAM_D_O[3]),
        .Tile_X4Y4_FAB2RAM_D1_O0      (FAB2RAM_D_O[4]),
        .Tile_X4Y4_FAB2RAM_D1_O1      (FAB2RAM_D_O[5]),
        .Tile_X4Y4_FAB2RAM_D1_O2      (FAB2RAM_D_O[6]),
        .Tile_X4Y4_FAB2RAM_D1_O3      (FAB2RAM_D_O[7]),
        .Tile_X4Y4_FAB2RAM_D2_O0      (FAB2RAM_D_O[8]),
        .Tile_X4Y4_FAB2RAM_D2_O1      (FAB2RAM_D_O[9]),
        .Tile_X4Y4_FAB2RAM_D2_O2      (FAB2RAM_D_O[10]),
        .Tile_X4Y4_FAB2RAM_D2_O3      (FAB2RAM_D_O[11]),
        .Tile_X4Y4_FAB2RAM_D3_O0      (FAB2RAM_D_O[12]),
        .Tile_X4Y4_FAB2RAM_D3_O1      (FAB2RAM_D_O[13]),
        .Tile_X4Y4_FAB2RAM_D3_O2      (FAB2RAM_D_O[14]),
        .Tile_X4Y4_FAB2RAM_D3_O3      (FAB2RAM_D_O[15]),
        .Tile_X4Y3_FAB2RAM_D0_O0      (FAB2RAM_D_O[16]),
        .Tile_X4Y3_FAB2RAM_D0_O1      (FAB2RAM_D_O[17]),
        .Tile_X4Y3_FAB2RAM_D0_O2      (FAB2RAM_D_O[18]),
        .Tile_X4Y3_FAB2RAM_D0_O3      (FAB2RAM_D_O[19]),
        .Tile_X4Y3_FAB2RAM_D1_O0      (FAB2RAM_D_O[20]),
        .Tile_X4Y3_FAB2RAM_D1_O1      (FAB2RAM_D_O[21]),
        .Tile_X4Y3_FAB2RAM_D1_O2      (FAB2RAM_D_O[22]),
        .Tile_X4Y3_FAB2RAM_D1_O3      (FAB2RAM_D_O[23]),
        .Tile_X4Y3_FAB2RAM_D2_O0      (FAB2RAM_D_O[24]),
        .Tile_X4Y3_FAB2RAM_D2_O1      (FAB2RAM_D_O[25]),
        .Tile_X4Y3_FAB2RAM_D2_O2      (FAB2RAM_D_O[26]),
        .Tile_X4Y3_FAB2RAM_D2_O3      (FAB2RAM_D_O[27]),
        .Tile_X4Y3_FAB2RAM_D3_O0      (FAB2RAM_D_O[28]),
        .Tile_X4Y3_FAB2RAM_D3_O1      (FAB2RAM_D_O[29]),
        .Tile_X4Y3_FAB2RAM_D3_O2      (FAB2RAM_D_O[30]),
        .Tile_X4Y3_FAB2RAM_D3_O3      (FAB2RAM_D_O[31]),
        .Tile_X4Y2_FAB2RAM_D0_O0      (FAB2RAM_D_O[32]),
        .Tile_X4Y2_FAB2RAM_D0_O1      (FAB2RAM_D_O[33]),
        .Tile_X4Y2_FAB2RAM_D0_O2      (FAB2RAM_D_O[34]),
        .Tile_X4Y2_FAB2RAM_D0_O3      (FAB2RAM_D_O[35]),
        .Tile_X4Y2_FAB2RAM_D1_O0      (FAB2RAM_D_O[36]),
        .Tile_X4Y2_FAB2RAM_D1_O1      (FAB2RAM_D_O[37]),
        .Tile_X4Y2_FAB2RAM_D1_O2      (FAB2RAM_D_O[38]),
        .Tile_X4Y2_FAB2RAM_D1_O3      (FAB2RAM_D_O[39]),
        .Tile_X4Y2_FAB2RAM_D2_O0      (FAB2RAM_D_O[40]),
        .Tile_X4Y2_FAB2RAM_D2_O1      (FAB2RAM_D_O[41]),
        .Tile_X4Y2_FAB2RAM_D2_O2      (FAB2RAM_D_O[42]),
        .Tile_X4Y2_FAB2RAM_D2_O3      (FAB2RAM_D_O[43]),
        .Tile_X4Y2_FAB2RAM_D3_O0      (FAB2RAM_D_O[44]),
        .Tile_X4Y2_FAB2RAM_D3_O1      (FAB2RAM_D_O[45]),
        .Tile_X4Y2_FAB2RAM_D3_O2      (FAB2RAM_D_O[46]),
        .Tile_X4Y2_FAB2RAM_D3_O3      (FAB2RAM_D_O[47]),
        .Tile_X4Y1_FAB2RAM_D0_O0      (FAB2RAM_D_O[48]),
        .Tile_X4Y1_FAB2RAM_D0_O1      (FAB2RAM_D_O[49]),
        .Tile_X4Y1_FAB2RAM_D0_O2      (FAB2RAM_D_O[50]),
        .Tile_X4Y1_FAB2RAM_D0_O3      (FAB2RAM_D_O[51]),
        .Tile_X4Y1_FAB2RAM_D1_O0      (FAB2RAM_D_O[52]),
        .Tile_X4Y1_FAB2RAM_D1_O1      (FAB2RAM_D_O[53]),
        .Tile_X4Y1_FAB2RAM_D1_O2      (FAB2RAM_D_O[54]),
        .Tile_X4Y1_FAB2RAM_D1_O3      (FAB2RAM_D_O[55]),
        .Tile_X4Y1_FAB2RAM_D2_O0      (FAB2RAM_D_O[56]),
        .Tile_X4Y1_FAB2RAM_D2_O1      (FAB2RAM_D_O[57]),
        .Tile_X4Y1_FAB2RAM_D2_O2      (FAB2RAM_D_O[58]),
        .Tile_X4Y1_FAB2RAM_D2_O3      (FAB2RAM_D_O[59]),
        .Tile_X4Y1_FAB2RAM_D3_O0      (FAB2RAM_D_O[60]),
        .Tile_X4Y1_FAB2RAM_D3_O1      (FAB2RAM_D_O[61]),
        .Tile_X4Y1_FAB2RAM_D3_O2      (FAB2RAM_D_O[62]),
        .Tile_X4Y1_FAB2RAM_D3_O3      (FAB2RAM_D_O[63]),
        .Tile_X0Y4_B_I_top            (I_top[0]),
        .Tile_X0Y4_A_I_top            (I_top[1]),
        .Tile_X0Y3_B_I_top            (I_top[2]),
        .Tile_X0Y3_A_I_top            (I_top[3]),
        .Tile_X0Y2_B_I_top            (I_top[4]),
        .Tile_X0Y2_A_I_top            (I_top[5]),
        .Tile_X0Y1_B_I_top            (I_top[6]),
        .Tile_X0Y1_A_I_top            (I_top[7]),
        .Tile_X0Y4_B_O_top            (O_top[0]),
        .Tile_X0Y4_A_O_top            (O_top[1]),
        .Tile_X0Y3_B_O_top            (O_top[2]),
        .Tile_X0Y3_A_O_top            (O_top[3]),
        .Tile_X0Y2_B_O_top            (O_top[4]),
        .Tile_X0Y2_A_O_top            (O_top[5]),
        .Tile_X0Y1_B_O_top            (O_top[6]),
        .Tile_X0Y1_A_O_top            (O_top[7]),
        .Tile_X4Y4_RAM2FAB_D0_I0      (RAM2FAB_D_I[0]),
        .Tile_X4Y4_RAM2FAB_D0_I1      (RAM2FAB_D_I[1]),
        .Tile_X4Y4_RAM2FAB_D0_I2      (RAM2FAB_D_I[2]),
        .Tile_X4Y4_RAM2FAB_D0_I3      (RAM2FAB_D_I[3]),
        .Tile_X4Y4_RAM2FAB_D1_I0      (RAM2FAB_D_I[4]),
        .Tile_X4Y4_RAM2FAB_D1_I1      (RAM2FAB_D_I[5]),
        .Tile_X4Y4_RAM2FAB_D1_I2      (RAM2FAB_D_I[6]),
        .Tile_X4Y4_RAM2FAB_D1_I3      (RAM2FAB_D_I[7]),
        .Tile_X4Y4_RAM2FAB_D2_I0      (RAM2FAB_D_I[8]),
        .Tile_X4Y4_RAM2FAB_D2_I1      (RAM2FAB_D_I[9]),
        .Tile_X4Y4_RAM2FAB_D2_I2      (RAM2FAB_D_I[10]),
        .Tile_X4Y4_RAM2FAB_D2_I3      (RAM2FAB_D_I[11]),
        .Tile_X4Y4_RAM2FAB_D3_I0      (RAM2FAB_D_I[12]),
        .Tile_X4Y4_RAM2FAB_D3_I1      (RAM2FAB_D_I[13]),
        .Tile_X4Y4_RAM2FAB_D3_I2      (RAM2FAB_D_I[14]),
        .Tile_X4Y4_RAM2FAB_D3_I3      (RAM2FAB_D_I[15]),
        .Tile_X4Y3_RAM2FAB_D0_I0      (RAM2FAB_D_I[16]),
        .Tile_X4Y3_RAM2FAB_D0_I1      (RAM2FAB_D_I[17]),
        .Tile_X4Y3_RAM2FAB_D0_I2      (RAM2FAB_D_I[18]),
        .Tile_X4Y3_RAM2FAB_D0_I3      (RAM2FAB_D_I[19]),
        .Tile_X4Y3_RAM2FAB_D1_I0      (RAM2FAB_D_I[20]),
        .Tile_X4Y3_RAM2FAB_D1_I1      (RAM2FAB_D_I[21]),
        .Tile_X4Y3_RAM2FAB_D1_I2      (RAM2FAB_D_I[22]),
        .Tile_X4Y3_RAM2FAB_D1_I3      (RAM2FAB_D_I[23]),
        .Tile_X4Y3_RAM2FAB_D2_I0      (RAM2FAB_D_I[24]),
        .Tile_X4Y3_RAM2FAB_D2_I1      (RAM2FAB_D_I[25]),
        .Tile_X4Y3_RAM2FAB_D2_I2      (RAM2FAB_D_I[26]),
        .Tile_X4Y3_RAM2FAB_D2_I3      (RAM2FAB_D_I[27]),
        .Tile_X4Y3_RAM2FAB_D3_I0      (RAM2FAB_D_I[28]),
        .Tile_X4Y3_RAM2FAB_D3_I1      (RAM2FAB_D_I[29]),
        .Tile_X4Y3_RAM2FAB_D3_I2      (RAM2FAB_D_I[30]),
        .Tile_X4Y3_RAM2FAB_D3_I3      (RAM2FAB_D_I[31]),
        .Tile_X4Y2_RAM2FAB_D0_I0      (RAM2FAB_D_I[32]),
        .Tile_X4Y2_RAM2FAB_D0_I1      (RAM2FAB_D_I[33]),
        .Tile_X4Y2_RAM2FAB_D0_I2      (RAM2FAB_D_I[34]),
        .Tile_X4Y2_RAM2FAB_D0_I3      (RAM2FAB_D_I[35]),
        .Tile_X4Y2_RAM2FAB_D1_I0      (RAM2FAB_D_I[36]),
        .Tile_X4Y2_RAM2FAB_D1_I1      (RAM2FAB_D_I[37]),
        .Tile_X4Y2_RAM2FAB_D1_I2      (RAM2FAB_D_I[38]),
        .Tile_X4Y2_RAM2FAB_D1_I3      (RAM2FAB_D_I[39]),
        .Tile_X4Y2_RAM2FAB_D2_I0      (RAM2FAB_D_I[40]),
        .Tile_X4Y2_RAM2FAB_D2_I1      (RAM2FAB_D_I[41]),
        .Tile_X4Y2_RAM2FAB_D2_I2      (RAM2FAB_D_I[42]),
        .Tile_X4Y2_RAM2FAB_D2_I3      (RAM2FAB_D_I[43]),
        .Tile_X4Y2_RAM2FAB_D3_I0      (RAM2FAB_D_I[44]),
        .Tile_X4Y2_RAM2FAB_D3_I1      (RAM2FAB_D_I[45]),
        .Tile_X4Y2_RAM2FAB_D3_I2      (RAM2FAB_D_I[46]),
        .Tile_X4Y2_RAM2FAB_D3_I3      (RAM2FAB_D_I[47]),
        .Tile_X4Y1_RAM2FAB_D0_I0      (RAM2FAB_D_I[48]),
        .Tile_X4Y1_RAM2FAB_D0_I1      (RAM2FAB_D_I[49]),
        .Tile_X4Y1_RAM2FAB_D0_I2      (RAM2FAB_D_I[50]),
        .Tile_X4Y1_RAM2FAB_D0_I3      (RAM2FAB_D_I[51]),
        .Tile_X4Y1_RAM2FAB_D1_I0      (RAM2FAB_D_I[52]),
        .Tile_X4Y1_RAM2FAB_D1_I1      (RAM2FAB_D_I[53]),
        .Tile_X4Y1_RAM2FAB_D1_I2      (RAM2FAB_D_I[54]),
        .Tile_X4Y1_RAM2FAB_D1_I3      (RAM2FAB_D_I[55]),
        .Tile_X4Y1_RAM2FAB_D2_I0      (RAM2FAB_D_I[56]),
        .Tile_X4Y1_RAM2FAB_D2_I1      (RAM2FAB_D_I[57]),
        .Tile_X4Y1_RAM2FAB_D2_I2      (RAM2FAB_D_I[58]),
        .Tile_X4Y1_RAM2FAB_D2_I3      (RAM2FAB_D_I[59]),
        .Tile_X4Y1_RAM2FAB_D3_I0      (RAM2FAB_D_I[60]),
        .Tile_X4Y1_RAM2FAB_D3_I1      (RAM2FAB_D_I[61]),
        .Tile_X4Y1_RAM2FAB_D3_I2      (RAM2FAB_D_I[62]),
        .Tile_X4Y1_RAM2FAB_D3_I3      (RAM2FAB_D_I[63]),
        .Tile_X0Y4_B_T_top            (T_top[0]),
        .Tile_X0Y4_A_T_top            (T_top[1]),
        .Tile_X0Y3_B_T_top            (T_top[2]),
        .Tile_X0Y3_A_T_top            (T_top[3]),
        .Tile_X0Y2_B_T_top            (T_top[4]),
        .Tile_X0Y2_A_T_top            (T_top[5]),
        .Tile_X0Y1_B_T_top            (T_top[6]),
        .Tile_X0Y1_A_T_top            (T_top[7]),
        .UserCLK                      (CLK),
        .FrameData                    (FrameData),
        .FrameStrobe                  (FrameSelect)
    );


    BlockRAM_1KB Inst_BlockRAM_0 (
        .clk    (CLK),
        .rd_addr(FAB2RAM_A_O[7:0]),
        .rd_data(RAM2FAB_D_I[31:0]),
        .wr_addr(FAB2RAM_A_O[15:8]),
        .wr_data(FAB2RAM_D_O[31:0]),
        .C0     (FAB2RAM_C_O[0]),
        .C1     (FAB2RAM_C_O[1]),
        .C2     (FAB2RAM_C_O[2]),
        .C3     (FAB2RAM_C_O[3]),
        .C4     (FAB2RAM_C_O[4]),
        .C5     (FAB2RAM_C_O[5])
    );

    BlockRAM_1KB Inst_BlockRAM_1 (
        .clk    (CLK),
        .rd_addr(FAB2RAM_A_O[23:16]),
        .rd_data(RAM2FAB_D_I[63:32]),
        .wr_addr(FAB2RAM_A_O[31:24]),
        .wr_data(FAB2RAM_D_O[63:32]),
        .C0     (FAB2RAM_C_O[8]),
        .C1     (FAB2RAM_C_O[9]),
        .C2     (FAB2RAM_C_O[10]),
        .C3     (FAB2RAM_C_O[11]),
        .C4     (FAB2RAM_C_O[12]),
        .C5     (FAB2RAM_C_O[13])
    );

    assign FrameData = {32'h12345678, FrameRegister, 32'h12345678};
endmodule
