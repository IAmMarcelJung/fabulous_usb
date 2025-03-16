module jtag_bridge (
    input  wire       clk,
    input  wire       rst_n_i,
    input  wire [7:0] usb_data,
    input  wire       usb_valid,
    output reg        usb_data_ready_o,
    output reg        tck,
    output reg        tms,
    output reg        tdi,
    output reg        trst,
    output reg        srst,
    input  wire       tdo,
    output wire       captured_tdo,
    output reg  [7:0] usb_out,
    output reg        usb_out_valid,
    input  wire       usb_out_ready_i,
    output reg        blink_led
);

    always @(posedge clk or negedge rst_n_i) begin
        if (!rst_n_i) begin
            tck              <= 0;
            tms              <= 0;
            tdi              <= 0;
            trst             <= 0;
            srst             <= 1'b0;
            blink_led        <= 0;
            usb_out_valid    <= 0;
            usb_out          <= 8'b0;
            usb_data_ready_o <= 1'b0;
        end else if (usb_valid) begin
            usb_out_valid    <= 0;
            usb_data_ready_o <= 1'b1;
            case (usb_data)
                "B": blink_led <= 1;  // Blink ON
                "b": blink_led <= 0;  // Blink OFF

                "R": begin
                    if (usb_out_ready_i) begin
                        usb_out       <= captured_tdo ? "1" : "0";  // Use synchronized TDO
                        usb_out_valid <= 1;
                    end
                end

                "0": {tck, tms, tdi} <= 3'b000;  // Write 0 0 0
                "1": {tck, tms, tdi} <= 3'b001;  // Write 0 0 1
                "2": {tck, tms, tdi} <= 3'b010;  // Write 0 1 0
                "3": {tck, tms, tdi} <= 3'b011;  // Write 0 1 1
                "4": {tck, tms, tdi} <= 3'b100;  // Write 1 0 0
                "5": {tck, tms, tdi} <= 3'b101;  // Write 1 0 1
                "6": {tck, tms, tdi} <= 3'b110;  // Write 1 1 0
                "7": {tck, tms, tdi} <= 3'b111;  // Write 1 1 1
                "r": {trst, srst} <= 2'b00;  // Reset 0 0
                "s": {trst, srst} <= 2'b01;  // Reset 0 1
                "t": {trst, srst} <= 2'b10;  // Reset 1 0
                "u": {trst, srst} <= 2'b11;  // Reset 1 1
                default: begin
                    tck              <= tck;
                    tms              <= tms;
                    tdi              <= tdi;
                    trst             <= trst;
                    srst             <= srst;
                    blink_led        <= blink_led;
                    usb_out          <= 8'b0;
                    usb_out_valid    <= 0;
                    usb_data_ready_o <= 1'b1;
                end
            endcase
        end
    end
endmodule
