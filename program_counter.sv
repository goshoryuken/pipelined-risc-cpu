module program_counter(input logic branch, input logic[15:0] branch_addr, input logic pc_write_enable, input logic clk, input logic reset, output logic[15:0] pc_out);

always_ff @(posedge clk) begin
    if (reset == 1) begin
        pc_out <= 0;
    end
    else if(branch == 1) begin
        pc_out <= branch_addr;
    end
    //pc_write_enable is equal to not stalling so it checks if it wont stall before moving forward.
    else if (pc_write_enable) begin
        pc_out <= pc_out + 1;
    end

end

endmodule