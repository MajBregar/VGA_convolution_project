module framebuffer_writer (
    input  logic       clk,       // Clock signal
    input  logic       reset,     // Reset signal
    input  logic [7:0] data_in,   // Data input from UART receiver
    input  logic       rx_data_ready,  
    output logic [9:0] addr_x,    // X address
    output logic [9:0] addr_y,    // Y address
    output logic [31:0] data_out,  // Data output
    output logic       write,      // Write signal
    output logic done_recieving
);
    localparam int WIDTH = 640;
    localparam int HEIGHT = 480;
    localparam int WRITE_HOLD_TIME = 3; 

    logic [$clog2(WIDTH * HEIGHT)-1:0] pixel_counter, output_pixel_counter, output_pixel_counter_next;
    logic already_processed;

    logic [2:0] word_counter;
    logic [31:0] output_buffer;
    logic [2:0] write_hold;

    typedef enum logic [2:0] {
        NOT_INITIALIZED,
        NEW_IMAGE,
        WAITING_FOR_DATA,
        BUFFER_FILLING_STAGE,
        WORD_BUFFER_FULL,
        WRITE_HOLD,
        IMAGE_PROCESSED
    } state_t;
    state_t current_state, next_state;

    assign debug_state = current_state;

    //state transitions
    always_comb begin
        next_state = current_state;

        case (current_state)
            NOT_INITIALIZED: begin
                if (rx_data_ready) begin
                    next_state = NEW_IMAGE;
                end
            end
            NEW_IMAGE: next_state = WAITING_FOR_DATA;
            WAITING_FOR_DATA: begin
                if (rx_data_ready && !already_processed) begin
                    if (pixel_counter % 8 == 0) begin
                        next_state = WORD_BUFFER_FULL;
                    end else begin
                        next_state = BUFFER_FILLING_STAGE;
                    end
                end
            end
            BUFFER_FILLING_STAGE: begin
                next_state = WAITING_FOR_DATA;
            end
            WORD_BUFFER_FULL: next_state = WRITE_HOLD;

            WRITE_HOLD: begin
                if (!write) begin
                    if (pixel_counter < (WIDTH * HEIGHT)) begin
                        next_state = WAITING_FOR_DATA;
                    end else begin
                        next_state = IMAGE_PROCESSED;
                    end
                end
            end

            IMAGE_PROCESSED: begin
                if (rx_data_ready) begin
                    next_state = NEW_IMAGE;
                end
            end
            default: next_state = NOT_INITIALIZED;
        endcase
    end

    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            //INTERNAL STATE
            current_state <= NOT_INITIALIZED;
            pixel_counter <= 0;
            output_pixel_counter <= 0;
            output_pixel_counter_next <= 0;
            already_processed <= 0;
            output_buffer <= 0;
            write <= 0;
            write_hold <= 0;
            
        end else begin

            case (current_state)
                NOT_INITIALIZED: begin
                end
                NEW_IMAGE: begin
                    pixel_counter <= 4;
                    output_pixel_counter <= 0;
                    output_pixel_counter_next <= 0;
                    output_buffer <= {data_in, output_buffer[31:8]};
                    already_processed <= 1;
                end
                WAITING_FOR_DATA: begin
                    if (!rx_data_ready) begin
                        already_processed <= 0;
                    end
                    write_hold <= 0;
                end
                BUFFER_FILLING_STAGE: begin
                    pixel_counter <= pixel_counter + 2;
                    already_processed <= 1;
                    output_buffer <= {data_in, output_buffer[31:8]};
                end
                WORD_BUFFER_FULL: begin
                    pixel_counter <= pixel_counter + 2;
                    output_pixel_counter <= output_pixel_counter_next;
                    output_pixel_counter_next <= output_pixel_counter_next + 8;
                    already_processed <= 1;
                    output_buffer <= {data_in, output_buffer[31:8]};
                    write_hold <= 0;
                    write <= 1;
                end
                WRITE_HOLD: begin
                    write_hold <= write_hold + 1;
                    if (write_hold + 1 > WRITE_HOLD_TIME - 1) begin
                        write <= 0;
                    end else begin
                        write <= 1;
                    end
                end
                IMAGE_PROCESSED: begin
                    write_hold <= 0;
                end
            endcase

            current_state <= next_state;
        end
    end

    always_comb begin
        if (reset) begin
            //OUTPUTS
            addr_x = 10'bZ;
            addr_y = 10'bZ;
            data_out = 32'bZ;
            done_recieving = 0;
        end else begin
            if (write) begin
                addr_x = output_pixel_counter % WIDTH;
                addr_y = output_pixel_counter / WIDTH;
                data_out = output_buffer;
                done_recieving = 0;
            end else if (current_state == IMAGE_PROCESSED) begin
                addr_x = 10'bZ;
                addr_y = 10'bZ;
                data_out = 32'bZ;
                done_recieving = 1;
            end else begin
                addr_x = 10'bZ;
                addr_y = 10'bZ;
                data_out = 32'bZ;
                done_recieving = 0;
            end 
        end

    end



endmodule
