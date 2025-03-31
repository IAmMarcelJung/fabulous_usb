module prim_ram_2p #(
    parameter Width           = 32,    // Data width (32 bits)
    parameter Depth           = 1024,  // Depth of the memory
    parameter DataBitsPerMask = 8,     // Write mask granularity
    parameter MemInitFile     = ""     // Memory initialization file
) (
    input  wire                             clk_a_i,
    input  wire                             clk_b_i,
    input  wire                             cfg_i,
    // Port A (Write/Read)
    input  wire                             a_req_i,
    input  wire                             a_write_i,
    input  wire [        $clog2(Depth)-1:0] a_addr_i,   // Correct address width
    input  wire [                Width-1:0] a_wdata_i,
    input  wire [Width/DataBitsPerMask-1:0] a_wmask_i,  // Proper mask width
    output reg  [                Width-1:0] a_rdata_o,
    // Port B (Write/Read)
    input  wire                             b_req_i,
    input  wire                             b_write_i,
    input  wire [        $clog2(Depth)-1:0] b_addr_i,   // Correct address width
    input  wire [                Width-1:0] b_wdata_i,
    input  wire [Width/DataBitsPerMask-1:0] b_wmask_i,  // Proper mask width
    output reg  [                Width-1:0] b_rdata_o
);
    // Internal memory for the BRAM
    reg [Width-1:0] ram[0:Depth-1];

    // Memory initialization
    initial begin
        if (MemInitFile != "") begin
            $readmemh(MemInitFile, ram);
        end
    end

    // Port A operations
    always @(posedge clk_a_i) begin
        if (a_req_i) begin
            if (a_write_i) begin
                // Handle byte-wise masking
                // This implementation assumes DataBitsPerMask=8 for a 32-bit word
                // with 4 bytes that can be individually masked
                if (a_wmask_i[0]) ram[a_addr_i][7:0] <= a_wdata_i[7:0];
                if (a_wmask_i[1]) ram[a_addr_i][15:8] <= a_wdata_i[15:8];
                if (a_wmask_i[2]) ram[a_addr_i][23:16] <= a_wdata_i[23:16];
                if (a_wmask_i[3]) ram[a_addr_i][31:24] <= a_wdata_i[31:24];
            end else begin
                // Read operation
                a_rdata_o <= ram[a_addr_i];
            end
        end
    end

    // Port B operations
    always @(posedge clk_b_i) begin
        if (b_req_i) begin
            if (b_write_i) begin
                // Handle byte-wise masking
                if (b_wmask_i[0]) ram[b_addr_i][7:0] <= b_wdata_i[7:0];
                if (b_wmask_i[1]) ram[b_addr_i][15:8] <= b_wdata_i[15:8];
                if (b_wmask_i[2]) ram[b_addr_i][23:16] <= b_wdata_i[23:16];
                if (b_wmask_i[3]) ram[b_addr_i][31:24] <= b_wdata_i[31:24];
            end else begin
                // Read operation
                b_rdata_o <= ram[b_addr_i];
            end
        end
    end
endmodule


