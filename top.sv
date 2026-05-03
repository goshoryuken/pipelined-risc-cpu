module top (
    input  logic clk,
    input  logic rst,
    output logic clk_out1,
    inout  wire  dio1,
    output logic clk_out2,
    inout  wire  dio2,
    output logic overflow_led
);

    // invert reset (Tang Nano button is active-low)
    logic rst_internal;
    assign rst_internal = ~rst;

    // slow clock for CPU so you can watch Fibonacci count up
    logic [24:0] cpu_div;
    logic cpu_clk;
    always_ff @(posedge clk) begin
        if (rst_internal) cpu_div <= 0;
        else cpu_div <= cpu_div + 1;
    end
    assign cpu_clk = cpu_div[22]; // ~1.6 Hz

    

    // CPU
    logic [15:0] result;
    logic [15:0] fib_out;
    logic [15:0] prev_fib;
    cpu cpu_inst (
        .clk(cpu_clk),
        .reset(rst_internal),
        .result(result),
        .fib_out(fib_out)
    );

    //turns on the LED to indicate that the fib sequence overflowed.
    always_ff @(posedge cpu_clk) begin

        if (rst_internal) begin
            prev_fib <= 0;
            overflow_led <= 0;
        end else begin
            prev_fib <= fib_out;
            if (fib_out < prev_fib) begin //checks then updates, not sequential like software
                    overflow_led <= 1; // stays on
            end
        end

    end

    // Binary to BCD
    logic [19:0] bcd;
    binary_to_bcd binary_to_bcd_inst (
        .bin(fib_out),
        .bcd(bcd)
    );

    // Display 1: lower 4 digits (ones, tens, hundreds, thousands)
    seg7_driver display1 (
        .clk(clk),
        .rst(rst_internal),
        .bcd_in(bcd[15:0]),
        .clk_out(clk_out1),
        .dio(dio1)
    );

    // Display 2: ten-thousands digit, other 3 blanked (0xF hits default = blank)
    seg7_driver display2 (
        .clk(clk),
        .rst(rst_internal),
        .bcd_in({12'hFFF, bcd[19:16]}),
        .clk_out(clk_out2),
        .dio(dio2)
    );

endmodule