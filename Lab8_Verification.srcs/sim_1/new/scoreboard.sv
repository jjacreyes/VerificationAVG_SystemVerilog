// scoreboard.sv
// The scoreboard compares monitored results against a trusted reference (golden) model/predicted outcomes. It flags mismatches and reports pass/fail.
// It should be independent of the DUT implementation as much as possible.

class scoreboard #(
    parameter int unsigned DATA_WIDTH  = 16,
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned BRAM_DEPTH  = 1 << ADDR_WIDTH,
    parameter int unsigned WINDOW_SIZE = 8
);

    virtual dut_if vif;
    mailbox monitor2scoreboard_mailbox;  // from monitor: actual outputs from the DUT
    mailbox driver2scoreboard_mailbox;  // from generator: the frame to compute golden reference
    int m_errors;
    int m_test_num;
    data_frame m_frame;
    event done;

    function new(input int test_num = 0);
        m_errors   = 0;
        m_test_num = test_num;
    endfunction

    // Golden reference for calculating an 8-point moving average
    function automatic logic [15:0] avg(const ref logic [15:0] data[], int idx);
        logic [31:0] sum = 0;
        for (int i = 0; i < 8; i++) sum += data[idx+i];

        return sum / 8;
    endfunction

    // Retrieve a string representation of the current 8-point window for debug printing
    function automatic string sample_window_values(const ref logic [15:0] data[], int idx);
        string temp = "";
        for (int i = 0; i < 8; i++) temp = {temp, $sformatf("%0d, ", data[idx+i])};

        return temp.substr(0, temp.len() - 3);
    endfunction

    // Retrieve a string representation of the BRAM addresses for the current 8-point window for debug printing
    function automatic string sample_window_addresses(int idx);
        string temp = "";
        for (int i = 0; i < 8; i++) temp = {temp, $sformatf("%0d, ", idx + i)};

        return temp.substr(0, temp.len() - 3);
    endfunction

    // Main test procedure.
    task run();
        int          expected_cnt;
        int          out_idx;
        logic [15:0] got;
        logic [15:0] exp;

        // Get the data information from the driver
        driver2scoreboard_mailbox.get(m_frame);
        m_frame.print("[SCB]");

        // Calculate expected number of outputs
        expected_cnt = m_frame.depth - m_frame.wsize + 1;
        out_idx      = 0;

        $display("T=%0t [SCB] Expecting %0d outputs", $time, expected_cnt);

        // Compare streamed outputs against golden sequence
        while (out_idx < expected_cnt) begin
            monitor2scoreboard_mailbox.get(got);  // Get valid data from monitor          

            // Calculate true expected value
            exp = avg(m_frame.data, out_idx);

            // Drive the debug signal for waveform debugging.
            // Default to 0, set to 1 on mismatch
            vif.output_mismatch <= 0;

            // Compare
            if (got !== exp) begin
                $display("T=%0t [SCB] MISMATCH @%0d: got %0d, expected %0d for values: %s from BRAM addresses: ",
                    $time, out_idx, got, exp, sample_window_values(m_frame.data, out_idx), sample_window_addresses(out_idx));
                m_errors++;
                vif.output_mismatch <= 1;  // Toggle output_mismatch signal for waveform debug

            end else begin
                $display("T=%0t [SCB] CORRECT @%0d: got %0d, expected %0d for values: %s from BRAM addresses: ",
                    $time, out_idx, got, exp, sample_window_values(m_frame.data, out_idx), sample_window_addresses(out_idx));
            end

            out_idx++;
        end

        $display("T=%0t [SCB] Done. Number of Errors=%0d", $time, m_errors);

        // Signal that checking is done.
        ->done;
    endtask
endclass

