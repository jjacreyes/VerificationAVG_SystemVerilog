`timescale 1ns / 1ps
// base_test.sv
// The base_test is the top-level verification class that orchestrates a simulation run. 
// It builds and configures the environment, starts stimulus, and defines common tools used for all derived tests.
//
// Its responsibilities typically include:
//  - Build & connect the environment (driver/monitor/scoreboard) and pass virtual interfaces.
//  - Configure settings for each verification component.
//  - Start stimulus (choose a generator/sequence) and manage run-time.

class base_test;
    parameter int unsigned DATA_WIDTH = 16;
    parameter int unsigned ADDR_WIDTH = 10;
    parameter int unsigned BRAM_DEPTH = 1 << ADDR_WIDTH;
    parameter int unsigned WINDOW_SIZE = 8;

    driver     #(.DATA_WIDTH(DATA_WIDTH)) m_driver;
    monitor    #(.DATA_WIDTH(DATA_WIDTH)) m_monitor;
    scoreboard #(.DATA_WIDTH(DATA_WIDTH)) m_scoreboard;

    mailbox                               driver2scoreboard_mailbox;
    mailbox                               monitor2scoreboard_mailbox;
    event                                 scoreboard_done;

    virtual dut_if                        vif;

    int                                   m_test_num;

    // Constructor function, performs some setup for the testbench environment
    function new(input int test_num = 0);
        // Create the main environment component objects
        m_driver     = new(.test_num(test_num));
        m_monitor    = new(.test_num(test_num));
        m_scoreboard = new(.test_num(test_num));

        // Create mailbox objects to pass data between testbench components
        // Mailboxes are like FIFOs that can pass any data between classes. 
        // In this case, we use them to pass transactions and samples to the scoreboard.
        driver2scoreboard_mailbox   = new();
        monitor2scoreboard_mailbox  = new();

        // Connect mailboxes (basically make the variables refer to the same object)
        m_driver.driver2scoreboard_mailbox      = driver2scoreboard_mailbox;
        m_scoreboard.driver2scoreboard_mailbox  = driver2scoreboard_mailbox;

        m_monitor.monitor2scoreboard_mailbox    = monitor2scoreboard_mailbox;
        m_scoreboard.monitor2scoreboard_mailbox = monitor2scoreboard_mailbox;

        // This event triggers when the scoreboard is done checking all results
        scoreboard_done  = m_scoreboard.done;

        m_test_num  = test_num;

    endfunction

    // Task to encapsulate the design reset process
    task automatic reset_design();
        // set reset/start values
        vif.cb.i_rst   <= 1;
        vif.cb.i_start <= 0;

        // Hold reset for a few cycles and then deassert
        repeat (10) @(vif.cb);
        vif.cb.i_rst <= 0;

    endtask

    // Task to encapsulate the design start process
    task automatic assert_start();

        // Wait a few cycles, then assert start
        repeat (5) @(vif.cb);
        vif.cb.i_start <= 1;

    endtask

    // Main test procedure.
    task run();
        // Pass virtual interfaces to driver and monitor
        m_driver.vif     = vif;
        m_monitor.vif    = vif;
        m_scoreboard.vif = vif;

        // At this point, simulation is at time 0.
        $display("T=%0t [base_test] Applying Reset", $time);

        reset_design();

        $display("T=%0t [base_test] Starting Test", $time);

        // Choose a test case to run
        case (m_test_num)
            // TESTCASE 0 : Drive the BRAM signals from the testbench
            0: begin

                // Set the start signal from the testbench
                assert_start();

                // Start driver, monitor, and scoreboard.
                // The "fork...join_any" construct allows these tasks to run concurrently 
                // (i.e., all 4 lines between the fork...join_any execute at the same time).
                fork
                    m_driver.run();
                    m_monitor.run();
                    m_scoreboard.run();
                    @(scoreboard_done);
                join_any
            end

            // TESTCASE 1 : Let the DUT drive the BRAM signals
            // TODO: write testcase...


            // Default case for unimplemented tests
            default: begin
                $display("ERROR: unimplemented test number %0d!", m_test_num);
                $finish;
            end
        endcase

        report();

        // End of simulation
        $finish;
    endtask


    task automatic report();
        if (m_scoreboard.m_errors == 0) begin
            $display("T=%0t [base_test] ================ TEST PASSED ================", $time);
        end else begin
            $display("T=%0t [base_test] ================ TEST FAILED ================", $time);
        end
    endtask



endclass

