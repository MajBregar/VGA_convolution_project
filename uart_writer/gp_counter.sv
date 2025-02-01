module gp_counter #( 
    parameter int PRESCALER_WIDTH = 8
) (
    input  logic clock,
    input  logic reset,
    input  logic [PRESCALER_WIDTH-1:0] limit,
    output logic sample_tick
);
    logic [PRESCALER_WIDTH-1:0] count;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            count <= 0;
            sample_tick <= 0;
        end else begin
            if (count == (limit - 1)) begin
                count <= 0;
                sample_tick <= 1;
            end else begin
                count <= count + 1;
                sample_tick <= 0;
            end
        end
    end

endmodule
