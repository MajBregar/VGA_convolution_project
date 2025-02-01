module uart_reciever (
    input logic clk,
    input logic reset,
    input logic rx,
    output logic [7:0] data_out,
    output logic rx_empty,
    output logic rx_data_ready
);

    // Parameters
    localparam int PRESCALER_WIDTH = 9;
    localparam int LIMIT = 326;
    localparam int DBITS = 8;
    localparam int SBITS = 1;

    // Wires
    logic [PRESCALER_WIDTH-1:0] limit = LIMIT;
    logic sample_tick; //generated sample tick
    logic [7:0] uart_out; //uart output
    logic rx_done; //done recieving

    gp_counter #(
        .PRESCALER_WIDTH(PRESCALER_WIDTH)
    ) sample_tick_generator (
        .clock(clk),
        .reset(reset),
        .limit(limit),
        .sample_tick(sample_tick)
    );

    uart_logic_FSM #(
        .DBITS(DBITS),
        .SBITS(SBITS)
    ) uart_machine (
        .clock(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .rx(rx),
        .data_out(uart_out),
        .rx_done(rx_done)
    );


    logic [7:0] message;
    uart_interface #(
        .DATA_WIDTH(DBITS)
    ) IF_circ (
        .clock(clk),
        .reset(reset),
        .r_input(uart_out),
        .rx_done(rx_done),
        .rx_empty(rx_empty),
        .r_out(message),
        .rx_data_ready(rx_data_ready)
    );

    assign data_out = message;
endmodule
