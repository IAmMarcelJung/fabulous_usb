`timescale 1ps / 1ps

module tap_controller (
    input            clk,
    tms,
    trst,
    output reg [3:0] tstate,
    output reg       enable,   // enables output via tdo
    tselect,  // selects data register (0) or instruction register (1)
    captureIR,
    shiftIR,
    captureDR,
    shiftDR,
    clkIR,
    clkDR,
    output           resetn_o,
    updateIR,
    updateDR
);

    // JTAG States
    localparam [3:0] TLRESET = 4'h0;
    localparam [3:0] IDLE = 4'h1;
    localparam [3:0] SELDR = 4'h2;
    localparam [3:0] CAPDR = 4'h3;
    localparam [3:0] SHDR = 4'h4;
    localparam [3:0] EX1DR = 4'h5;
    localparam [3:0] PDR = 4'h6;
    localparam [3:0] EX2DR = 4'h7;
    localparam [3:0] UPDR = 4'h8;
    localparam [3:0] SELIR = 4'h9;
    localparam [3:0] CAPIR = 4'ha;
    localparam [3:0] SHIR = 4'hb;
    localparam [3:0] EX1IR = 4'hc;
    localparam [3:0] PIR = 4'hd;
    localparam [3:0] EX2IR = 4'he;
    localparam [3:0] UPIR = 4'hf;

    localparam [3:0] TLRESET_C = 4'hF;
    localparam [3:0] IDLE_C = 4'hC;
    localparam [3:0] SELDR_C = 4'h7;
    localparam [3:0] CAPDR_C = 4'h6;
    localparam [3:0] SHDR_C = 4'h2;
    localparam [3:0] EX1DR_C = 4'h1;
    localparam [3:0] PDR_C = 4'h3;
    localparam [3:0] EX2DR_C = 4'h0;
    localparam [3:0] UPDR_C = 4'h5;
    localparam [3:0] SELIR_C = 4'h4;
    localparam [3:0] CAPIR_C = 4'hE;
    localparam [3:0] SHIR_C = 4'hA;
    localparam [3:0] EX1IR_C = 4'h9;
    localparam [3:0] PIR_C = 4'hB;
    localparam [3:0] EX2IR_C = 4'h8;
    localparam [3:0] UPIR_C = 4'hD;

    reg [3:0] state_current;
    reg [3:0] state_next;

    always @(*) begin
        if (tms == 1'b0) begin
            case (state_current)
                TLRESET: state_next = IDLE;
                IDLE:    state_next = IDLE;
                SELDR:   state_next = CAPDR;
                CAPDR:   state_next = SHDR;
                SHDR:    state_next = SHDR;
                EX1DR:   state_next = PDR;
                PDR:     state_next = PDR;
                EX2DR:   state_next = SHDR;
                UPDR:    state_next = IDLE;
                SELIR:   state_next = CAPIR;
                CAPIR:   state_next = SHIR;
                SHIR:    state_next = SHIR;
                EX1IR:   state_next = PIR;
                PIR:     state_next = PIR;
                EX2IR:   state_next = SHIR;
                UPIR:    state_next = IDLE;
                default: state_next = TLRESET;
            endcase
        end else if (tms == 1'b1) begin
            case (state_current)
                TLRESET: state_next = TLRESET;
                IDLE:    state_next = SELDR;
                SELDR:   state_next = SELIR;
                CAPDR:   state_next = EX1DR;
                SHDR:    state_next = EX1DR;
                EX1DR:   state_next = UPDR;
                PDR:     state_next = EX2DR;
                EX2DR:   state_next = UPDR;
                UPDR:    state_next = SELDR;
                SELIR:   state_next = TLRESET;
                CAPIR:   state_next = EX1IR;
                SHIR:    state_next = EX1IR;
                EX1IR:   state_next = UPIR;
                PIR:     state_next = EX2IR;
                EX2IR:   state_next = UPIR;
                UPIR:    state_next = SELDR;
                default: state_next = TLRESET;
            endcase
        end else state_next = state_current;
    end

    always @(*) begin
        case (state_current)
            TLRESET: tstate = TLRESET_C;
            IDLE:    tstate = IDLE_C;
            SELDR:   tstate = SELDR_C;
            CAPDR:   tstate = CAPDR_C;
            SHDR:    tstate = SHDR_C;
            EX1DR:   tstate = EX1DR_C;
            PDR:     tstate = PDR_C;
            EX2DR:   tstate = EX2DR_C;
            UPDR:    tstate = UPDR_C;
            SELIR:   tstate = SELIR_C;
            CAPIR:   tstate = CAPIR_C;
            SHIR:    tstate = SHIR_C;
            EX1IR:   tstate = EX1IR_C;
            PIR:     tstate = PIR_C;
            EX2IR:   tstate = EX2IR_C;
            UPIR:    tstate = UPIR_C;
            default: tstate = TLRESET_C;
        endcase
    end

    assign updateIR = (state_current == UPIR & clk == 1'b0) ? 1'b1 : 1'b0;
    assign updateDR = (state_current == UPDR & clk == 1'b0) ? 1'b1 : 1'b0;

    always @(posedge clk, negedge trst) begin
        // global reset
        if (trst == 1'b0) begin
            state_current <= TLRESET;
        end else begin
            state_current <= state_next;
        end
    end

    assign resetn_o = (state_current == TLRESET) ? 1'b0 : trst;

    always @(negedge clk) begin
        case (state_current)
            CAPIR:   {captureIR, shiftIR, captureDR, shiftDR} <= 4'b1000;
            SHIR:    {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0100;
            CAPDR:   {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0010;
            SHDR:    {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0001;
            default: {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0000;
        endcase

    end
    always @(negedge clk) begin
        if (state_current == SHIR | state_current == SHDR) enable <= 1'b1;
        else enable <= 1'b0;
    end

    always @(posedge clk) begin
        if (tstate[3] == 1'b1) tselect <= 1'b1;
        else tselect <= 1'b0;
    end

    always @(posedge clk) begin
        if (state_current == SHIR | state_current == CAPIR) clkIR <= clk;
        else clkIR <= 1'b1;
    end

    always @(posedge clk) begin
        if (state_current == SHDR | state_current == CAPDR) clkDR <= clk;
        else clkDR <= 1'b1;
    end
endmodule


