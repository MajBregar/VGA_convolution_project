module vga_vsync(
    input logic clk,
    input logic reset,
    input logic pixel_tick,
    input logic eol,
    output logic vsync,
    output logic [9:0] y_pos,
    output logic [9:0] y_pos_next, // Added output for y_pos_next
    output logic vvideo_on
);

    // 0. Define constants
    localparam BP = 29;
    localparam FP = 10;
    localparam SP = 2;
    localparam DT = 480;
    localparam COUNTER_LIMIT = BP + FP + SP + DT;

    // 1. Determine how many bits are needed for the counter
    logic [9:0] count;
    logic vsync_next, vvideo_on_next;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 0;
            y_pos <= 0;
            vsync <= 0;
            vvideo_on <= 0;
        end else begin
            if (pixel_tick & eol) begin
                count <= count + 1;
                y_pos <= y_pos_next;   // Update y_pos with the next value
                vsync <= vsync_next;
                vvideo_on <= vvideo_on_next;
                if (count == COUNTER_LIMIT - 1) begin
                    count <= 0;       // Reset count when it reaches the limit
                end
            end
        end
    end

    // Continuous assignments for next-state logic
    assign vsync_next = count < (BP + FP + DT);
    assign vvideo_on_next = (count >= BP) && (count < (BP + DT));
    assign y_pos_next = (vvideo_on_next) ? (count - BP) : 0;

endmodule
