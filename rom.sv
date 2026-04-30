module rom(input logic [15:0] address, output logic[15:0] data);


    always_comb begin
    case (address)
        16'h0000: data = 16'h6200;
        16'h0001: data = 16'h6401;
        16'h0002: data = 16'h6002;
        16'h0003: data = 16'h0A50;
        16'h0004: data = 16'h0280;
        16'h0005: data = 16'h0540;
        16'h0006: data = 16'h8005;
        default: data = 16'h0000;
    endcase

    end

endmodule