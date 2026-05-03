module data_memory(
    input logic clk, 
    input logic reset, // Add reset here
    input logic write_enable, 
    input logic[15:0] write_addr, 
    input logic[15:0] write_data, 
    input logic[15:0] read_addr, 
    output logic[15:0] read_data
);

    logic [15:0] memory[255:0];

    // Remove the initial block completely

    always_ff @(posedge clk) begin
        if (reset) begin
            // Initialize your Fib starting values on reset
            memory[0] <= 16'd0;
            memory[1] <= 16'd1;
            memory[2] <= 16'd0;
        end else if (write_enable == 1) begin
            memory[write_addr[7:0]] <= write_data;
        end
    end

    assign read_data = memory[read_addr[7:0]];

endmodule