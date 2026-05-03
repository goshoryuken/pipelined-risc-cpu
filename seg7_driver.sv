module seg7_driver (
    input  logic        clk,      // 27 MHz system clock
    input  logic        rst,      // Active-high reset
    input  logic [15:0] bcd_in,   // 4 digits of BCD from binary_to_bcd module
    output logic        clk_out,  // To TM1637 CLK (Pin 27)
    inout  wire         dio       // To TM1637 DIO (Pin 28)
);

    // --------------------------------------------------------
    // 1. Tick Generator (27MHz -> ~100kHz state transition)
    // --------------------------------------------------------
    // Each I2C bit will take 3 ticks (30us), yielding a safe ~33kHz I2C clock
    logic [15:0] tick_counter;
    logic        tick;

    always_ff @(posedge clk) begin
        if (rst) begin
            tick_counter <= 0;
            tick <= 0;
        end else if (tick_counter == 269) begin // 27,000,000 / 100,000 = 270
            tick_counter <= 0;
            tick <= 1;
        end else begin
            tick_counter <= tick_counter + 1;
            tick <= 0;
        end
    end

    // --------------------------------------------------------
    // 2. BCD to 7-Segment Decoder
    // --------------------------------------------------------
    function logic [7:0] bcd_to_seg(input logic [3:0] bcd);
        case (bcd)
            4'h0: bcd_to_seg = 8'h3F;
            4'h1: bcd_to_seg = 8'h06;
            4'h2: bcd_to_seg = 8'h5B;
            4'h3: bcd_to_seg = 8'h4F;
            4'h4: bcd_to_seg = 8'h66;
            4'h5: bcd_to_seg = 8'h6D;
            4'h6: bcd_to_seg = 8'h7D;
            4'h7: bcd_to_seg = 8'h07;
            4'h8: bcd_to_seg = 8'h7F;
            4'h9: bcd_to_seg = 8'h6F;
            default: bcd_to_seg = 8'h00; // Blank
        endcase
    endfunction

    logic [7:0] seg_data [0:3];
    assign seg_data[0] = bcd_to_seg(bcd_in[3:0]);   // LSB (Right-most digit)
    assign seg_data[1] = bcd_to_seg(bcd_in[7:4]);
    assign seg_data[2] = bcd_to_seg(bcd_in[11:8]);
    assign seg_data[3] = bcd_to_seg(bcd_in[15:12]); // MSB (Left-most digit)

    // --------------------------------------------------------
    // 3. Macro Instruction Sequencer (The ROM)
    // --------------------------------------------------------
    logic [3:0] prog_pc;
    logic [2:0] macro_op;
    logic [7:0] macro_data;

    localparam OP_START = 3'd0;
    localparam OP_SEND  = 3'd1;
    localparam OP_STOP  = 3'd2;
    localparam OP_DONE  = 3'd3;

    always_comb begin
        case (prog_pc)
            // Phase 0: Write Data Command
            0:  {macro_op, macro_data} = {OP_START, 8'h00}; 
            1:  {macro_op, macro_data} = {OP_SEND,  8'h40}; // 0x40 = Write data to display register
            2:  {macro_op, macro_data} = {OP_STOP,  8'h00}; 

            // Phase 1: Address and Data
            3:  {macro_op, macro_data} = {OP_START, 8'h00};
            4:  {macro_op, macro_data} = {OP_SEND,  8'hC0}; // 0xC0 = Starting address (Left-most)
            5:  {macro_op, macro_data} = {OP_SEND,  seg_data[3]}; // Send MSB (Thousands) first
            6:  {macro_op, macro_data} = {OP_SEND,  seg_data[2]}; 
            7:  {macro_op, macro_data} = {OP_SEND,  seg_data[1]};
            8:  {macro_op, macro_data} = {OP_SEND,  seg_data[0]}; // Send LSB (Ones) last
            9:  {macro_op, macro_data} = {OP_STOP,  8'h00}; 

            // Phase 2: Display Control
            10: {macro_op, macro_data} = {OP_START, 8'h00}; 
            11: {macro_op, macro_data} = {OP_SEND,  8'h8F}; // 0x8F = Display ON, Max brightness
            12: {macro_op, macro_data} = {OP_STOP,  8'h00}; 

            // Loop back to continually refresh the display
            13: {macro_op, macro_data} = {OP_DONE,  8'h00}; 
            default: {macro_op, macro_data} = {OP_DONE, 8'h00};
        endcase
    end

    // --------------------------------------------------------
    // 4. Low-Level Pin Control FSM
    // --------------------------------------------------------
    // Tri-state buffer logic for DIO
    logic dio_out;
    logic dio_dir; // 1 = Output, 0 = Input (High-Z)
    assign dio = dio_dir ? dio_out : 1'bz;

    // State Machine
    typedef enum logic [3:0] {
        ST_INIT, ST_FETCH,
        ST_START_1, ST_START_2,
        ST_SEND_1, ST_SEND_2, ST_SEND_3,
        ST_ACK_1, ST_ACK_2, ST_ACK_3,
        ST_STOP_1, ST_STOP_2, ST_STOP_3
    } state_t;

    state_t state;
    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= ST_INIT;
            prog_pc  <= 0;
            clk_out  <= 1;
            dio_out  <= 1;
            dio_dir  <= 1;
            bit_cnt  <= 0;
            shift_reg<= 0;
        end else if (tick) begin
            case (state)
                ST_INIT: begin
                    clk_out <= 1;
                    dio_out <= 1;
                    dio_dir <= 1;
                    prog_pc <= 0;
                    state   <= ST_FETCH;
                end

                ST_FETCH: begin
                    if (macro_op == OP_START) begin
                        state <= ST_START_1;
                    end else if (macro_op == OP_SEND) begin
                        shift_reg <= macro_data;
                        bit_cnt   <= 0;
                        state     <= ST_SEND_1;
                    end else if (macro_op == OP_STOP) begin
                        state <= ST_STOP_1;
                    end else if (macro_op == OP_DONE) begin
                        prog_pc <= 0; // Restart loop to grab new BCD values
                        state   <= ST_INIT; 
                    end
                end

                // --- START CONDITION ---
                ST_START_1: begin
                    dio_out <= 0; // DIO goes Low while CLK is High
                    state   <= ST_START_2;
                end
                ST_START_2: begin
                    clk_out <= 0; // Pull CLK low to prepare for data
                    prog_pc <= prog_pc + 1;
                    state   <= ST_FETCH;
                end

                // --- SEND BYTE (LSB First) ---
                ST_SEND_1: begin
                    dio_out <= shift_reg[0]; // Set DIO while CLK is Low
                    state   <= ST_SEND_2;
                end
                ST_SEND_2: begin
                    clk_out <= 1;            // TM1637 reads data here
                    state   <= ST_SEND_3;
                end
                ST_SEND_3: begin
                    clk_out   <= 0;          // CLK back low
                    shift_reg <= {1'b0, shift_reg[7:1]};
                    if (bit_cnt == 7) begin
                        state <= ST_ACK_1;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                        state   <= ST_SEND_1;
                    end
                end

                // --- WAIT FOR ACK ---
                ST_ACK_1: begin
                    dio_dir <= 0; // High-Z, let TM1637 pull down
                    state   <= ST_ACK_2;
                end
                ST_ACK_2: begin
                    clk_out <= 1; // 9th Clock pulse High
                    state   <= ST_ACK_3;
                end
                ST_ACK_3: begin
                    clk_out <= 0; // 9th Clock pulse Low
                    dio_dir <= 1; // Take back control of DIO
                    dio_out <= 0; // Default drive low
                    prog_pc <= prog_pc + 1;
                    state   <= ST_FETCH;
                end

                // --- STOP CONDITION ---
                ST_STOP_1: begin
                    dio_out <= 0; // Ensure DIO is Low
                    state   <= ST_STOP_2;
                end
                ST_STOP_2: begin
                    clk_out <= 1; // CLK goes High
                    state   <= ST_STOP_3;
                end
                ST_STOP_3: begin
                    dio_out <= 1; // DIO goes High while CLK is High
                    prog_pc <= prog_pc + 1;
                    state   <= ST_FETCH;
                end

                default: state <= ST_INIT;
            endcase
        end
    end

endmodule