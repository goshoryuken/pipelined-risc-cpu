module instruction_memory(input logic[15:0] address_in, output logic[15:0] instruction_out);

    logic[15:0] addresses[255:0];

    initial begin
        $readmemh("program.hex", addresses, 0, 255);
    end

    assign instruction_out = addresses[address_in];

endmodule