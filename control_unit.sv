module control_unit(input logic[15:0] instruction, output logic[2:0] alu_op, output logic reg_write_enable, output logic mem_write_enable, output logic mem_read, output logic mem_to_reg, output logic branch, output logic halt, output logic alu_src);

    parameter addition = 4'b0000;
    parameter subtraction = 4'b0001;
    parameter and_op = 4'b0010;
    parameter or_op = 4'b0011;
    parameter shift_left = 4'b0100;
    parameter shift_right = 4'b0101;
    parameter load = 4'b0110;
    parameter store = 4'b0111;
    parameter beq = 4'b1000;
    parameter halt_op = 4'b1001;
    parameter xor_op = 4'b1010;
    parameter not_op = 4'b1011;

    logic [3:0] opcode;
    assign opcode = instruction[15:12];

    always_comb begin

        case (opcode)

            4'b0000: begin //ADDITION

            alu_op = 3'b000;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0; 
            branch = 0;
            halt = 0;
            alu_src = 0;

            end
            4'b0001: begin //SUBTRACTION

            alu_op = 3'b001;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 0;
            alu_src = 0;

            end
            4'b0010: begin //AND

            alu_op = 3'b010;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 0;
            alu_src = 0;

            end
            4'b0011: begin //OR

            alu_op = 3'b011;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 0;
            alu_src = 0;
            
            end
            4'b0100: begin //SHIFT LEFT

            alu_op = 3'b100;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 0;
            alu_src = 0;

            end
            4'b0101: begin //SHIFT RIGHT

            alu_op = 3'b101;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0; 
            branch = 0;
            halt = 0;
            alu_src = 0;

            end
            4'b0110: begin //LOAD

            alu_op = 3'b000; //add but acts as a placeholder doesn't do anything
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 1;
            mem_to_reg = 1; 
            branch = 0;
            halt = 0;
            alu_src = 1;

            end
            4'b0111: begin //STORE

            alu_op = 3'b000; //add but acts as a placeholder doesn't do anything
            reg_write_enable = 0;
            mem_write_enable = 1;
            mem_read = 0;
            mem_to_reg = 0; 
            branch = 0;
            halt = 0;
            alu_src = 1;

            end
            4'b1000: begin //BEQ

            alu_op = 3'b001; //subtract
            reg_write_enable = 0;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 1;
            halt = 0;
            alu_src = 0;

            end
            4'b1001: begin //HALT

            alu_op = 3'b000; //add but acts as a placeholder doesn't do anything
            reg_write_enable = 0;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 1;
            alu_src = 0;

            end
            4'b1010: begin //XOR
            alu_op = 3'b110;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 0;
            alu_src = 0;
            end
            4'b1011: begin //NOT
            alu_op = 3'b111;
            reg_write_enable = 1;
            mem_write_enable = 0;
            mem_read = 0;
            mem_to_reg = 0;
            branch = 0;
            halt = 0;
            alu_src = 0;
            end
            
            default: begin
                alu_op = 3'b000;
                reg_write_enable = 0;
                mem_write_enable = 0;
                mem_read = 0;
                mem_to_reg = 0;
                branch = 0;
                halt = 0;
                alu_src = 0;
            end
            

        endcase

    end

endmodule