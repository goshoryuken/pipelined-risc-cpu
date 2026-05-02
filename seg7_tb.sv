`timescale 1ns/1ps

module seg7_tb;
	logic clk = 1'b0;
	logic rst_n = 1'b0;
	logic [31:0] digits = 32'h0000;
	logic dio1;
    logic dio2;
	logic clk_out1;
    logic clk_out2;

	// Adjust port names here if seg7_driver.sv differs.
	seg7_driver dut (
		.clk     (clk),
		.rst   (rst_n),
		.digits  (digits),
		.dio1     (dio1),
        .dio2     (dio2),
		.clk_out1 (clk_out1),
        .clk_out2 (clk_out2)
	);

	always #5 clk = ~clk;

	initial begin
        $dumpfile("seg7_tb.vcd");
        $dumpvars(0, seg7_tb);

		// Reset
		rst_n = 1'b1;
		digits = 32'h00000000;
		repeat (200) @(posedge clk);
		rst_n = 1'b0;

		// Drive some visible values for GTKWave.
		digits = 32'h12345678;
		repeat (2000) @(posedge clk);

		digits = 32'h39829038;
		repeat (2000) @(posedge clk);

		digits = 32'h98712349;
		repeat (2000) @(posedge clk);

		$finish;
	end
endmodule
