module mem #(
    parameter ADDR_WIDTH = 10,    // Number of address bits
    parameter DATA_WIDTH = 16     // Data width
) (
    input  wire                   i_clk,
    input  wire                   i_rst,
    input  wire  [ADDR_WIDTH-1:0] i_addr,

    input  wire                   i_wr_en,    // Write enable
    input  wire                   i_rd_en,    // Read enable
    input  wire [DATA_WIDTH-1:0]  i_wr_data, // Data input
    output reg  [DATA_WIDTH-1:0]  o_rd_data  // Data output

);


endmodule
