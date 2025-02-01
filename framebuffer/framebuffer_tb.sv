`timescale 1ns/1ps

module Framebuffer_tb;

    localparam int WIDTH = 640;
    localparam int HEIGHT = 480;

    localparam CLK_PERIOD = 10; // Clock period in nanoseconds

    // Testbench signals
    logic clk;
    logic reset;
    logic [31:0] data_in;
    logic [9:0] x_pos;
    logic [9:0] y_pos;
    logic read;
    logic write;
    logic [99:0] data_chunk;
    logic data_ready;
    logic data_ready;

    logic [31:0] generated_input_data;

    // Instantiate the Framebuffer module
    Framebuffer uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .read(read),
        .write(write),
        .data_chunk(data_chunk),
        .data_ready(data_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end


    // Task to write data to the Framebuffer
    task write_to_framebuffer(input [31:0] wr_data, input [9:0] wr_x_pos, input [9:0] wr_y_pos);
        begin
            @(posedge clk);
            data_in <= wr_data;
            x_pos = wr_x_pos;
            y_pos = wr_y_pos;
            write = 1;
            @(posedge clk);
            @(posedge clk);
            data_in <= 32'bZ;
            x_pos = 10'bZ;
            y_pos = 10'bZ;
            write = 0;
        end
    endtask

    // Task to read data from the Framebuffer
    task read_from_framebuffer(input [9:0] rd_x_pos, input [9:0] rd_y_pos);
        begin
            @(posedge clk);
            x_pos = rd_x_pos;
            y_pos = rd_y_pos;
            read = 1;
            @(posedge clk);
            @(posedge clk);
            #200;
            @(posedge clk);
            x_pos = 10'bZ;
            y_pos = 10'bZ;
            read = 0;
            wait (data_ready == 1);
            $display("DATA=%h", data_chunk);
        end
    endtask

    // Testbench process
    initial begin
        clk = 0;
        reset = 1;
        data_in = 32'bZ;
        x_pos = 10'bZ;
        y_pos = 10'bZ;
        read = 0;
        write = 0;
        #100;
        reset = 0;
        #20;


        
        // Test write operations
        $display("Starting write operations...");
        for (int y = 0; y < HEIGHT; y++) begin
            generated_input_data = (y % 16) * 32'h11111111;
            write_to_framebuffer(generated_input_data, 576, y);
            generated_input_data = (15 - (y % 16)) * 32'h11111111;
            write_to_framebuffer(generated_input_data, 584, y);
        end

        for (int y = 0; y < HEIGHT; y++) begin
            read_from_framebuffer(582, y);
        end
        

        $finish;
    end

endmodule
