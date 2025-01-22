`timescale 1ps / 1ps
`include "constants.vh"
module tap #(
    parameter bsregInLen  = 4,
    parameter bsregOutLen = 4
) (
    input                    tck,
    tms,
    tdi,
    input                    trst,
    output                   tdo,
    input  [ bsregInLen-1:0] pins_in,
    output [bsregOutLen-1:0] pins_out,
    input  [bsregOutLen-1:0] logic_pins_out,
    output [ bsregInLen-1:0] logic_pins_in,
    output                   active,
    config_strobe,
    output [           31:0] config_data
);
    wire [                    3:0] tstate;
    wire                           reset;
    wire                           tselect;
    wire                           enable;
    wire                           clkIR;
    wire                           shiftIR;
    // verilator lint_off UNUSEDSIGNAL
    wire                           captureIR;
    wire                           updateIR;
    // verilator lint_off UNUSEDSIGNAL
    wire                           clkDR;
    wire                           captureDR;
    wire                           shiftDR;
    wire                           updateDR;

    wire [       `IREG_LENGTH-1:0] IRdata_pin;
    wire [`INSTRUCTION_LENGTH-1:0] IRout;
    wire                           IRtdi;
    wire                           ir_tdo_mux;

    wire shiftBSR, updateBSR, BSRIntdo;
    wire bsrInEnableIn, bsrInEnableOut, bsrInMode, BSRIntdi;
    wire bsrOutEnableIn, bsrOutEnableOut, bsrOutMode;
    wire BSROuttdi, BSROuttdo;

    wire shiftBP, captureBP, BPdataOut;
    wire BPdataIn;
    wire shiftID, idOut;
    wire drTdoMux;

    wire clkConfig, dataInConfig, configFinished, strobeConfig, jtagActive;
    reg         resetConfig;
    wire [31:0] dataOutConfig;


    tap_controller tap_controller_I (
        .clk      (tck),
        .tms      (tms),
        .trst     (trst),
        .tstate   (tstate),
        .reset    (reset),
        .tselect  (tselect),
        .enable   (enable),
        .clkIR    (clkIR),
        .captureIR(captureIR),
        .shiftIR  (shiftIR),
        .updateIR (updateIR),
        .clkDR    (clkDR),
        .captureDR(captureDR),
        .shiftDR  (shiftDR),
        .updateDR (updateDR)
    );

    assign IRdata_pin[`IREG_LENGTH-1:1] = 0;
    assign IRdata_pin[0]                = 1'b1;
    instruction_register #(
        .REG_LEN  (`IREG_LENGTH),
        .INSTR_NUM(`INSTRUCTION_LENGTH)
    ) ir_I (
        .clkIR  (clkIR),
        .upIR   (updateIR),
        .shIR   (shiftIR),
        .piData (IRdata_pin),
        .tdi    (IRtdi),
        .reset  (reset),
        .instrB (IRout),
        .tdo_mux(ir_tdo_mux),
        .state  (tstate)
    );

    boundary_scan_register #(
        .LEN(bsregInLen)
    ) bsr_in (
        .tck      (tck),
        .reset    (reset),
        .enableIn (bsrInEnableIn),
        .enableOut(bsrInEnableOut),
        .mode     (bsrInMode),
        .clkDR    (clkDR),
        .shiftDR  (shiftBSR),
        .updateDR (updateBSR),
        .data_pin (pins_in),
        .tdi      (BSRIntdi),
        .tdo      (BSRIntdo),
        .data_pout(logic_pins_in)
    );

    boundary_scan_register #(
        .LEN(bsregOutLen)
    ) bsr_out (
        .tck      (tck),
        .reset    (reset),
        .enableIn (bsrOutEnableIn),
        .enableOut(bsrOutEnableOut),
        .mode     (bsrOutMode),
        .clkDR    (clkDR),
        .shiftDR  (shiftBSR),
        .updateDR (updateBSR),
        .data_pin (logic_pins_out),
        .tdi      (BSRIntdo),
        .tdo      (BSROuttdo),
        .data_pout(pins_out)
    );

    bypass_register reg_bypass_I (
        .data_in (BPdataIn),
        .shiftDR (shiftBP),
        .clkDR   (clkDR),
        .data_out(BPdataOut)
    );

    id_register reg_id_I (
        .clkDR   (clkDR),
        .shiftDR (shiftID),
        .data_out(idOut)
    );

    assign active        = jtagActive;
    assign config_data   = dataOutConfig;
    assign config_strobe = strobeConfig;
    jtag_config config_I (
        .clk     (clkConfig),
        .reset   (resetConfig),
        .data_in (dataInConfig),
        .finished(configFinished),
        .data_out(dataOutConfig),
        .strobe  (strobeConfig)
    );

    assign shiftBSR = (IRout == `SAMPLE_PRELOAD_INSTR | IRout == `EXTEST_INSTR |
                       IRout == `INTEST_INSTR) ? shiftDR : 1'b1;
    assign updateBSR = (IRout == `SAMPLE_PRELOAD_INSTR | IRout == `EXTEST_INSTR |
                        IRout == `INTEST_INSTR) ? updateDR : 1'b1;

    assign shiftBP = (IRout == `BYPASS_INSTR) ? shiftDR : 1'b1;
    assign captureBP = (IRout == `BYPASS_INSTR) ? captureDR : 1'b1;

    assign shiftID = (IRout == `IDCODE_INSTR) ? shiftDR : 1'b1;

    assign jtagActive = (configFinished == 1'b0 & tstate == `IDLE_C & IRout == `PROGRAM_INSTR) ?
        1'b1 : 1'b0;
    assign clkConfig = (IRout == `PROGRAM_INSTR & tstate == `IDLE_C) ? tck : 1'b1;
    assign dataInConfig = (IRout == `PROGRAM_INSTR) ? tdi : 1'b1;

    always @(*) begin
        if (~trst | tstate == `SELDR_C) resetConfig = 1'b0;
        else resetConfig = 1'b1;
    end

    // tdo mux
    assign tdo = (enable == 1'b1 & tselect == 1'b1) ?
        ir_tdo_mux : (enable == 1'b1 & tselect == 1'b0) ? drTdoMux : 1'b0;

    assign IRtdi = (tselect == 1'b1) ? tdi : 1'b0;

    assign BPdataIn = (tselect == 1'b0 & IRout == `BYPASS_INSTR) ? tdi : 1'b0;
    assign BSRIntdi = (tselect == 1'b0 & (IRout == `SAMPLE_PRELOAD_INSTR | IRout == `EXTEST_INSTR |
                                          IRout == `INTEST_INSTR)) ? tdi : 1'b0;

    assign drTdoMux = (tselect == 1'b0 & IRout == `BYPASS_INSTR) ?
        BPdataOut : (tselect == 1'b0 & IRout == `IDCODE_INSTR) ?
        idOut : (tselect == 1'b0 & (IRout == `SAMPLE_PRELOAD_INSTR | IRout == `EXTEST_INSTR |
                                    IRout == `INTEST_INSTR)) ? BSROuttdo : 1'b0;

    assign bsrInMode = (tselect == 1'b0 & (IRout == `BYPASS_INSTR | IRout == `IDCODE_INSTR |
                                           IRout == `SAMPLE_PRELOAD_INSTR)) ?
        1'b0 : (tselect == 1'b0 & (IRout == `EXTEST_INSTR | IRout == `INTEST_INSTR)) ? 1'b1 : 1'b0;

    assign bsrOutMode = (tselect == 1'b0 & (IRout == `BYPASS_INSTR | IRout == `IDCODE_INSTR |
                                            IRout == `SAMPLE_PRELOAD_INSTR)) ?
        1'b0 : (tselect == 1'b0 & (IRout == `EXTEST_INSTR | IRout == `INTEST_INSTR)) ? 1'b1 : 1'b0;

    assign bsrInEnableIn =
        (tselect == 1'b0 & (IRout == `BYPASS_INSTR | IRout == `IDCODE_INSTR |
                            IRout == `SAMPLE_PRELOAD_INSTR | IRout == `EXTEST_INSTR)) ?
        1'b1 : (tselect == 1'b0 & IRout == `INTEST_INSTR) ? 1'b0 : 1'b1;

    assign bsrInEnableOut =
        (tselect == 1'b0 & (IRout == `BYPASS_INSTR | IRout == `IDCODE_INSTR |
                            IRout == `SAMPLE_PRELOAD_INSTR | IRout == `INTEST_INSTR)) ?
        1'b1 : (tselect == 1'b0 & IRout == `EXTEST_INSTR) ? 1'b0 : 1'b1;

    assign bsrOutEnableIn =
        (tselect == 1'b0 & (IRout == `BYPASS_INSTR | IRout == `IDCODE_INSTR |
                            IRout == `SAMPLE_PRELOAD_INSTR | IRout == `INTEST_INSTR)) ?
        1'b1 : (tselect == 1'b0 & IRout == `EXTEST_INSTR) ? 1'b0 : 1'b1;

    assign bsrOutEnableOut = (tselect == 1'b0 & (IRout == `BYPASS_INSTR | IRout == `IDCODE_INSTR |
                                                 IRout == `SAMPLE_PRELOAD_INSTR |
                                                 IRout == `EXTEST_INSTR | IRout == `INTEST_INSTR)) ?
        1'b1 : 1'b1;

endmodule

