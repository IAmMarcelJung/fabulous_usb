// This file is used so that the ibex demo system can be run out-of-conext and
// still does not have to be changed internally

module ibex_demo_wrapper #(
    parameter int                 GpiWidth       = 8,
    parameter int                 GpoWidth       = 4,
    parameter int                 PwmWidth       = 0,
    parameter int unsigned        ClockFrequency = 50_000_000,
    parameter int unsigned        BaudRate       = 115_200,
    parameter ibex_pkg::regfile_e RegFile        = ibex_pkg::RegFileFPGA,
    parameter                     SRAMInitFile   = ""
) (
    input logic clk_sys_i,
    input logic rst_sys_ni,

    input  logic [GpiWidth-1:0] gp_i,
    output logic [GpoWidth-1:0] gp_o,
    output logic [PwmWidth-1:0] pwm_o,
    input  logic                uart_rx_i,
    output logic                uart_tx_o,
    input  logic                spi_rx_i,
    output logic                spi_tx_o,
    output logic                spi_sck_o,

    input  logic tck_i,    // JTAG test clock pad
    input  logic tms_i,    // JTAG test mode select pad
    input  logic trst_ni,  // JTAG test reset pad
    input  logic td_i,     // JTAG test data input pad
    output logic td_o      // JTAG test data output pad
);
    ibex_demo_system #(
        .ClockFrequency(12_000_000),
        .GpiWidth      (GpiWidth),
        .GpoWidth      (GpoWidth),
        .PwmWidth      (PwmWidth),
        .BaudRate      (BaudRate),
        .RegFile       (RegFile),
        .SRAMInitFile  (SRAMInitFile)

    ) u_ibex_demo_system (
        //input
        .clk_sys_i (clk_sys_i),
        .rst_sys_ni(rst_sys_ni),
        .gp_i      (gp_i),
        .uart_rx_i(uart_rx_i),

        //output
        .gp_o (gp_o),
        .pwm_o(pwm_o),
        .uart_tx_o(uart_tx_o),

        .spi_rx_i (spi_rx_i),
        .spi_tx_o (spi_tx_o),
        .spi_sck_o(spi_sck_o),

        .trst_ni(trst_ni),
        .tms_i  (tms_i),
        .tck_i  (tck_i),
        .td_i   (td_i),
        .td_o   (td_o)
    );

endmodule
