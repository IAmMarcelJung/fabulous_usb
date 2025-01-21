module eFPGA_top #(
    parameter include_eFPGA = 1,
    parameter NumberOfRows = 5,
    parameter NumberOfCols = 5,
    parameter FrameBitsPerRow = 32,
    parameter MaxFramesPerCol = 20,
    parameter desync_flag = 20,
    parameter FrameSelectWidth = 5,
    parameter RowSelectWidth = 5,
    parameter NumUsedIOs = 8,
    parameter NUM_OF_ANODES = 8

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

  wire [80-1:0] RAM2FAB_D_I;
  wire [80-1:0] FAB2RAM_D_O;
  wire [40-1:0] FAB2RAM_A_O;
  wire [20-1:0] FAB2RAM_C_O;

  //Signal declarations
  wire [(NumberOfRows*FrameBitsPerRow)-1:0] FrameRegister;
  wire [(MaxFramesPerCol*NumberOfCols)-1:0] FrameSelect;
  wire [(FrameBitsPerRow*(NumberOfRows+2))-1:0] FrameData;
  wire [FrameBitsPerRow-1:0] FrameAddressRegister;
  wire LongFrameStrobe;
  wire [31:0] LocalWriteData;
  wire LocalWriteStrobe;
  wire [RowSelectWidth-1:0] RowSelect;
  wire resetn;

  //JTAG related signals
  wire [NumUsedIOs-1:0] I_out;
  wire [NumUsedIOs-1:0] O_in;
  wire [31:0] JTAGWriteData;
  wire JTAGWriteStrobe;
  wire JTAGActive;

  assign resetn = !reset;

  genvar i;
  generate
    for (i = 0; i < NumUsedIOs; i = i + 1) begin : g_tristate_outputs
      assign user_io[i] = T_top[i] ? I_top : 1'bz;
    end
  endgenerate

  assign O_top[NUM_OF_ANODES-1] = user_io;

  tap #(
      .bsregInLen(NumUsedIOs),
      .bsregInLen(NumUsedIOs)
  ) Inst_jtag (
      .tck(tck),
      .tms(tms),
      .tdi(tdi),
      .tdo(tdo),
      .trst(resetn),
      .pins_in(O_top),
      .pins_out(I_top),
      .logic_pins_in(O_in),
      .logic_pins_out(I_out),
      .active(JTAGActive),
      .config_data(JTAGWriteData),
      .config_strobe(JTAGWriteStrobe)
  );

  eFPGA_Config #(
      .RowSelectWidth(RowSelectWidth),
      .NumberOfRows(NumberOfRows),
      .desync_flag(desync_flag),
      .FrameBitsPerRow(FrameBitsPerRow)
  ) eFPGA_Config_inst (
      .CLK(CLK),
      .resetn(resetn),
      .Rx(Rx),
      .ComActive(ComActive),
      .ReceiveLED(ReceiveLED),
      .s_clk(),
      .s_data(),
      .SelfWriteData(),
      .SelfWriteStrobe(),
      .ConfigWriteData(LocalWriteData),
      .ConfigWriteStrobe(LocalWriteStrobe),
      .FrameAddressRegister(FrameAddressRegister),
      .LongFrameStrobe(LongFrameStrobe),
      .RowSelect(RowSelect),
      .JTAGWriteData(JTAGWriteData),
      .JTAGWriteStrobe(JTAGWriteStrobe),
      .JTAGActive(JTAGActive),
      .tck(tck)
  );


  Frame_Data_Reg #(
      .FrameBitsPerRow(FrameBitsPerRow),
      .RowSelectWidth(RowSelectWidth),
      .Row(1)
  ) inst_Frame_Data_Reg_0 (
      .FrameData_I(LocalWriteData),
      .FrameData_O(FrameRegister[0*FrameBitsPerRow+FrameBitsPerRow-1:0*FrameBitsPerRow]),
      .RowSelect(RowSelect),
      .CLK(CLK)
  );

  Frame_Data_Reg #(
      .FrameBitsPerRow(FrameBitsPerRow),
      .RowSelectWidth(RowSelectWidth),
      .Row(2)
  ) inst_Frame_Data_Reg_1 (
      .FrameData_I(LocalWriteData),
      .FrameData_O(FrameRegister[1*FrameBitsPerRow+FrameBitsPerRow-1:1*FrameBitsPerRow]),
      .RowSelect(RowSelect),
      .CLK(CLK)
  );

  Frame_Data_Reg #(
      .FrameBitsPerRow(FrameBitsPerRow),
      .RowSelectWidth(RowSelectWidth),
      .Row(3)
  ) inst_Frame_Data_Reg_2 (
      .FrameData_I(LocalWriteData),
      .FrameData_O(FrameRegister[2*FrameBitsPerRow+FrameBitsPerRow-1:2*FrameBitsPerRow]),
      .RowSelect(RowSelect),
      .CLK(CLK)
  );

  Frame_Data_Reg #(
      .FrameBitsPerRow(FrameBitsPerRow),
      .RowSelectWidth(RowSelectWidth),
      .Row(4)
  ) inst_Frame_Data_Reg_3 (
      .FrameData_I(LocalWriteData),
      .FrameData_O(FrameRegister[3*FrameBitsPerRow+FrameBitsPerRow-1:3*FrameBitsPerRow]),
      .RowSelect(RowSelect),
      .CLK(CLK)
  );

  Frame_Data_Reg #(
      .FrameBitsPerRow(FrameBitsPerRow),
      .RowSelectWidth(RowSelectWidth),
      .Row(5)
  ) inst_Frame_Data_Reg_4 (
      .FrameData_I(LocalWriteData),
      .FrameData_O(FrameRegister[4*FrameBitsPerRow+FrameBitsPerRow-1:4*FrameBitsPerRow]),
      .RowSelect(RowSelect),
      .CLK(CLK)
  );


  Frame_Select #(
      .MaxFramesPerCol(MaxFramesPerCol),
      .FrameSelectWidth(FrameSelectWidth),
      .Col(0)
  ) inst_Frame_Select_0 (
      .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
      .FrameStrobe_O(FrameSelect[0*MaxFramesPerCol+MaxFramesPerCol-1:0*MaxFramesPerCol]),
      .FrameSelect  (FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-FrameSelectWidth]),
      .FrameStrobe  (LongFrameStrobe)
  );

  Frame_Select #(
      .MaxFramesPerCol(MaxFramesPerCol),
      .FrameSelectWidth(FrameSelectWidth),
      .Col(1)
  ) inst_Frame_Select_1 (
      .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
      .FrameStrobe_O(FrameSelect[1*MaxFramesPerCol+MaxFramesPerCol-1:1*MaxFramesPerCol]),
      .FrameSelect  (FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-FrameSelectWidth]),
      .FrameStrobe  (LongFrameStrobe)
  );

  Frame_Select #(
      .MaxFramesPerCol(MaxFramesPerCol),
      .FrameSelectWidth(FrameSelectWidth),
      .Col(2)
  ) inst_Frame_Select_2 (
      .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
      .FrameStrobe_O(FrameSelect[2*MaxFramesPerCol+MaxFramesPerCol-1:2*MaxFramesPerCol]),
      .FrameSelect  (FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-FrameSelectWidth]),
      .FrameStrobe  (LongFrameStrobe)
  );

  Frame_Select #(
      .MaxFramesPerCol(MaxFramesPerCol),
      .FrameSelectWidth(FrameSelectWidth),
      .Col(3)
  ) inst_Frame_Select_3 (
      .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
      .FrameStrobe_O(FrameSelect[3*MaxFramesPerCol+MaxFramesPerCol-1:3*MaxFramesPerCol]),
      .FrameSelect  (FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-FrameSelectWidth]),
      .FrameStrobe  (LongFrameStrobe)
  );

  Frame_Select #(
      .MaxFramesPerCol(MaxFramesPerCol),
      .FrameSelectWidth(FrameSelectWidth),
      .Col(4)
  ) inst_Frame_Select_4 (
      .FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
      .FrameStrobe_O(FrameSelect[4*MaxFramesPerCol+MaxFramesPerCol-1:4*MaxFramesPerCol]),
      .FrameSelect  (FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-FrameSelectWidth]),
      .FrameStrobe  (LongFrameStrobe)
  );


  eFPGA eFPGA_inst (
      .Tile_X0Y5_A_config_C_bit0(A_config_C[0]),
      .Tile_X0Y5_A_config_C_bit1(A_config_C[1]),
      .Tile_X0Y5_A_config_C_bit2(A_config_C[2]),
      .Tile_X0Y5_A_config_C_bit3(A_config_C[3]),
      .Tile_X0Y4_A_config_C_bit0(A_config_C[4]),
      .Tile_X0Y4_A_config_C_bit1(A_config_C[5]),
      .Tile_X0Y4_A_config_C_bit2(A_config_C[6]),
      .Tile_X0Y4_A_config_C_bit3(A_config_C[7]),
      .Tile_X0Y3_A_config_C_bit0(A_config_C[8]),
      .Tile_X0Y3_A_config_C_bit1(A_config_C[9]),
      .Tile_X0Y3_A_config_C_bit2(A_config_C[10]),
      .Tile_X0Y3_A_config_C_bit3(A_config_C[11]),
      .Tile_X0Y2_A_config_C_bit0(A_config_C[12]),
      .Tile_X0Y2_A_config_C_bit1(A_config_C[13]),
      .Tile_X0Y2_A_config_C_bit2(A_config_C[14]),
      .Tile_X0Y2_A_config_C_bit3(A_config_C[15]),
      .Tile_X0Y1_A_config_C_bit0(A_config_C[16]),
      .Tile_X0Y1_A_config_C_bit1(A_config_C[17]),
      .Tile_X0Y1_A_config_C_bit2(A_config_C[18]),
      .Tile_X0Y1_A_config_C_bit3(A_config_C[19]),
      .Tile_X0Y5_B_config_C_bit0(B_config_C[0]),
      .Tile_X0Y5_B_config_C_bit1(B_config_C[1]),
      .Tile_X0Y5_B_config_C_bit2(B_config_C[2]),
      .Tile_X0Y5_B_config_C_bit3(B_config_C[3]),
      .Tile_X0Y4_B_config_C_bit0(B_config_C[4]),
      .Tile_X0Y4_B_config_C_bit1(B_config_C[5]),
      .Tile_X0Y4_B_config_C_bit2(B_config_C[6]),
      .Tile_X0Y4_B_config_C_bit3(B_config_C[7]),
      .Tile_X0Y3_B_config_C_bit0(B_config_C[8]),
      .Tile_X0Y3_B_config_C_bit1(B_config_C[9]),
      .Tile_X0Y3_B_config_C_bit2(B_config_C[10]),
      .Tile_X0Y3_B_config_C_bit3(B_config_C[11]),
      .Tile_X0Y2_B_config_C_bit0(B_config_C[12]),
      .Tile_X0Y2_B_config_C_bit1(B_config_C[13]),
      .Tile_X0Y2_B_config_C_bit2(B_config_C[14]),
      .Tile_X0Y2_B_config_C_bit3(B_config_C[15]),
      .Tile_X0Y1_B_config_C_bit0(B_config_C[16]),
      .Tile_X0Y1_B_config_C_bit1(B_config_C[17]),
      .Tile_X0Y1_B_config_C_bit2(B_config_C[18]),
      .Tile_X0Y1_B_config_C_bit3(B_config_C[19]),
      .Tile_X4Y5_Config_accessC_bit0(Config_accessC[0]),
      .Tile_X4Y5_Config_accessC_bit1(Config_accessC[1]),
      .Tile_X4Y5_Config_accessC_bit2(Config_accessC[2]),
      .Tile_X4Y5_Config_accessC_bit3(Config_accessC[3]),
      .Tile_X4Y4_Config_accessC_bit0(Config_accessC[4]),
      .Tile_X4Y4_Config_accessC_bit1(Config_accessC[5]),
      .Tile_X4Y4_Config_accessC_bit2(Config_accessC[6]),
      .Tile_X4Y4_Config_accessC_bit3(Config_accessC[7]),
      .Tile_X4Y3_Config_accessC_bit0(Config_accessC[8]),
      .Tile_X4Y3_Config_accessC_bit1(Config_accessC[9]),
      .Tile_X4Y3_Config_accessC_bit2(Config_accessC[10]),
      .Tile_X4Y3_Config_accessC_bit3(Config_accessC[11]),
      .Tile_X4Y2_Config_accessC_bit0(Config_accessC[12]),
      .Tile_X4Y2_Config_accessC_bit1(Config_accessC[13]),
      .Tile_X4Y2_Config_accessC_bit2(Config_accessC[14]),
      .Tile_X4Y2_Config_accessC_bit3(Config_accessC[15]),
      .Tile_X4Y1_Config_accessC_bit0(Config_accessC[16]),
      .Tile_X4Y1_Config_accessC_bit1(Config_accessC[17]),
      .Tile_X4Y1_Config_accessC_bit2(Config_accessC[18]),
      .Tile_X4Y1_Config_accessC_bit3(Config_accessC[19]),
      .Tile_X4Y5_FAB2RAM_A0_O0(FAB2RAM_A_O[0]),
      .Tile_X4Y5_FAB2RAM_A0_O1(FAB2RAM_A_O[1]),
      .Tile_X4Y5_FAB2RAM_A0_O2(FAB2RAM_A_O[2]),
      .Tile_X4Y5_FAB2RAM_A0_O3(FAB2RAM_A_O[3]),
      .Tile_X4Y5_FAB2RAM_A1_O0(FAB2RAM_A_O[4]),
      .Tile_X4Y5_FAB2RAM_A1_O1(FAB2RAM_A_O[5]),
      .Tile_X4Y5_FAB2RAM_A1_O2(FAB2RAM_A_O[6]),
      .Tile_X4Y5_FAB2RAM_A1_O3(FAB2RAM_A_O[7]),
      .Tile_X4Y4_FAB2RAM_A0_O0(FAB2RAM_A_O[8]),
      .Tile_X4Y4_FAB2RAM_A0_O1(FAB2RAM_A_O[9]),
      .Tile_X4Y4_FAB2RAM_A0_O2(FAB2RAM_A_O[10]),
      .Tile_X4Y4_FAB2RAM_A0_O3(FAB2RAM_A_O[11]),
      .Tile_X4Y4_FAB2RAM_A1_O0(FAB2RAM_A_O[12]),
      .Tile_X4Y4_FAB2RAM_A1_O1(FAB2RAM_A_O[13]),
      .Tile_X4Y4_FAB2RAM_A1_O2(FAB2RAM_A_O[14]),
      .Tile_X4Y4_FAB2RAM_A1_O3(FAB2RAM_A_O[15]),
      .Tile_X4Y3_FAB2RAM_A0_O0(FAB2RAM_A_O[16]),
      .Tile_X4Y3_FAB2RAM_A0_O1(FAB2RAM_A_O[17]),
      .Tile_X4Y3_FAB2RAM_A0_O2(FAB2RAM_A_O[18]),
      .Tile_X4Y3_FAB2RAM_A0_O3(FAB2RAM_A_O[19]),
      .Tile_X4Y3_FAB2RAM_A1_O0(FAB2RAM_A_O[20]),
      .Tile_X4Y3_FAB2RAM_A1_O1(FAB2RAM_A_O[21]),
      .Tile_X4Y3_FAB2RAM_A1_O2(FAB2RAM_A_O[22]),
      .Tile_X4Y3_FAB2RAM_A1_O3(FAB2RAM_A_O[23]),
      .Tile_X4Y2_FAB2RAM_A0_O0(FAB2RAM_A_O[24]),
      .Tile_X4Y2_FAB2RAM_A0_O1(FAB2RAM_A_O[25]),
      .Tile_X4Y2_FAB2RAM_A0_O2(FAB2RAM_A_O[26]),
      .Tile_X4Y2_FAB2RAM_A0_O3(FAB2RAM_A_O[27]),
      .Tile_X4Y2_FAB2RAM_A1_O0(FAB2RAM_A_O[28]),
      .Tile_X4Y2_FAB2RAM_A1_O1(FAB2RAM_A_O[29]),
      .Tile_X4Y2_FAB2RAM_A1_O2(FAB2RAM_A_O[30]),
      .Tile_X4Y2_FAB2RAM_A1_O3(FAB2RAM_A_O[31]),
      .Tile_X4Y1_FAB2RAM_A0_O0(FAB2RAM_A_O[32]),
      .Tile_X4Y1_FAB2RAM_A0_O1(FAB2RAM_A_O[33]),
      .Tile_X4Y1_FAB2RAM_A0_O2(FAB2RAM_A_O[34]),
      .Tile_X4Y1_FAB2RAM_A0_O3(FAB2RAM_A_O[35]),
      .Tile_X4Y1_FAB2RAM_A1_O0(FAB2RAM_A_O[36]),
      .Tile_X4Y1_FAB2RAM_A1_O1(FAB2RAM_A_O[37]),
      .Tile_X4Y1_FAB2RAM_A1_O2(FAB2RAM_A_O[38]),
      .Tile_X4Y1_FAB2RAM_A1_O3(FAB2RAM_A_O[39]),
      .Tile_X4Y5_FAB2RAM_C_O0(FAB2RAM_C_O[0]),
      .Tile_X4Y5_FAB2RAM_C_O1(FAB2RAM_C_O[1]),
      .Tile_X4Y5_FAB2RAM_C_O2(FAB2RAM_C_O[2]),
      .Tile_X4Y5_FAB2RAM_C_O3(FAB2RAM_C_O[3]),
      .Tile_X4Y4_FAB2RAM_C_O0(FAB2RAM_C_O[4]),
      .Tile_X4Y4_FAB2RAM_C_O1(FAB2RAM_C_O[5]),
      .Tile_X4Y4_FAB2RAM_C_O2(FAB2RAM_C_O[6]),
      .Tile_X4Y4_FAB2RAM_C_O3(FAB2RAM_C_O[7]),
      .Tile_X4Y3_FAB2RAM_C_O0(FAB2RAM_C_O[8]),
      .Tile_X4Y3_FAB2RAM_C_O1(FAB2RAM_C_O[9]),
      .Tile_X4Y3_FAB2RAM_C_O2(FAB2RAM_C_O[10]),
      .Tile_X4Y3_FAB2RAM_C_O3(FAB2RAM_C_O[11]),
      .Tile_X4Y2_FAB2RAM_C_O0(FAB2RAM_C_O[12]),
      .Tile_X4Y2_FAB2RAM_C_O1(FAB2RAM_C_O[13]),
      .Tile_X4Y2_FAB2RAM_C_O2(FAB2RAM_C_O[14]),
      .Tile_X4Y2_FAB2RAM_C_O3(FAB2RAM_C_O[15]),
      .Tile_X4Y1_FAB2RAM_C_O0(FAB2RAM_C_O[16]),
      .Tile_X4Y1_FAB2RAM_C_O1(FAB2RAM_C_O[17]),
      .Tile_X4Y1_FAB2RAM_C_O2(FAB2RAM_C_O[18]),
      .Tile_X4Y1_FAB2RAM_C_O3(FAB2RAM_C_O[19]),
      .Tile_X4Y5_FAB2RAM_D0_O0(FAB2RAM_D_O[0]),
      .Tile_X4Y5_FAB2RAM_D0_O1(FAB2RAM_D_O[1]),
      .Tile_X4Y5_FAB2RAM_D0_O2(FAB2RAM_D_O[2]),
      .Tile_X4Y5_FAB2RAM_D0_O3(FAB2RAM_D_O[3]),
      .Tile_X4Y5_FAB2RAM_D1_O0(FAB2RAM_D_O[4]),
      .Tile_X4Y5_FAB2RAM_D1_O1(FAB2RAM_D_O[5]),
      .Tile_X4Y5_FAB2RAM_D1_O2(FAB2RAM_D_O[6]),
      .Tile_X4Y5_FAB2RAM_D1_O3(FAB2RAM_D_O[7]),
      .Tile_X4Y5_FAB2RAM_D2_O0(FAB2RAM_D_O[8]),
      .Tile_X4Y5_FAB2RAM_D2_O1(FAB2RAM_D_O[9]),
      .Tile_X4Y5_FAB2RAM_D2_O2(FAB2RAM_D_O[10]),
      .Tile_X4Y5_FAB2RAM_D2_O3(FAB2RAM_D_O[11]),
      .Tile_X4Y5_FAB2RAM_D3_O0(FAB2RAM_D_O[12]),
      .Tile_X4Y5_FAB2RAM_D3_O1(FAB2RAM_D_O[13]),
      .Tile_X4Y5_FAB2RAM_D3_O2(FAB2RAM_D_O[14]),
      .Tile_X4Y5_FAB2RAM_D3_O3(FAB2RAM_D_O[15]),
      .Tile_X4Y4_FAB2RAM_D0_O0(FAB2RAM_D_O[16]),
      .Tile_X4Y4_FAB2RAM_D0_O1(FAB2RAM_D_O[17]),
      .Tile_X4Y4_FAB2RAM_D0_O2(FAB2RAM_D_O[18]),
      .Tile_X4Y4_FAB2RAM_D0_O3(FAB2RAM_D_O[19]),
      .Tile_X4Y4_FAB2RAM_D1_O0(FAB2RAM_D_O[20]),
      .Tile_X4Y4_FAB2RAM_D1_O1(FAB2RAM_D_O[21]),
      .Tile_X4Y4_FAB2RAM_D1_O2(FAB2RAM_D_O[22]),
      .Tile_X4Y4_FAB2RAM_D1_O3(FAB2RAM_D_O[23]),
      .Tile_X4Y4_FAB2RAM_D2_O0(FAB2RAM_D_O[24]),
      .Tile_X4Y4_FAB2RAM_D2_O1(FAB2RAM_D_O[25]),
      .Tile_X4Y4_FAB2RAM_D2_O2(FAB2RAM_D_O[26]),
      .Tile_X4Y4_FAB2RAM_D2_O3(FAB2RAM_D_O[27]),
      .Tile_X4Y4_FAB2RAM_D3_O0(FAB2RAM_D_O[28]),
      .Tile_X4Y4_FAB2RAM_D3_O1(FAB2RAM_D_O[29]),
      .Tile_X4Y4_FAB2RAM_D3_O2(FAB2RAM_D_O[30]),
      .Tile_X4Y4_FAB2RAM_D3_O3(FAB2RAM_D_O[31]),
      .Tile_X4Y3_FAB2RAM_D0_O0(FAB2RAM_D_O[32]),
      .Tile_X4Y3_FAB2RAM_D0_O1(FAB2RAM_D_O[33]),
      .Tile_X4Y3_FAB2RAM_D0_O2(FAB2RAM_D_O[34]),
      .Tile_X4Y3_FAB2RAM_D0_O3(FAB2RAM_D_O[35]),
      .Tile_X4Y3_FAB2RAM_D1_O0(FAB2RAM_D_O[36]),
      .Tile_X4Y3_FAB2RAM_D1_O1(FAB2RAM_D_O[37]),
      .Tile_X4Y3_FAB2RAM_D1_O2(FAB2RAM_D_O[38]),
      .Tile_X4Y3_FAB2RAM_D1_O3(FAB2RAM_D_O[39]),
      .Tile_X4Y3_FAB2RAM_D2_O0(FAB2RAM_D_O[40]),
      .Tile_X4Y3_FAB2RAM_D2_O1(FAB2RAM_D_O[41]),
      .Tile_X4Y3_FAB2RAM_D2_O2(FAB2RAM_D_O[42]),
      .Tile_X4Y3_FAB2RAM_D2_O3(FAB2RAM_D_O[43]),
      .Tile_X4Y3_FAB2RAM_D3_O0(FAB2RAM_D_O[44]),
      .Tile_X4Y3_FAB2RAM_D3_O1(FAB2RAM_D_O[45]),
      .Tile_X4Y3_FAB2RAM_D3_O2(FAB2RAM_D_O[46]),
      .Tile_X4Y3_FAB2RAM_D3_O3(FAB2RAM_D_O[47]),
      .Tile_X4Y2_FAB2RAM_D0_O0(FAB2RAM_D_O[48]),
      .Tile_X4Y2_FAB2RAM_D0_O1(FAB2RAM_D_O[49]),
      .Tile_X4Y2_FAB2RAM_D0_O2(FAB2RAM_D_O[50]),
      .Tile_X4Y2_FAB2RAM_D0_O3(FAB2RAM_D_O[51]),
      .Tile_X4Y2_FAB2RAM_D1_O0(FAB2RAM_D_O[52]),
      .Tile_X4Y2_FAB2RAM_D1_O1(FAB2RAM_D_O[53]),
      .Tile_X4Y2_FAB2RAM_D1_O2(FAB2RAM_D_O[54]),
      .Tile_X4Y2_FAB2RAM_D1_O3(FAB2RAM_D_O[55]),
      .Tile_X4Y2_FAB2RAM_D2_O0(FAB2RAM_D_O[56]),
      .Tile_X4Y2_FAB2RAM_D2_O1(FAB2RAM_D_O[57]),
      .Tile_X4Y2_FAB2RAM_D2_O2(FAB2RAM_D_O[58]),
      .Tile_X4Y2_FAB2RAM_D2_O3(FAB2RAM_D_O[59]),
      .Tile_X4Y2_FAB2RAM_D3_O0(FAB2RAM_D_O[60]),
      .Tile_X4Y2_FAB2RAM_D3_O1(FAB2RAM_D_O[61]),
      .Tile_X4Y2_FAB2RAM_D3_O2(FAB2RAM_D_O[62]),
      .Tile_X4Y2_FAB2RAM_D3_O3(FAB2RAM_D_O[63]),
      .Tile_X4Y1_FAB2RAM_D0_O0(FAB2RAM_D_O[64]),
      .Tile_X4Y1_FAB2RAM_D0_O1(FAB2RAM_D_O[65]),
      .Tile_X4Y1_FAB2RAM_D0_O2(FAB2RAM_D_O[66]),
      .Tile_X4Y1_FAB2RAM_D0_O3(FAB2RAM_D_O[67]),
      .Tile_X4Y1_FAB2RAM_D1_O0(FAB2RAM_D_O[68]),
      .Tile_X4Y1_FAB2RAM_D1_O1(FAB2RAM_D_O[69]),
      .Tile_X4Y1_FAB2RAM_D1_O2(FAB2RAM_D_O[70]),
      .Tile_X4Y1_FAB2RAM_D1_O3(FAB2RAM_D_O[71]),
      .Tile_X4Y1_FAB2RAM_D2_O0(FAB2RAM_D_O[72]),
      .Tile_X4Y1_FAB2RAM_D2_O1(FAB2RAM_D_O[73]),
      .Tile_X4Y1_FAB2RAM_D2_O2(FAB2RAM_D_O[74]),
      .Tile_X4Y1_FAB2RAM_D2_O3(FAB2RAM_D_O[75]),
      .Tile_X4Y1_FAB2RAM_D3_O0(FAB2RAM_D_O[76]),
      .Tile_X4Y1_FAB2RAM_D3_O1(FAB2RAM_D_O[77]),
      .Tile_X4Y1_FAB2RAM_D3_O2(FAB2RAM_D_O[78]),
      .Tile_X4Y1_FAB2RAM_D3_O3(FAB2RAM_D_O[79]),
      .Tile_X0Y5_B_I_top(I_top[0]),
      .Tile_X0Y5_A_I_top(I_top[1]),
      .Tile_X0Y4_B_I_top(I_top[2]),
      .Tile_X0Y4_A_I_top(I_top[3]),
      .Tile_X0Y3_B_I_top(I_top[4]),
      .Tile_X0Y3_A_I_top(I_top[5]),
      .Tile_X0Y2_B_I_top(I_top[6]),
      .Tile_X0Y2_A_I_top(I_top[7]),
      .Tile_X0Y1_B_I_top(I_top[8]),
      .Tile_X0Y1_A_I_top(I_top[9]),
      .Tile_X0Y5_B_O_top(O_top[0]),
      .Tile_X0Y5_A_O_top(O_top[1]),
      .Tile_X0Y4_B_O_top(O_top[2]),
      .Tile_X0Y4_A_O_top(O_top[3]),
      .Tile_X0Y3_B_O_top(O_top[4]),
      .Tile_X0Y3_A_O_top(O_top[5]),
      .Tile_X0Y2_B_O_top(O_top[6]),
      .Tile_X0Y2_A_O_top(O_top[7]),
      .Tile_X0Y1_B_O_top(O_top[8]),
      .Tile_X0Y1_A_O_top(O_top[9]),
      .Tile_X4Y5_RAM2FAB_D0_I0(RAM2FAB_D_I[0]),
      .Tile_X4Y5_RAM2FAB_D0_I1(RAM2FAB_D_I[1]),
      .Tile_X4Y5_RAM2FAB_D0_I2(RAM2FAB_D_I[2]),
      .Tile_X4Y5_RAM2FAB_D0_I3(RAM2FAB_D_I[3]),
      .Tile_X4Y5_RAM2FAB_D1_I0(RAM2FAB_D_I[4]),
      .Tile_X4Y5_RAM2FAB_D1_I1(RAM2FAB_D_I[5]),
      .Tile_X4Y5_RAM2FAB_D1_I2(RAM2FAB_D_I[6]),
      .Tile_X4Y5_RAM2FAB_D1_I3(RAM2FAB_D_I[7]),
      .Tile_X4Y5_RAM2FAB_D2_I0(RAM2FAB_D_I[8]),
      .Tile_X4Y5_RAM2FAB_D2_I1(RAM2FAB_D_I[9]),
      .Tile_X4Y5_RAM2FAB_D2_I2(RAM2FAB_D_I[10]),
      .Tile_X4Y5_RAM2FAB_D2_I3(RAM2FAB_D_I[11]),
      .Tile_X4Y5_RAM2FAB_D3_I0(RAM2FAB_D_I[12]),
      .Tile_X4Y5_RAM2FAB_D3_I1(RAM2FAB_D_I[13]),
      .Tile_X4Y5_RAM2FAB_D3_I2(RAM2FAB_D_I[14]),
      .Tile_X4Y5_RAM2FAB_D3_I3(RAM2FAB_D_I[15]),
      .Tile_X4Y4_RAM2FAB_D0_I0(RAM2FAB_D_I[16]),
      .Tile_X4Y4_RAM2FAB_D0_I1(RAM2FAB_D_I[17]),
      .Tile_X4Y4_RAM2FAB_D0_I2(RAM2FAB_D_I[18]),
      .Tile_X4Y4_RAM2FAB_D0_I3(RAM2FAB_D_I[19]),
      .Tile_X4Y4_RAM2FAB_D1_I0(RAM2FAB_D_I[20]),
      .Tile_X4Y4_RAM2FAB_D1_I1(RAM2FAB_D_I[21]),
      .Tile_X4Y4_RAM2FAB_D1_I2(RAM2FAB_D_I[22]),
      .Tile_X4Y4_RAM2FAB_D1_I3(RAM2FAB_D_I[23]),
      .Tile_X4Y4_RAM2FAB_D2_I0(RAM2FAB_D_I[24]),
      .Tile_X4Y4_RAM2FAB_D2_I1(RAM2FAB_D_I[25]),
      .Tile_X4Y4_RAM2FAB_D2_I2(RAM2FAB_D_I[26]),
      .Tile_X4Y4_RAM2FAB_D2_I3(RAM2FAB_D_I[27]),
      .Tile_X4Y4_RAM2FAB_D3_I0(RAM2FAB_D_I[28]),
      .Tile_X4Y4_RAM2FAB_D3_I1(RAM2FAB_D_I[29]),
      .Tile_X4Y4_RAM2FAB_D3_I2(RAM2FAB_D_I[30]),
      .Tile_X4Y4_RAM2FAB_D3_I3(RAM2FAB_D_I[31]),
      .Tile_X4Y3_RAM2FAB_D0_I0(RAM2FAB_D_I[32]),
      .Tile_X4Y3_RAM2FAB_D0_I1(RAM2FAB_D_I[33]),
      .Tile_X4Y3_RAM2FAB_D0_I2(RAM2FAB_D_I[34]),
      .Tile_X4Y3_RAM2FAB_D0_I3(RAM2FAB_D_I[35]),
      .Tile_X4Y3_RAM2FAB_D1_I0(RAM2FAB_D_I[36]),
      .Tile_X4Y3_RAM2FAB_D1_I1(RAM2FAB_D_I[37]),
      .Tile_X4Y3_RAM2FAB_D1_I2(RAM2FAB_D_I[38]),
      .Tile_X4Y3_RAM2FAB_D1_I3(RAM2FAB_D_I[39]),
      .Tile_X4Y3_RAM2FAB_D2_I0(RAM2FAB_D_I[40]),
      .Tile_X4Y3_RAM2FAB_D2_I1(RAM2FAB_D_I[41]),
      .Tile_X4Y3_RAM2FAB_D2_I2(RAM2FAB_D_I[42]),
      .Tile_X4Y3_RAM2FAB_D2_I3(RAM2FAB_D_I[43]),
      .Tile_X4Y3_RAM2FAB_D3_I0(RAM2FAB_D_I[44]),
      .Tile_X4Y3_RAM2FAB_D3_I1(RAM2FAB_D_I[45]),
      .Tile_X4Y3_RAM2FAB_D3_I2(RAM2FAB_D_I[46]),
      .Tile_X4Y3_RAM2FAB_D3_I3(RAM2FAB_D_I[47]),
      .Tile_X4Y2_RAM2FAB_D0_I0(RAM2FAB_D_I[48]),
      .Tile_X4Y2_RAM2FAB_D0_I1(RAM2FAB_D_I[49]),
      .Tile_X4Y2_RAM2FAB_D0_I2(RAM2FAB_D_I[50]),
      .Tile_X4Y2_RAM2FAB_D0_I3(RAM2FAB_D_I[51]),
      .Tile_X4Y2_RAM2FAB_D1_I0(RAM2FAB_D_I[52]),
      .Tile_X4Y2_RAM2FAB_D1_I1(RAM2FAB_D_I[53]),
      .Tile_X4Y2_RAM2FAB_D1_I2(RAM2FAB_D_I[54]),
      .Tile_X4Y2_RAM2FAB_D1_I3(RAM2FAB_D_I[55]),
      .Tile_X4Y2_RAM2FAB_D2_I0(RAM2FAB_D_I[56]),
      .Tile_X4Y2_RAM2FAB_D2_I1(RAM2FAB_D_I[57]),
      .Tile_X4Y2_RAM2FAB_D2_I2(RAM2FAB_D_I[58]),
      .Tile_X4Y2_RAM2FAB_D2_I3(RAM2FAB_D_I[59]),
      .Tile_X4Y2_RAM2FAB_D3_I0(RAM2FAB_D_I[60]),
      .Tile_X4Y2_RAM2FAB_D3_I1(RAM2FAB_D_I[61]),
      .Tile_X4Y2_RAM2FAB_D3_I2(RAM2FAB_D_I[62]),
      .Tile_X4Y2_RAM2FAB_D3_I3(RAM2FAB_D_I[63]),
      .Tile_X4Y1_RAM2FAB_D0_I0(RAM2FAB_D_I[64]),
      .Tile_X4Y1_RAM2FAB_D0_I1(RAM2FAB_D_I[65]),
      .Tile_X4Y1_RAM2FAB_D0_I2(RAM2FAB_D_I[66]),
      .Tile_X4Y1_RAM2FAB_D0_I3(RAM2FAB_D_I[67]),
      .Tile_X4Y1_RAM2FAB_D1_I0(RAM2FAB_D_I[68]),
      .Tile_X4Y1_RAM2FAB_D1_I1(RAM2FAB_D_I[69]),
      .Tile_X4Y1_RAM2FAB_D1_I2(RAM2FAB_D_I[70]),
      .Tile_X4Y1_RAM2FAB_D1_I3(RAM2FAB_D_I[71]),
      .Tile_X4Y1_RAM2FAB_D2_I0(RAM2FAB_D_I[72]),
      .Tile_X4Y1_RAM2FAB_D2_I1(RAM2FAB_D_I[73]),
      .Tile_X4Y1_RAM2FAB_D2_I2(RAM2FAB_D_I[74]),
      .Tile_X4Y1_RAM2FAB_D2_I3(RAM2FAB_D_I[75]),
      .Tile_X4Y1_RAM2FAB_D3_I0(RAM2FAB_D_I[76]),
      .Tile_X4Y1_RAM2FAB_D3_I1(RAM2FAB_D_I[77]),
      .Tile_X4Y1_RAM2FAB_D3_I2(RAM2FAB_D_I[78]),
      .Tile_X4Y1_RAM2FAB_D3_I3(RAM2FAB_D_I[79]),
      .Tile_X0Y5_B_T_top(T_top[0]),
      .Tile_X0Y5_A_T_top(T_top[1]),
      .Tile_X0Y4_B_T_top(T_top[2]),
      .Tile_X0Y4_A_T_top(T_top[3]),
      .Tile_X0Y3_B_T_top(T_top[4]),
      .Tile_X0Y3_A_T_top(T_top[5]),
      .Tile_X0Y2_B_T_top(T_top[6]),
      .Tile_X0Y2_A_T_top(T_top[7]),
      .Tile_X0Y1_B_T_top(T_top[8]),
      .Tile_X0Y1_A_T_top(T_top[9]),
      .UserCLK(CLK),
      .FrameData(FrameData),
      .FrameStrobe(FrameSelect)
  );


  BlockRAM_1KB Inst_BlockRAM_0 (
      .clk(CLK),
      .rd_addr(FAB2RAM_A_O[7:0]),
      .rd_data(RAM2FAB_D_I[31:0]),
      .wr_addr(FAB2RAM_A_O[15:8]),
      .wr_data(FAB2RAM_D_O[31:0]),
      .C0(FAB2RAM_C_O[0]),
      .C1(FAB2RAM_C_O[1]),
      .C2(FAB2RAM_C_O[2]),
      .C3(FAB2RAM_C_O[3]),
      .C4(FAB2RAM_C_O[4]),
      .C5(FAB2RAM_C_O[5])
  );

  BlockRAM_1KB Inst_BlockRAM_1 (
      .clk(CLK),
      .rd_addr(FAB2RAM_A_O[27:20]),
      .rd_data(RAM2FAB_D_I[71:40]),
      .wr_addr(FAB2RAM_A_O[35:28]),
      .wr_data(FAB2RAM_D_O[71:40]),
      .C0(FAB2RAM_C_O[10]),
      .C1(FAB2RAM_C_O[11]),
      .C2(FAB2RAM_C_O[12]),
      .C3(FAB2RAM_C_O[13]),
      .C4(FAB2RAM_C_O[14]),
      .C5(FAB2RAM_C_O[15])
  );

  assign FrameData = {32'h12345678, FrameRegister, 32'h12345678};
endmodule
