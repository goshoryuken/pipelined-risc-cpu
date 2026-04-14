module alu(input logic[15:0] x, input logic[15:0] y, input logic[2:0] operation, output logic[16:0] result, output logic zero_flag);

    parameter addition = 3'b000;
    parameter subtraction = 3'b001;
    parameter and_op = 3'b010;
    parameter or_op = 3'b011;
    parameter shift_left = 3'b100;
    parameter shift_right = 3'b101;
    parameter xor_op = 3'b110;
    parameter not_op = 3'b111;

    always_comb begin

        case (operation)

            3'b000: begin
                result = x + y;
            end
            3'b001: begin
                result = x - y;
            end
            3'b010: begin
                result = x & y;
            end
            3'b011: begin
                result = x | y;
            end
            3'b100: begin
                result = x << 1;
            end
            3'b101: begin
                result = x >> 1;
            end
            3'b110: begin
                result = (x & ~y) | (~x & y);
            end
            3'b111: begin
                result = ~x;
            end



        endcase

    end

    //checks if the last result was zero
    //needed for BEQ,
    assign zero_flag = (result[15:0] == 16'h0000);


endmodule