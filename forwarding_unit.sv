module forwarding_unit(
input logic[2:0] id_ex_read_addr1, 
input logic[2:0] id_ex_read_addr2,
input logic[2:0] ex_mem_write_addr, 
input logic ex_mem_reg_write_enable, 
input logic[2:0] mem_wb_write_addr, 
input logic mem_wb_reg_write_enable,
output logic[1:0] forward_a,
output logic[1:0] forward_b
);

    always_comb begin

        if (ex_mem_reg_write_enable == 1 && ex_mem_write_addr == id_ex_read_addr1) begin
            forward_a = 2'b10;
        end else if (mem_wb_reg_write_enable == 1 && mem_wb_write_addr == id_ex_read_addr1) begin
            forward_a = 2'b01;
        end else begin
            forward_a = 2'b00;
        end

        if (ex_mem_reg_write_enable == 1 && ex_mem_write_addr == id_ex_read_addr2) begin
            forward_b = 2'b10;
        end else if (mem_wb_reg_write_enable == 1 && mem_wb_write_addr == id_ex_read_addr2) begin
            forward_b = 2'b01;
        end else begin
            forward_b = 2'b00;
        end

    end



endmodule