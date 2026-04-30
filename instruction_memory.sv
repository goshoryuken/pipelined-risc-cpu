module instruction_memory(input logic[15:0] address_in, output logic[15:0] instruction_out);

    logic[15:0] addresses[255:0];

    `ifdef SIMULATION
    initial begin
        $readmemh("program.hex", addresses, 0, 255);
    end
    assign instruction_out = addresses[address_in[7:0]];
    `else
    //this is hardcoded for the fibonacci sequence, cuz readmemh might not work on an FPGA.
    always_comb begin
    case (address_in)
        16'h0000: instruction_out = 16'h6200;
        16'h0001: instruction_out = 16'h6401;
        16'h0002: instruction_out = 16'h6002;
        16'h0003: instruction_out = 16'h0A50;
        16'h0004: instruction_out = 16'h0280;
        16'h0005: instruction_out = 16'h0540;
        16'h0006: instruction_out = 16'h8005;
        default: instruction_out = 16'h0000;
    endcase
    end
    `endif

    

endmodule