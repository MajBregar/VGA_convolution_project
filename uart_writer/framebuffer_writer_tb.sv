`timescale 1ns/1ps

module framebuffer_writer_tb;

    // Testbench signals
    logic clk;
    logic reset;
    logic [7:0] data_in;
    logic rx_data_ready;
    logic [9:0] addr_x;
    logic [9:0] addr_y;
    logic [31:0] data_out;
    logic write;
    logic done_recieving;    
    logic [7:0] random_byte;
    // Instantiate the DUT (Device Under Test)
    framebuffer_writer uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .rx_data_ready(rx_data_ready),
        .addr_x(addr_x),
        .addr_y(addr_y),
        .data_out(data_out),
        .write(write),
        .done_recieving(done_recieving)    
    );

    // Clock generation (50MHz -> 20ns period)
    always #10 clk = ~clk;

    // Task to send a byte
    task send_byte(input [7:0] byte_data);
        begin
            @(posedge clk);
            data_in = byte_data;
            rx_data_ready = 1;
            @(posedge clk);
            rx_data_ready = 0;
            @(posedge clk);
            @(posedge clk);
            data_in = 0;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        data_in = 8'b0;
        rx_data_ready = 0;
        @(posedge clk);
        reset = 0;
        #30;
        @(posedge clk);
        
        
        for (int y = 0; y < 480; y++) begin
            for (int x = 0; x < 640 / 2; x++) begin
                random_byte = $urandom;
                send_byte(random_byte);
                #200;
            end
        end

        #400;

        for (int y = 0; y < 480; y++) begin
            for (int x = 0; x < 640 / 2; x++) begin
                random_byte = $urandom;
                send_byte(random_byte);
                #200;
            end
        end

        #100;

        $stop;
    end

endmodule
