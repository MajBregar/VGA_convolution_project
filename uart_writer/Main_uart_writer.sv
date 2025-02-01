module Main_uart_fb_writer (
    input logic clk,
    input logic reset,
    input logic rx,
    output logic rx_empty,
    output logic data_ready_LED,
    output logic [7:0] debug_data,
    output logic buffer_filled,
    output logic debug_LED
);
    
    logic [7:0] reciever_out;
    logic reciever_data_ready;

    logic [9:0] x_pos_writer, y_pos_writer;
    logic [31:0] data_word;
    logic write;
    logic done_recieving;


    logic [9:0] x_pos, y_pos;
    logic read;
    logic [99:0] fb_data_chunk;
    logic fb_output_data_ready;

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
    

    always_comb begin
        if (!done_recieving) begin
            x_pos = x_pos_writer;
            y_pos = y_pos_writer;
            read = 0;
        end else begin
            x_pos = 8;
            y_pos = 8;
            read = 1;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            debug_data <= 0;
            debug_LED <= 0;
        end else begin
            if (fb_output_data_ready) begin
                debug_LED <= 1;
                debug_data <= fb_data_chunk[7:0];
            end 
        end
    end

    Framebuffer fb(
        .clk(clk),
        .reset(reset),
        .data_in(data_word),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .read(read),
        .write(write),
        .data_chunk(fb_data_chunk),
        .data_ready(fb_output_data_ready)
    );

    
    assign data_ready_LED = reciever_data_ready;
    assign buffer_filled = done_recieving;
endmodule
