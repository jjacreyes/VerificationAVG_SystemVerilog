`timescale 1ns / 1ps

// dut_if.sv
// A bundle of related signals (and often a clocking block + modports) that standardizes timing and connectivity between TB and DUT. 
// It reduces wiring, avoids race conditions, and enables reuse by passing a single virtual interface handle to drivers/monitors.
interface dut_if(input logic i_clk);
    // DUT pins
    logic         i_rst = 0;
    logic         i_start = 0;
    logic  [9:0]  o_bram_addr;
    logic         o_bram_en;
    logic  [15:0] i_bram_data = 0;
    logic  [15:0] o_data;
    logic         o_valid;


    // You can also drive testbench signals, which are not part of the DUT pins.
    // This is useful for adding debug information, such as showing when errors occur in the waveform.
    logic output_mismatch = 0;

    // Clocking block to avoid races/ambiguity on sampling
    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input  o_bram_addr, o_bram_en, o_data, o_valid;
        output i_rst, i_start, i_bram_data;
    endclocking


    // The opposite of the "force" command, "release" stops forcing a signal and returns it to normal operation.
    // For testcases that do not want to force data onto the bram_data signal, release the testbench's "force".
    // Use when you want the actual memory to drive the data, not the testbench.
    task automatic disable_bram_data_force();
        release $root.moving_avg_tb.dut.i_bram_data;
    endtask

endinterface
