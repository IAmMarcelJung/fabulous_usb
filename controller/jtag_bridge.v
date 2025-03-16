module jtag_bridge (
    input  wire       clk_i,
    input  wire       rst_n_i,
    input  wire [7:0] from_usb_data_i,
    input  wire       from_usb_valid_i,
    output reg        from_usb_ready_o,
    output reg        tck_o,
    output reg        tms_o,
    output reg        tdi_o,
    output reg        trst_o,
    output reg        srst_o,
    input  wire       tdo_i,
    output reg  [7:0] to_usb_data_o,
    output reg        to_usb_valid_o,
    input  wire       to_usb_ready_i,
    output reg        bitbang_led_o
);

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            tck_o            <= 1'b0;
            tms_o            <= 1'b0;
            tdi_o            <= 1'b0;
            trst_o           <= 1'b0;
            srst_o           <= 1'b0;
            bitbang_led_o    <= 1'b0;
            to_usb_valid_o   <= 1'b0;
            to_usb_data_o    <= 8'b0;
            from_usb_ready_o <= 1'b0;
        end else if (from_usb_valid_i) begin
            to_usb_valid_o   <= 1'b0;
            from_usb_ready_o <= 1'b1;
            case (from_usb_data_i)
                "B": bitbang_led_o <= 1'b1;  // Blink ON
                "b": bitbang_led_o <= 1'b0;  // Blink OFF

                "R": begin
                    if (to_usb_ready_i) begin
                        to_usb_data_o  <= tdo_i ? "1" : "0";
                        to_usb_valid_o <= 1'b1;
                    end
                end

                "0": {tck_o, tms_o, tdi_o} <= 3'b000;
                "1": {tck_o, tms_o, tdi_o} <= 3'b001;
                "2": {tck_o, tms_o, tdi_o} <= 3'b010;
                "3": {tck_o, tms_o, tdi_o} <= 3'b011;
                "4": {tck_o, tms_o, tdi_o} <= 3'b100;
                "5": {tck_o, tms_o, tdi_o} <= 3'b101;
                "6": {tck_o, tms_o, tdi_o} <= 3'b110;
                "7": {tck_o, tms_o, tdi_o} <= 3'b111;
                "r": {trst_o, srst_o} <= 2'b00;
                "s": {trst_o, srst_o} <= 2'b01;
                "t": {trst_o, srst_o} <= 2'b10;
                "u": {trst_o, srst_o} <= 2'b11;
                default: begin
                    tck_o            <= tck_o;
                    tms_o            <= tms_o;
                    tdi_o            <= tdi_o;
                    trst_o           <= trst_o;
                    srst_o           <= srst_o;
                    bitbang_led_o    <= bitbang_led_o;
                    to_usb_data_o    <= to_usb_data_o;
                    to_usb_valid_o   <= 1'b0;
                    from_usb_ready_o <= 1'b1;
                end
            endcase
        end
    end
endmodule
