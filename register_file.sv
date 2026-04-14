module register_file (input logic clk,
  input logic write_enable,
  input logic [2:0] write_addr, 
  input logic[15:0] write_data, 
  input logic [2:0] read_addr1, 
  input logic[2:0] read_addr2, 
  output logic[15:0] read_data1,
  output logic[15:0] read_data2);


    logic [15:0] registers[7:0];

    //initializing the arr at the start of simulation

    initial begin

        for (int i = 0; i < 8; i++) begin
            registers[i] = 16'h0000;
        end

    end

    always_ff @(posedge clk) begin

        if (write_enable == 1) begin
            registers[write_addr] <= write_data;
        end

    end
    
    //if we read the same register we are currently writing to,
    //bypass the memory array and grab the "write_data" directly.

    //basically checks if the address we are tryna read  is the same as the address we are writing too right now.
    //and if it is, you just grab the data sitting on the write_data wire and pass it thru
    assign read_data1 = (write_enable && (read_addr1 == write_addr)) ? write_data : registers[read_addr1];
    assign read_data2 = (write_enable && (read_addr2 == write_addr)) ? write_data : registers[read_addr2];




endmodule