`timescale 1ns / 1ps

module vga_hsync (
    input logic clk,
    input logic reset,
    input logic pixel_tick,
    output logic hsync,
    output logic eol, 
    output logic hvideo_on,
    output logic [9:0] x_pos,
    output logic [9:0] x_pos_next
);

    localparam BP = 48;
    localparam FP = 16;
    localparam SP = 96;
    localparam DT = 640;
    localparam COUNTER_LIMIT = BP + FP + SP + DT; // 800

    logic [9:0] count;
    logic hsync_next, eol_next, hvideo_on_next;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 0;
            hsync <= 0;
            eol <= 0; 
            hvideo_on <= 0;
            x_pos <= 0;
        end else if (pixel_tick) begin
            // Update the current state
            count <= (count == COUNTER_LIMIT - 1) ? 0 : count + 1;
            hsync <= hsync_next;
            eol <= eol_next; 
            hvideo_on <= hvideo_on_next;
            x_pos <= x_pos_next; // Reflect the next x position on clock edge
        end
    end

    // Continuous assignments for next-state logic
    assign hsync_next = count < (BP + FP + DT);
    assign eol_next = (count == COUNTER_LIMIT - 1);
    assign hvideo_on_next = (count >= BP) && (count < (BP + DT));
    assign x_pos_next = (hvideo_on_next) ? (count - BP) : 0; 
 
endmodule
