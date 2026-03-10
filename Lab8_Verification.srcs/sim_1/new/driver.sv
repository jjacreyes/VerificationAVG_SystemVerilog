// driver.sv
// Generates stimulus: it converts high-level transation (e.g., packets, samples) into pin-level activity on the DUT while obeying 
// protocol timing and handshakes. Good drivers are configurable (seeds/constraints) and respect back-pressure.

class driver #(
    parameter int unsigned DATA_WIDTH  = 16,
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned BRAM_DEPTH  = 1 << ADDR_WIDTH,
    parameter int unsigned WINDOW_SIZE = 8
);
    virtual dut_if                  vif;
    mailbox                         driver2scoreboard_mailbox;
    data_frame                      m_transaction;

    int                             m_test_num;

    function new(input int test_num = 0);
        m_test_num  = test_num;
    endfunction

    // Main test procedure.
    task run();
        $display("T=%0t [DRV] Starting driver...", $time);
        // Initialize bram_data signal to 0
        vif.cb.i_bram_data <= 0;

        // Generate a new data object
        $display("T=%0t [DRV] Creating new m_transaction object.", $time);
        m_transaction = new(.depth_i(BRAM_DEPTH), .wsize_i(WINDOW_SIZE), .test_num(m_test_num));
        m_transaction.print("[DRV]");

        // Send data object to scoreboard for checking.
        driver2scoreboard_mailbox.put(m_transaction);

        // Begin driver loop
        // Only one BRAM module (m_transaction) is modelled in this test.
        forever begin
            // Execute at every clock edge
            @(vif.cb);

            // Drive data with 1-cycle latency relative to bram_en
            if (vif.cb.o_bram_en) begin
                // Address presented this cycle -> data available next cycle
                vif.cb.i_bram_data <= m_transaction.data[vif.o_bram_addr];
            end

        end

    endtask
endclass
