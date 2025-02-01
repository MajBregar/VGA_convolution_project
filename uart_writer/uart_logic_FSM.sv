module uart_logic_FSM #( 
    parameter int DBITS = 8,
    parameter int SBITS = 1
) (
    input  logic clock,
    input  logic reset,
    input  logic sample_tick,
    input  logic rx,
    output logic [DBITS-1:0] data_out,
    output logic rx_done
);

    localparam int STOP_TICKS = SBITS * 16; //stop bit length in sample ticks

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t state, next_state;
    logic [DBITS-1:0] shift_reg, shift_reg_next;
    logic [3:0] s_counter, s_counter_next;       //sample counter
    logic [3:0] n_counter, n_counter_next;       //data bit counter
    logic rx_done_next;                          //next value for done signal

    // Sequential logic for state and data registers
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            //reset module state
            state <= IDLE;
            shift_reg <= 0;
            s_counter <= 0;
            n_counter <= 0;
            rx_done <= 0;
        end else begin
            //update module state when clock pulse
            state <= next_state;
            shift_reg <= shift_reg_next;
            s_counter <= s_counter_next;
            n_counter <= n_counter_next;
            rx_done <= rx_done_next;
        end
    end

    //conbinational logic for next module state
    always_comb begin
        next_state = state;
        rx_done_next = 0;
        shift_reg_next = shift_reg;
        s_counter_next = s_counter;
        n_counter_next = n_counter;

        case (state)
            IDLE: begin
                if (rx == 0) begin
                    //detected beginning recieving when rx goes low
                    next_state = START;
                    s_counter_next = 0;
                end
            end
            START: begin
                if (sample_tick) begin
                    if (s_counter == 7) begin
                        //in the middle of start bit - transition to data section
                        next_state = DATA;
                        n_counter_next = 0;
                        s_counter_next = 0;
                    end else begin
                        s_counter_next = s_counter + 1;
                    end
                end
            end
            DATA: begin
                if (sample_tick) begin
                    if (s_counter == 15) begin
                        //last middle sample of data bit - save it
                        s_counter_next = 0;
                        shift_reg_next = {rx, shift_reg[DBITS-1:1]};
                        if (n_counter == (DBITS - 1)) begin
                            next_state = STOP;
                        end else begin
                            n_counter_next = n_counter + 1;
                        end
                    end else begin
                        s_counter_next = s_counter + 1;
                    end
                end
            end
            STOP: begin
                if (sample_tick) begin
                    if (s_counter == (STOP_TICKS - 1)) begin
                        rx_done_next = 1;
                        next_state = IDLE;
                    end else begin
                        s_counter_next = s_counter + 1;
                    end
                end
            end
        endcase
    end

    //output recieved data
    assign data_out = shift_reg;
endmodule
