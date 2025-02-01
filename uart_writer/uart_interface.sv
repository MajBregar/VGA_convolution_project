module uart_interface #(
    parameter int DATA_WIDTH = 8
) (
    input  logic clock,
    input  logic reset,
    input  logic [DATA_WIDTH-1:0] r_input,
    input  logic rx_done,
    output logic rx_empty,
    output logic [DATA_WIDTH-1:0] r_out,
    output logic rx_data_ready
);

    // Internal signals
    logic [1:0] cycle_count; // 2-bit counter to track 3 cycles
    logic active;

    // Data buffer logic
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            r_out <= 0;
            rx_data_ready <= 0;
            cycle_count <= 0;
            active <= 0;
        end else if (rx_done && !active) begin
            r_out <= r_input;
            rx_data_ready <= 1;
            cycle_count <= 1;
            active <= 1;
        end else if (active) begin
            if (cycle_count < 3) begin
                cycle_count <= cycle_count + 1;
            end else begin
                rx_data_ready <= 0;
                r_out <= 0;
                cycle_count <= 0;
                active <= 0;
            end
        end
    end

    // Update rx_empty based on active status
    assign rx_empty = ~active;

endmodule