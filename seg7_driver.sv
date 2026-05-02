
//I used two 4 7-segment displays to display eight digits total, each digit is 4 bits, so 8 digits * 4 bits each = 32 bits.
//outputs are clk_out: serial clock to TM1637 
//dio: serial data to TM1637, bidirectional so inout
module seg7_driver (input logic clk, input logic rst, input logic[31:0] digits, output logic clk_out1, output logic dio1, output logic clk_out2, output logic dio2);

    logic[5:0] count = 0;
    logic[2:0] bit_counter;
    logic[2:0] byte_counter;
    logic [7:0] CMD_BYTE = 8'h40;
    logic [7:0] ADDR_BYTE = 8'hC0;

    //counter, 27MHz / 250kHz = 108, so you toggle the output clk twice every 54 cycles bc the FPGA's clk is too high.
    always_ff @(posedge clk) begin

        if (rst) begin
            count <= 0;
            clk_out1 <= 0;
            clk_out2 <= 0;
        end else if (count == 53) begin
            count <= 0;
            clk_out1 <= ~clk_out1;
            clk_out2 <= ~clk_out2;
        end else begin
            count <= count + 1;
        end

    end

    //maps a 4 bit digit to the 8 bit segment pattern that the TM1637 expects. each bits controls one segment (a-g + a decimal point), so for example abcdef lights up all segments making a zero.
    function [7:0] seg7;
        input logic[3:0] digit;

        case(digit)

            4'd0: seg7 = 8'b00111111; // abcdef
            4'd1: seg7 = 8'b00000110; // bc
            4'd2: seg7 = 8'b01011011; // abdeg
            4'd3: seg7 = 8'b01001111; // abcdg
            4'd4: seg7 = 8'b01100110; // bcfg
            4'd5: seg7 = 8'b01101101; // acdfg
            4'd6: seg7 = 8'b01111101; // acdefg
            4'd7: seg7 = 8'b00000111; // abc
            4'd8: seg7 = 8'b01111111; // all
            4'd9: seg7 = 8'b01101111; // abcdfg
            default: seg7 = 8'b00000000;

        endcase
    endfunction

    //arr thats 8 long and holds 8 bits per index, with each index representing the pattern to give
    logic [7:0] seg_data [7:0];

    //assigns each index by running the digits thru the function to find the pattern to give
    assign seg_data[0] = seg7(digits[3:0]);
    assign seg_data[1] = seg7(digits[7:4]);
    assign seg_data[2] = seg7(digits[11:8]);
    assign seg_data[3] = seg7(digits[15:12]);
    assign seg_data[4] = seg7(digits[19:16]);
    assign seg_data[5] = seg7(digits[23:20]);
    assign seg_data[6] = seg7(digits[27:24]);
    assign seg_data[7] = seg7(digits[31:28]);

    typedef enum logic[3:0] {
        IDLE, //0
        START, //1
        SEND_CMD, //2
        SEND_BYTE, //3
        SEND_ADDR, //4
        WAIT_ACK, //5
        STOP //6
    } state_t;

    state_t state;
    logic phase;

    //PHASE 0: goes from start -> send_cmd -> wait_ack -> stop
    //PHASE 1: goes from start -> send_addr -> wait_ack -> send_byte -> wait_ack -> stop

    always_ff @(posedge clk_out1 or posedge rst) begin

        if (rst) begin
            state <= IDLE;
            bit_counter <= 0;
            byte_counter <= 0;
            phase <= 0;
        end else begin
            case (state)

                IDLE: state <= START; //continuous refresh
                START: begin
                    dio1 <= 0;
                    dio2 <= 0;
                    if (phase == 0) begin
                        state <= SEND_CMD;
                    end else begin
                        state <= SEND_ADDR;
                    end
                end
                SEND_CMD: begin

                    dio1 <= CMD_BYTE[bit_counter]; //put current bit of 0x40 onto DIO wire
                    dio2 <= CMD_BYTE[bit_counter]; //the same for the second display

                    if (bit_counter == 7) begin //after all eight bits send u move on
                        state <= WAIT_ACK;
                        bit_counter <= 0;
                    end else begin
                        bit_counter <= bit_counter + 1; //otherwise, send next bit next clock
                    end
                    
                end
                SEND_BYTE: begin

                    dio1 <= seg_data[byte_counter][bit_counter]; //now sending actual segment data, still tracks by 8 bytes
                    dio2 <= seg_data[byte_counter + 4][bit_counter];

                    if (bit_counter == 7) begin //after all eight bits send u move on            
                        state <= WAIT_ACK;                      
                        bit_counter <= 0;
                        byte_counter <= byte_counter + 1;
                    end else begin
                        bit_counter <= bit_counter + 1; //otherwise, send next bit next clock
                    end
                end
                SEND_ADDR: begin

                    dio1 <= ADDR_BYTE[bit_counter]; //put current bit of 0xCok wai0 onto DIO wire
                    dio2 <= ADDR_BYTE[bit_counter]; //the same for the second display

                    if (bit_counter == 7) begin //after all eight bits send u move on
                        state <= WAIT_ACK;
                        bit_counter <= 0;
                    end else begin
                        bit_counter <= bit_counter + 1; //otherwise, send next bit next clock
                    end

                end
                WAIT_ACK: begin
                    dio1 <= 1;
                    dio2 <= 1;

                    if (phase == 0) begin
                        state <= STOP;
                    end else begin
                        if (byte_counter == 4) begin //4 because byte_counter is already incremented at the end of each byte, so after sending byte 3 it increments to 4.
                            state <= STOP;
                        end else begin
                            state <= SEND_BYTE;
                        end
                    end
                    
                end
                STOP: begin
                    dio1 <= 1;
                    dio2 <= 1;

                    if (phase == 0) begin
                        phase <= 1;
                        state <= START;
                    end else begin 
                        phase <= 0;
                        byte_counter <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule