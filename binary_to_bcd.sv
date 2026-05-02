module binary_to_bcd(input logic[15:0] bin, output logic[19:0] bcd);

    logic[19:0] temp;
    integer i;

    always_comb begin
        temp = 0; // start with all digits at zero

        for (i = 0; i < 16; i = i + 1) begin
            // if any BCD digit is 5 or more, add 3 to correct it before shifting
            if (temp[3:0] >= 5)   temp[3:0]   = temp[3:0] + 3;   // ones
            if (temp[7:4] >= 5)   temp[7:4]   = temp[7:4] + 3;   // tens
            if (temp[11:8] >= 5)  temp[11:8]  = temp[11:8] + 3;  // hundreds
            if (temp[15:12] >= 5) temp[15:12] = temp[15:12] + 3; // thousands
            if (temp[19:16] >= 5) temp[19:16] = temp[19:16] + 3; // ten-thousands

            // shift temp left by 1 and pull in the next bit from binary input (MSB first)
            temp = temp << 1 | (bin >> (15 - i)) & 1;
        end

        bcd = temp; // assign the final BCD result to output
    end

endmodule