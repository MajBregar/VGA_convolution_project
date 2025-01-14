`timescale 1ns / 1ps

module color_generator(
    input logic clk,
    input logic reset,
    input logic output_tick,
    input logic [9:0] x_next,
    input logic [9:0] y_next,
    output logic [3:0] grayscale_color
);

    logic [3:0] next_color;
    
    function [3:0] calculate_grayscale(input logic [9:0] x, input logic [9:0] y);
        // Divide the coordinates by 64 to determine the patch location
        logic [6:0] patch_x = x / 64;
        logic [6:0] patch_y = y / 64;
    
        // Determine if the current patch is black or white
        // Use XOR to alternate colors in a checkerboard pattern
        if ((patch_x ^ patch_y) % 2 == 0) begin
            return 4'b1111; // White patch
        end else begin
            return 4'b0000; // Black patch
        end
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            grayscale_color <= calculate_grayscale(0, 0);
            next_color <= calculate_grayscale(0, 0);
        end else begin
            if (output_tick) begin
                grayscale_color <= next_color;
            end
            next_color <= calculate_grayscale(x_next, y_next);
        end
    end

endmodule
