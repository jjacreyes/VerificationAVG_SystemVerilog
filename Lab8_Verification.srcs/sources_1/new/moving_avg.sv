`timescale 1ns / 1ps

module moving_avg #(
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned DATA_WIDTH  = 16,
    parameter int unsigned WINDOW_SIZE = 8
) (
    input logic i_clk,
    input logic i_rst,
    input logic i_start,

    // BRAM read interface
    output logic [ADDR_WIDTH-1:0] o_bram_addr,
    output logic                  o_bram_en,
    input  logic [DATA_WIDTH-1:0] i_bram_data,

    // Output moving average stream
    output logic [DATA_WIDTH-1:0] o_data,
    output logic                  o_valid
);

    localparam int unsigned DEPTH = 1 << ADDR_WIDTH;

    typedef enum logic [1:0] {
        S_IDLE,
        S_READ,
        S_LAST
    } state_t;

    // Moving average window size
    logic [DATA_WIDTH-1:0] shift_reg[WINDOW_SIZE];

    logic bram_en_delay;
    logic [31:0] running_sum;
    logic [3:0] sample_count;

    // FSM
    state_t state, next_state;

    always_ff @(posedge i_clk) begin
        state <= next_state;
        if (i_rst) state <= S_IDLE;
    end

    // This block handles reading from BRAM, updating the running sum, and producing the output average
    always_ff @(posedge i_clk) begin
        // Use this delay signal to match the latency of the BRAM
        bram_en_delay <= o_bram_en;

        case (state)
            S_IDLE: begin
                o_bram_addr    <= 'd0;
                o_bram_en      <= 1'b0;
                sample_count <= 0;

            end

            S_READ: begin
                o_bram_en   <= 1'b1;
                // Incremement the BRAM address to read next sample
                o_bram_addr <= o_bram_addr + o_bram_en;

                // Capture new data into shift register
                shift_reg[0] <= i_bram_data;
                for (int i = WINDOW_SIZE - 1; i > 0; i = i - 1) begin
                    shift_reg[i] <= shift_reg[i-1];
                end

                // For the fii_rst few samples, just accumulate until we have a full window
                if (sample_count < WINDOW_SIZE) begin
                    running_sum  <= running_sum + i_bram_data;
                    sample_count <= sample_count + 1;
                end else begin
                    running_sum <= running_sum + i_bram_data - shift_reg[WINDOW_SIZE-1];
                end

            end

            // Due to BRAM latency, there are a few samples left to process after the last read.
            // This state handles those remaining samples.
            S_LAST: begin
                o_bram_en <= 1'b0;

                shift_reg[0] <= i_bram_data;
                for (int i = WINDOW_SIZE - 1; i > 0; i = i - 1) begin
                    shift_reg[i] <= shift_reg[i-1];
                end

                running_sum <= running_sum + i_bram_data - shift_reg[WINDOW_SIZE-1];
            end

            default: begin
                o_bram_addr    <= 'd0;
                o_bram_en      <= 1'b0;
                sample_count <= 0;
            end

        endcase

        // Always capture the running average, but only assert o_valid when we have a full window of samples
        o_data <= running_sum >> $clog2(WINDOW_SIZE);
        if ((sample_count == WINDOW_SIZE && state == S_READ) || state == S_LAST) begin
            o_valid <= 1'b1;
        end else begin
            o_valid <= 0;
        end

        // Reset
        if (i_rst) begin
            o_bram_addr    <= 0;
            o_bram_en      <= 0;
            running_sum  <= 0;
            o_valid    <= 0;
            o_data     <= 0;
            sample_count <= 0;
        end
    end

    // Next state logic
    always_comb begin
        next_state = S_IDLE;

        case (state)
            S_IDLE: begin
                // Begin reading when i_start is asserted
                if (i_start) next_state = S_READ;
            end
            S_READ: begin
                // Keep reading until we reach the end of memory
                if (o_bram_addr == DEPTH - 2) next_state = S_LAST;
                else next_state = S_READ;
            end
            S_LAST: begin
                // After the last read, go back to idle if o_bram_en is deasserted.
                // Use the delayed version to account for BRAM latency.
                if (bram_en_delay == 0) next_state = S_IDLE;
                else next_state = S_LAST;
            end

            default: next_state = S_IDLE;

        endcase

    end

endmodule

