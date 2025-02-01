`timescale 1ns/1ps

module Row_Bram (
    input logic clk,
    input logic reset,
    input logic [31:0] data_in,
    input logic [9:0] x_pos,
    input logic [6:0] local_y_pos,
    input logic read,
    input logic write,
    output logic [19:0] nibble_5_out
);  
    /*  BEHAVIOUR
        -stores WIDTH * ROW_COUNT nibble cells aka WIDTH_WORD_COUNT * ROW_COUNT 32-bit words
        -x_pos - address of a single nibble cell inside the BRAM - from 0 to WIDTH - 1
        -local_y_pos - address of the local row where a nibble is written - from 0 to ROW_COUNT - 1

        WRITING
        -addresses and input data must be stable before the write signal is asserted to high (recommend atleast 1 cycle)
        -write must be asserted for atleast 1 cycle

        READING
        -addresses must be stable before the read signal is asserted to high (recommend atleast 1 cycle)
        -data is available when read is asserted high

        OUTPUT - nibble_5_output
        -outputs a nibble at the position X_pos local_y_pos and its 2 surrounding left neighbours and 2 right neighbours
        -if the cell neighbours are out of position bounds the nibbles are returned as 4'b0000
        -formatted in form {left_far, left_close, addressed_nibble, right_close, right_far} where right_far are the LSB bits of the 20 bit bus
    */

    //RAM SETUP
    localparam int WIDTH = 640;
    localparam int ROW_COUNT = 96;
    localparam int WIDTH_WORD_COUNT = WIDTH / 8;
    localparam int TOTAL_CELL_COUNT = WIDTH_WORD_COUNT * ROW_COUNT;
    (* ram_style = "block" *) logic [31:0] bram [0:TOTAL_CELL_COUNT];

    //ADDRESS SIGNALS
    logic [$clog2(TOTAL_CELL_COUNT) - 1:0] core_address;
    logic [$clog2(TOTAL_CELL_COUNT) - 1:0] side_address;
    logic [2:0] nibble_select;

    //INTERNAL STATE SIGNALS
    logic [31:0] core_reg;
    logic [31:0] side_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            core_address <= 0;
            side_address <= 0;
            nibble_select <= 0;
        end else begin
            core_address <= WIDTH_WORD_COUNT * local_y_pos + x_pos[9:3];
            side_address <= WIDTH_WORD_COUNT * local_y_pos + x_pos[9:3] + (x_pos[2:0] >= 2 ? 1 : -1);
            nibble_select <= x_pos[2:0];
        end
    end

    //WRITE LOGIC
    always_ff @(posedge clk) begin
        if (write) begin
            bram[core_address] <= data_in;
        end
    end

    //READ LOGIC
    always_ff @(posedge clk) begin
        if (read) begin
            core_reg <= bram[core_address];
            side_reg <= bram[side_address];
        end
    end

    always_comb begin
        if (read) begin
            case (nibble_select)
                3'b000: nibble_5_out = (x_pos == 0) ? 
                        {8'b0, core_reg[3:0], core_reg[7:4], core_reg[11:8]} : 
                        {side_reg[27:24], side_reg[31:28], core_reg[3:0], core_reg[7:4], core_reg[11:8]};
                3'b001: nibble_5_out = (x_pos == 1) ? 
                        {4'b0, core_reg[3:0], core_reg[7:4], core_reg[11:8], core_reg[15:12]} : 
                        {side_reg[27:24], core_reg[3:0], core_reg[7:4], core_reg[11:8], core_reg[15:12]};
                3'b010: nibble_5_out = {core_reg[3:0], core_reg[7:4], core_reg[11:8], core_reg[15:12], core_reg[19:16]};
                3'b011: nibble_5_out = {core_reg[7:4], core_reg[11:8], core_reg[15:12], core_reg[19:16], core_reg[23:20]};               
                3'b100: nibble_5_out = {core_reg[11:8], core_reg[15:12], core_reg[19:16], core_reg[23:20], core_reg[27:24]};
                3'b101: nibble_5_out = {core_reg[15:12], core_reg[19:16], core_reg[23:20], core_reg[27:24], core_reg[31:28]};
                3'b110: nibble_5_out = (x_pos == WIDTH - 2) ? 
                        {core_reg[19:16], core_reg[23:20], core_reg[27:24], core_reg[31:28], 4'b0} : 
                        {core_reg[19:16], core_reg[23:20], core_reg[27:24], core_reg[31:28], side_reg[3:0]};
                3'b111: nibble_5_out = (x_pos == WIDTH - 1) ? 
                        {core_reg[23:20], core_reg[27:24], core_reg[31:28], 8'b0} :
                        {core_reg[23:20], core_reg[27:24], core_reg[31:28], side_reg[3:0], side_reg[7:4]};
                default: nibble_5_out = 20'h00000;
            endcase
        end else begin
            nibble_5_out = 20'bZ;
        end
    end
endmodule
