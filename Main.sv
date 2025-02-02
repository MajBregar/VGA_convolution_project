`timescale 1ns / 1ps

module Main(
    input logic clk,
    input logic reset,
    
    //VGA
    input logic display_image,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic hsync,
    output logic vsync,

    //UART
    input logic rx,
    output logic rx_empty,
    output logic data_ready_LED,
    output logic [7:0] debug_data,
    output logic buffer_filled,
    output logic debug_LED
);
    
    //uart reciever
    logic [7:0] reciever_out;
    logic reciever_data_ready;

    //uart framebuffer writer
    logic [9:0] x_pos_writer, y_pos_writer;
    logic [31:0] data_word;
    logic write;
    logic done_recieving;

    //fremebuffer
    logic [9:0] x_pos, y_pos;
    logic read;
    logic [99:0] fb_data_chunk;
    logic fb_output_data_ready;

    //vga output module
    logic new_pixel_request;
    logic [9:0] new_pixel_x;
    logic [9:0] new_pixel_y;
    logic [3:0] output_grayscale_color;


    uart_reciever uart_r (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(reciever_out),
        .rx_empty(rx_empty),
        .rx_data_ready(reciever_data_ready)
    );
    //guarantee that rx_data_ready and data_out are being asserted correctly

    framebuffer_writer fb_writer (
        .clk(clk),
        .reset(reset),
        .data_in(reciever_out),
        .rx_data_ready(reciever_data_ready),  
        .addr_x(x_pos_writer),
        .addr_y(y_pos_writer),
        .data_out(data_word),
        .write(write),
        .done_recieving(done_recieving)
    );
    //write signal is being asserted correctly - for 3 cycles
    //address generation works correctly
    //data word generates correctly
    
    //mux for buffer writer and vga pixel request
    always_comb begin
        if (!done_recieving) begin
            x_pos = x_pos_writer;
            y_pos = y_pos_writer;
        end else begin
            x_pos = new_pixel_x;
            y_pos = new_pixel_y;
        end
    end


    Framebuffer fb(
        .clk(clk),
        .reset(reset),
        .data_in(data_word),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .read(new_pixel_request),
        .write(write),
        .data_chunk(fb_data_chunk),
        .data_ready(fb_output_data_ready)
    );

    assign data_ready_LED = reciever_data_ready;
    assign buffer_filled = done_recieving;
    
    convolution cnv (
        .clk(clk),
        .reset(reset),
        .data_ready(fb_output_data_ready),
        .data_chunk(fb_data_chunk),
        .grayscale_color(output_grayscale_color)
    );



    VGA_output uut_vga_output(
        .clk(clk),
        .reset(reset),
        .display_image(done_recieving),
        .grayscale_pixel(output_grayscale_color),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync),
        .new_pixel_request(new_pixel_request),
        .new_pixel_x(new_pixel_x),
        .new_pixel_y(new_pixel_y)
    );

endmodule
