`timescale 1ns / 1ps

module Main(
    input logic clk,
    input logic reset,
    input logic display_image,
    
    //VGA output
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic hsync,
    output logic vsync
);
    
    logic [3:0] generated_color;
    logic new_pixel_request;
    logic [9:0] new_pixel_x;
    logic [9:0] new_pixel_y;
    
    VGA_output uut_vga_output(
        .clk(clk),
        .reset(reset),
        .display_image(display_image),
        .grayscale_pixel(generated_color),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync),
        .new_pixel_request(new_pixel_request),
        .new_pixel_x(new_pixel_x),
        .new_pixel_y(new_pixel_y)
    );

    color_generator uut_color_generator(
        .clk(clk),
        .reset(reset),
        .output_tick(new_pixel_request),
        .x_next(new_pixel_x),
        .y_next(new_pixel_y),
        .grayscale_color(generated_color)
    );
    
endmodule
