`timescale 1ns / 1ps

// moving_avg_tb.sv
module moving_avg_tb;

    // Create the clock
    logic clk = 0;
    always #5 clk = ~clk;  // 100 MHz
    initial $timeformat(-9, 2, " ns", 20);

    // Helper debug signal to indicate when an output mismatch occurs
    logic output_mismatch;

    // Interface to connect to DUT
    dut_if m_if (clk);

    // Helpful debug signal that showns when a mismatch happens in the waveform view
    assign output_mismatch = m_if.output_mismatch;

    // Instantiate the moving average design and connect testbench interface signals
    moving_avg_top dut (
        .i_sys_clk(clk),
        .i_sys_rst(m_if.i_rst),
        .i_start  (m_if.i_start)
    );

    // Create the main test object
    test_pkg::base_test m_test;

    initial begin
        // The "force" keyword is used here to connect to internal signals in the DUT
        // This is useful for skipping modules or connecting to internal signals
        // Note that this is not synthesizable, but is fine for testbenches

        // Skip the clock_gen module, force a simulated clock
        force dut.clk = m_if.i_clk; 
        force dut.rst = m_if.i_rst;
        // Skip the debouncer module, force the debounced start signal for simulation
        force dut.start_db = m_if.i_start;

        // Connect BRAM signals to the test interface
        force m_if.o_bram_addr = dut.o_bram_addr;
        force m_if.o_bram_en = dut.o_bram_en;
        force dut.i_bram_data = m_if.i_bram_data;

        // Connect output of moving average to test interface
        force m_if.o_data = dut.o_data;
        force m_if.o_valid = dut.o_valid;

        // Create base_test object and assign interface
        m_test = new(.test_num(0));

        // Pass the interface to the test class (basically give it a reference to the interface object)
        m_test.vif = m_if;

        // Run the desired testcase
        m_test.run();

    end

    initial begin
        // Prevent runaway testcases.
        #(14 * 1us);
        $finish;
    end

endmodule
