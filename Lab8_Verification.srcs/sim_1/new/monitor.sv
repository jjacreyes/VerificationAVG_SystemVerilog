// monitor.sv
// The monitor passively observes the DUT interface, sampling signals (often via a clocking block) and reconstructing transactions. 
// It publishes what actually happened to the scoreboard/coverage. It does not drive anything into the DUT.

class monitor #(
    parameter int unsigned DATA_WIDTH  = 16,
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned BRAM_DEPTH  = 1 << ADDR_WIDTH,
    parameter int unsigned WINDOW_SIZE = 8
);
    virtual dut_if                  vif;
    mailbox                         monitor2scoreboard_mailbox;
    logic          [DATA_WIDTH-1:0] m_sample;
    int                             m_test_num;

    function new(input int test_num = 0);
        m_test_num = test_num;
        m_sample   = 0;
    endfunction

    // Main test procedure.
    task run();
        $display("T=%0t [MON] Starting monitor...", $time);

        // Begin monitor loop
        forever begin
            @(vif.cb);

            // If the DUT signals a valid output, sample out_data and send to scoreboard for checking
            if (vif.cb.o_valid) begin
                m_sample = vif.o_data;
                monitor2scoreboard_mailbox.put(m_sample);
            end
        end
    endtask

endclass

