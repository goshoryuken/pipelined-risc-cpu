module top(input logic clk, input logic reset, output logic[15:0] result);

    cpu cpu_inst(
        .clk(clk),
        .reset(reset),
        .result(result)
    );


endmodule