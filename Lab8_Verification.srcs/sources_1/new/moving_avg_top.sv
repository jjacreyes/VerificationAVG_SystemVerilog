`timescale 1ns / 1ps

module moving_avg_top (
    input wire i_sys_clk,
    input wire i_sys_rst,
    input wire i_start
);

    parameter int unsigned ADDR_WIDTH = 9;
    parameter int unsigned DATA_WIDTH = 16;
    parameter int unsigned WINDOW_SIZE = 8;

    logic [ADDR_WIDTH-1:0] o_bram_addr;
    logic                  o_bram_en;
    logic [DATA_WIDTH-1:0] i_bram_data;
    logic [DATA_WIDTH-1:0] o_data;
    logic                  o_valid;

    logic                  clk, rst;
    logic                  locked;
    logic                  start_db;
    

    // Clock generator
    clk_wiz_0 clk_gen (
        .clk_in1(i_sys_clk),
        .reset(i_sys_rst),
        .locked(locked),
        .clk_out1(clk)
    );

    proc_sys_reset_0 rst_gen
    (
      .slowest_sync_clk(clk),
      .ext_reset_in(i_sys_rst),
      .aux_reset_in('0),
      .mb_debug_sys_rst('0),
      .dcm_locked(locked),    
      .mb_reset(),
      .bus_struct_reset(),
      .peripheral_reset(rst),
      .interconnect_aresetn(), 
      .peripheral_aresetn() 
    );

    // Debouncer for start signal
    debouncer btn_db (
        .i_clk(clk),
        .i_rst(rst),
        .i_btn_in(i_start),
        .o_btn_out(start_db)
    );

    // Memory Block RAM (BRAM) instance
    mem #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) bram (
        .i_clk(clk),
        .i_rst(rst),
        .i_addr(o_bram_addr),
        .i_wr_en('b0),
        .i_rd_en(o_bram_en),
        .i_wr_data('d0),
        .o_rd_data(i_bram_data)
    );

    // Moving average core instance
    moving_avg #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .WINDOW_SIZE(WINDOW_SIZE)
    ) moving_avg_core (
        .i_clk  (clk),
        .i_rst  (rst),
        .i_start(start_db),

        .o_bram_addr(o_bram_addr),
        .o_bram_en  (o_bram_en),
        .i_bram_data(i_bram_data),

        .o_data (o_data),
        .o_valid(o_valid)
    );


endmodule
