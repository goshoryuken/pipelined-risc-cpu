module data_memory(input logic clk, 
input logic write_enable, 
input logic[15:0] write_addr, 
input logic[15:0] write_data, 
input logic[15:0] read_addr, 
output logic[15:0] read_data);

logic [15:0] memory[255:0];

initial begin
    memory[0] = 0;
    memory[1] = 1;
    memory[2] = 0;
    

end

always_ff @(posedge clk) begin

    if (write_enable == 1) begin
        memory[write_addr] <= write_data;
    end

end

assign read_data = memory[read_addr];

endmodule