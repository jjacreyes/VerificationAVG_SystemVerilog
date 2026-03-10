`timescale 1ns / 1ps

module debouncer #(parameter int unsigned DEBOUNCE_COUNT = 500_000) (
    input logic i_clk,
    input logic i_rst,
    input logic i_btn_in,
    output logic o_btn_out
    );

    /*========================= DO NOT EDIT BEGINS ===============================*/
    /*========================= DO NOT EDIT BEGINS ===============================*/
    /*========================= DO NOT EDIT BEGINS ===============================*/

    localparam int unsigned COUNTER_WIDTH = $clog2(DEBOUNCE_COUNT);

    logic [COUNTER_WIDTH-1:0] cnt;
    (* async_reg = "true" *) logic sync0, sync1;
    
    always_ff @(posedge i_clk) begin
        sync0 <= i_btn_in;
        sync1 <= sync0;
    end

    always_ff @(posedge i_clk) begin
        if (sync1 != o_btn_out) begin

            cnt <= cnt + 1;

            if (cnt >= DEBOUNCE_COUNT) begin
                o_btn_out <= sync1;
                cnt <= 16'd0;
            end
        end else begin
            cnt <= 16'd0;
        end

        if (i_rst) begin
            cnt <= 16'd0;
            o_btn_out <= 1'b0;
        end
    end

    /*========================= DO NOT EDIT ENDS ===============================*/
    /*========================= DO NOT EDIT ENDS ===============================*/
    /*========================= DO NOT EDIT ENDS ===============================*/


endmodule