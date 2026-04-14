module cpu_tb;

    logic clk;
    logic reset;
    logic [15:0] result;

    cpu uut(
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    always #1 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #100;
        reset = 0;
        #500;
        $finish;
    end

    initial begin
        wait(reset == 0); 
        repeat(5) @(posedge clk); 
    
        $display("NEW FIBONACCI FOUND:     0"); // The Seed from r1
        $display("NEW FIBONACCI FOUND:     1"); // The Seed from r2
    end

    always @(posedge clk) begin

    

        if (uut.reg_file_inst.write_enable && (uut.reg_file_inst.write_addr == 3'd5)) begin
            $display("NEW FIBONACCI FOUND: %d", uut.reg_file_inst.write_data);
        end

    end

    

endmodule