module VGA_output(
    input logic clk,
    input logic reset,
    input logic display_image,
    input logic [3:0] grayscale_pixel,
    
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic hsync,
    output logic vsync,
    
    output logic new_pixel_request,
    output logic [9:0] new_pixel_x,
    output logic [9:0] new_pixel_y
);

    logic pixel_tick;
    counter25MHz uut_counter25MHz(
        .clk(clk),
        .reset(reset),
        .pixel_tick(pixel_tick)
    );
    
    //HSYNC
    logic eol;
    logic hvideo_on;
    logic [9:0] x_pos;
    logic [9:0] x_pos_next;
    vga_hsync uut_vga_hsync(
        .clk(clk),
        .reset(reset),
        .pixel_tick(pixel_tick),
        .hsync(hsync),
        .eol(eol),
        .hvideo_on(hvideo_on),
        .x_pos(x_pos),
        .x_pos_next(x_pos_next)
    );
    
    //VSYNC
    logic vvideo_on;
    logic [9:0] y_pos;
    logic [9:0] y_pos_next;
    vga_vsync uut_vga_vsync(
        .clk(clk),
        .reset(reset),
        .pixel_tick(pixel_tick),
        .eol(eol),
        .vsync(vsync),
        .y_pos(y_pos),
        .vvideo_on(vvideo_on),
        .y_pos_next(y_pos_next)
    );
    
    //LOGIC TO DETERMINE IF THE DISPLAY IS ON VISIBLE PART OF THE SCREEN
    logic video_on;
    assign video_on = hvideo_on && vvideo_on;
    
    //COLOR ASSIGNMENT
    assign new_pixel_request = pixel_tick;
    assign new_pixel_x = x_pos_next;
    assign new_pixel_y = y_pos_next;
    assign vga_r = (video_on) ? grayscale_pixel : 4'b0000;
    assign vga_b = (video_on) ? grayscale_pixel : 4'b0000;
    assign vga_g = (video_on) ? grayscale_pixel : 4'b0000;

endmodule