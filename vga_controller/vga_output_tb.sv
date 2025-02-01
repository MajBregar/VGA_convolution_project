`timescale 1ns / 1ps

module VGA_output_tb;
    
    logic clk;
    logic reset;
    logic display_image;
    logic [3:0] grayscale_pixel;
    
    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;
    logic hsync;
    logic vsync;
    
    logic new_pixel_request;
    logic [9:0] new_pixel_x;
    logic [9:0] new_pixel_y;
    
    // Instantiate the VGA_output module
    VGA_output uut (
        .clk(clk),
        .reset(reset),
        .display_image(display_image),
        .grayscale_pixel(grayscale_pixel),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync),
        .new_pixel_request(new_pixel_request),
        .new_pixel_x(new_pixel_x),
        .new_pixel_y(new_pixel_y)
    );
    
    // Clock generation
    always #5 clk = ~clk; // 10ns period -> 100MHz clock
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        display_image = 0;
        grayscale_pixel = 4'b0000;
        
        // Reset pulse
        @(posedge clk);
        reset = 0;
        #200;

        display_image = 1;
        grayscale_pixel = 4'b1010; // Example grayscale value
        
        #50000;

        
        $stop;
    end
    
    // Monitor outputs
    initial begin
        $monitor("Time=%0t | VGA_R=%b VGA_G=%b VGA_B=%b HSYNC=%b VSYNC=%b X=%d Y=%d", 
                 $time, vga_r, vga_g, vga_b, hsync, vsync, new_pixel_x, new_pixel_y);
    end
    
endmodule
