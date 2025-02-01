`timescale 1ns / 1ps

module convolution (
    input logic clk,
    input logic reset,
    input logic data_ready,
    input logic [99:0] data_chunk,
    output logic [3:0] grayscale_color
);

    //pass through for now
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            grayscale_color <= 0;
        end else begin
            if (data_ready) begin
                grayscale_color <= data_chunk[51:48];
            end
        end
    end

endmodule