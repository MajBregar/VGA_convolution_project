`timescale 1ns/1ps

module Framebuffer (
    input logic clk,
    input logic reset,
    input logic [31:0] data_in,     // This same signal is the input for every Row_Bram
    input logic [9:0] x_pos,        // This same x_pos is the input for every Row_Bram
    input logic [9:0] y_pos,        // Selects the BRAM and the local y position based on this signal
    input logic read,               // When high, every BRAM outputs its data simultaneously
    input logic write,              // When high, only one BRAM is written to
    output logic [99:0] data_chunk,  // Combined output of all BRAMs
    output logic data_ready
);

    localparam int WIDTH = 640;
    localparam int HEIGHT = 480;
    localparam int BRAM_HEIGHT = 96;

    //output data of brams
    logic [19:0] bram_outputs[4:0];

    //bram write enable for selecting only 1 bram during write
    logic [4:0] write_signals;
    assign write_signals = write ? (5'b1 << (y_pos % 5)) : 5'b0;

    //base offset of middle row
    logic [2:0] base_offset;
    assign base_offset = y_pos % 5;

    //offsets for calculating local y positions in brams
    logic [6:0] local_y_pos [4:0];
    logic signed [3:0] y_offset [4:0];
    logic signed [3:0] read_offset;
    
    logic [1:0] clock_cycle_counter;
    logic internal_read_flag;
    logic internal_read_clear;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clock_cycle_counter <= 0;
            data_ready <= 0;
            internal_read_flag <= 0;
            internal_read_clear <= 1;
        end else begin
            if (read && !internal_read_flag && !internal_read_clear) begin
                internal_read_flag <= 1;
                internal_read_clear <= 0;
                data_ready <= 1;
            end else if (read && internal_read_flag && !internal_read_clear) begin
                data_ready <= 1;
            end else if (data_ready && internal_read_flag && !internal_read_clear) begin
                data_ready <= 0;
                internal_read_clear <= 1;
            end else begin
                internal_read_clear <= 0;
                internal_read_flag <= 0;
                data_ready <= 0;
            end
        end
    end


    //combinational logic for selecting proper local y position inside each bram
    genvar i;
    generate
        for (i = 0; i < 5; i++) begin : Local_Y_Pos_Circuit
            always_comb begin
                y_offset[i] = i - base_offset;
                if (y_offset[i] < 0) begin
                    y_offset[i] = y_offset[i] + 5;
                end

                case (y_offset[i])
                    0: local_y_pos[i] = y_pos / 5;
                    1: local_y_pos[i] = (y_pos + 1) < HEIGHT ? (y_pos + 1) / 5 : 0;
                    2: local_y_pos[i] = (y_pos + 2) < HEIGHT ? (y_pos + 2) / 5 : 0;
                    3: local_y_pos[i] = (y_pos >= 2)  ? (y_pos - 2) / 5 : 0;
                    4: local_y_pos[i] = (y_pos >= 1)  ? (y_pos - 1) / 5 : 0;
                    default: local_y_pos[i] = 0;
                endcase
                //$display("i=%d,  local_y_pos[i]=%d,  y_offset[i]=%d, base_offset=%d", i, local_y_pos[i], y_offset[i], base_offset);
            end
        end
    endgenerate


    //bram row modules
    generate
        for (i = 0; i < 5; i++) begin : Row_Bram_Instances
            Row_Bram row_bram_inst (
                .clk(clk),
                .reset(reset),
                .data_in(data_in),
                .x_pos(x_pos),
                .local_y_pos(local_y_pos[i]),
                .read(read),
                .write(write_signals[i]),
                .nibble_5_out(bram_outputs[i])
            );
        end
    endgenerate


    //output logic - properly organises outputted rows and padds with 0 if we read on image edge
    //whats the do not repeat yourself rule in programming?
    

    always_comb begin
        if (data_ready) begin
            read_offset = (base_offset >= 2) ? base_offset - 2 : base_offset - 2 + 5;
            if (y_pos == 0) begin
                data_chunk = {  bram_outputs[(read_offset + 4) % 5], 
                                bram_outputs[(read_offset + 3) % 5], 
                                bram_outputs[(read_offset + 2) % 5],
                                40'h0
                };
            end else if (y_pos == 1) begin
                data_chunk = {  bram_outputs[(read_offset + 4) % 5], 
                                bram_outputs[(read_offset + 3) % 5], 
                                bram_outputs[(read_offset + 2) % 5],
                                bram_outputs[(read_offset + 1) % 5], 
                                20'h0
                };
            end else if (y_pos == HEIGHT - 1) begin
                data_chunk = {  40'h0,
                                bram_outputs[(read_offset + 2) % 5],
                                bram_outputs[(read_offset + 1) % 5], 
                                bram_outputs[(read_offset + 0) % 5]
                };
            end else if (y_pos == HEIGHT - 2) begin
                data_chunk = {  20'h0, 
                                bram_outputs[(read_offset + 3) % 5], 
                                bram_outputs[(read_offset + 2) % 5],
                                bram_outputs[(read_offset + 1) % 5], 
                                bram_outputs[(read_offset + 0) % 5]
                };
            end else begin
                data_chunk = {  bram_outputs[(read_offset + 4) % 5], 
                                bram_outputs[(read_offset + 3) % 5], 
                                bram_outputs[(read_offset + 2) % 5],
                                bram_outputs[(read_offset + 1) % 5], 
                                bram_outputs[(read_offset + 0) % 5]
                };
            end
        end else begin
            data_chunk = 100'bZ;
        end
        

        //$display("DATA in cont section = %h", cont_data_chunk);
    end

endmodule
