`timescale 1ns / 1ps

module Main_tb;
    // Clock and reset
    logic clk;
    logic reset;
    
    // VGA
    logic display_image;
    logic [3:0] vga_r, vga_g, vga_b;
    logic hsync, vsync;
    
    // UART
    logic rx;
    logic rx_empty;
    logic data_ready_LED;
    logic [7:0] debug_data;
    logic buffer_filled;
    logic debug_LED;
    
    // Clock period (100MHz -> 10ns per cycle)
    localparam CLOCK_PERIOD = 10;
    
    // UART Parameters (19200 baud -> ~52.08µs per bit)
    localparam UART_BAUD_RATE = 19200;
    localparam UART_BIT_PERIOD = 1000000000 / UART_BAUD_RATE; // in ns
    
    // Instantiate the DUT (Device Under Test)
    Main uut (
        .clk(clk),
        .reset(reset),
        .display_image(display_image),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync),
        .rx(rx),
        .rx_empty(rx_empty),
        .data_ready_LED(data_ready_LED),
        .debug_data(debug_data),
        .buffer_filled(buffer_filled),
        .debug_LED(debug_LED)
    );
    
    // Clock Generation
    always #(CLOCK_PERIOD / 2) clk = ~clk;
    
    // UART Transmission Task
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            rx = 0; // Start bit
            #(UART_BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(UART_BIT_PERIOD);
            end
            rx = 1; // Stop bit
            #(UART_BIT_PERIOD);
        end
        #1000;
    endtask
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        rx = 1;
        display_image = 0;
        #100;
        reset = 0;
        #100;
        
        for (int y = 0; y < 480; y++) begin
            for (int x = 0; x < 640 / 2; x++) begin
                send_uart_byte(8'hFF);
            end
        end
        
        wait (buffer_filled);

        #50000;
        
        $finish;
    end
endmodule
