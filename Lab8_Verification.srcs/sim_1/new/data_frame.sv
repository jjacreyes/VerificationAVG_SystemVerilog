// data_frame.sv
// A data_frame (or packet) is the testbench’s abstract unit of work: a self-contained object that represents one operation or sample that is independent of 
// pin-level timing. Drivers turn data_frames into signal activity; monitors reconstruct data_frames from the DUT; the scoreboard compares expected vs. observed 
// data_frames.

class data_frame #(
    parameter int unsigned DATA_WIDTH  = 16,
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned BRAM_DEPTH  = 1 << ADDR_WIDTH,
    parameter int unsigned WINDOW_SIZE = 8
);
    int unsigned depth;
    int unsigned wsize;
    rand logic [DATA_WIDTH-1:0] data[];

    function new(int depth_i = 0, int wsize_i = 0, int test_num = 0);
        depth = depth_i;
        wsize = wsize_i;
        data  = new[depth];

        // By default, the data is an array of random values between 10 and 1500
        // But this can be changed depending on the test case
        foreach (data[i]) data[i] = $urandom_range(10, 1500);
    endfunction

    function automatic void print(string tag="");
        // Prints the contents of the data frame to the simulation log / Tcl console
        $display("T=%0t %s Depth=%0d Window=%0d", $time, tag, depth, wsize);
    endfunction

endclass

