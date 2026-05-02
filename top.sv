//instantiates all the stuff together for deployment on the FPGA
module top(input logic clk, input logic rst, output logic clk_out1, output logic clk_out2, output logic dio1, output logic dio2);

    logic[15:0] result;
    logic[19:0] bcd;

    cpu cpu_inst(
        .clk(clk),
        .rst(rst),
        .result(result)
    );

    binary_to_bcd binary_to_bcd_inst(
        .result(result),
        .bcd(bcd)
    );

    seg7_driver display(
        .clk(clk),
        .rst(rst),
        .digits({12'b0, bcd}), //bcd is only 20 bits but driver wants 32, js pads the rest w zeros
        .clk_out1(clk_out1),
        .dio1(dio1),
        .clk_out2(clk_out2),
        .dio2(dio2)
    );

endmodule