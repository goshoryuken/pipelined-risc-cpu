module ram(input logic[15:0] address, input logic clk, input logic[15:0] data_in, input logic write_enable, output logic[15:0] data_out);

    logic [15:0] mem[255:0];

    always_ff @(posedge clk) begin
        
        if (write_enable) begin
            //take the first 8 bits cuz the upper 8 will js be zeros for this program anyways
            mem[address[7:0]] <= data_in;
        end
        data_out <= mem[address[7:0]];
    end

endmodule