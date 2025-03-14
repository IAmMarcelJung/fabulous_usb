module prim_ram_2p #(
    parameter Width           = 32,    // Data width (32 bits)
    parameter Depth           = 1024,  // Depth of the memory
    parameter DataBitsPerMask = 8,     // Write mask width
    parameter MemInitFile     = ""     // Memory initialization file (optional)
) (
    input wire clk_a_i,  // Clock for port A
    input wire clk_b_i,  // Clock for port B
    input wire cfg_i,    // Configuration input (unused in this example)

    // Port A (Write/Read)
    input  wire               a_req_i,    // Port A request
    input  wire               a_write_i,  // Write enable for port A
    input  wire [       31:0] a_addr_i,   // Address for port A
    input  wire [  Width-1:0] a_wdata_i,  // Write data for port A
    input  wire [Width/8-1:0] a_wmask_i,  // Write mask for port A
    output reg  [  Width-1:0] a_rdata_o,  // Read data from port A

    // Port B (Write/Read)
    input  wire               b_req_i,    // Port B request
    input  wire               b_write_i,  // Write enable for port B
    input  wire [       31:0] b_addr_i,   // Address for port B
    input  wire [  Width-1:0] b_wdata_i,  // Write data for port B
    input  wire [Width/8-1:0] b_wmask_i,  // Write mask for port B
    output reg  [  Width-1:0] b_rdata_o   // Read data from port B
);

    // Internal memory for the BRAM
    reg [Width-1:0] ram[0:Depth-1];  // Dual-port memory (Width x Depth)

    // Memory initialization (optional)
    initial begin
        if (MemInitFile != "") begin
            $readmemh(MemInitFile, ram);  // Initialize memory with a hex file
        end
    end

    // Port A read/write operations
    always @(posedge clk_a_i) begin
        if (a_req_i) begin
            if (a_write_i) begin
                // Write operation for Port A
                ram[a_addr_i] <= (a_wdata_i & a_wmask_i) | (ram[a_addr_i] & ~a_wmask_i);
            end
            // Read operation for Port A
            a_rdata_o <= ram[a_addr_i];
        end
    end

    // Port B read/write operations
    always @(posedge clk_b_i) begin
        if (b_req_i) begin
            if (b_write_i) begin
                // Write operation for Port B
                ram[b_addr_i] <= (b_wdata_i & b_wmask_i) | (ram[b_addr_i] & ~b_wmask_i);
            end
            // Read operation for Port B
            b_rdata_o <= ram[b_addr_i];
        end
    end

endmodule
