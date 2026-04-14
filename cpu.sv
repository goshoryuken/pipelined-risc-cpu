module cpu(input logic clk, input logic reset, output logic [15:0] result);
    
    //fetch logic stuff
    logic[15:0] instruction;
    logic[15:0] pc_out;
    logic[15:0] if_id_instruction;
    logic[15:0] if_id_pc;

    //decode logic stuff
    logic[2:0] read_addr1;
    logic[2:0] read_addr2;
    
    assign read_addr1 = if_id_instruction[8:6];
    assign read_addr2 = if_id_instruction[5:3];

    logic[15:0] read_data1;
    logic[15:0] read_data2;
    logic[2:0] alu_op;
    logic alu_src;
    logic mem_write_enable;
    logic reg_write_enable;
    logic mem_read;
    logic mem_to_reg;
    logic branch;
    logic halt;
    logic[2:0] write_addr;
    logic[15:0] immediate;
    assign write_addr = if_id_instruction[11:9];

    //takes the 3rd bit of my instruction, repeats it five times, this way it can handle negative numbers
    assign immediate = {{13{if_id_instruction[2]}}, if_id_instruction[2:0]};
    
    logic[15:0] id_ex_read_data1;
    logic[15:0] id_ex_read_data2;
    logic[2:0] id_ex_alu_op;
    logic[2:0] id_ex_read_addr1;
    logic[2:0] id_ex_read_addr2;
    logic id_ex_alu_src;
    logic id_ex_reg_write_enable;
    logic id_ex_mem_write_enable;
    logic id_ex_mem_read;
    logic id_ex_mem_to_reg;
    logic id_ex_branch;
    logic id_ex_halt;
    logic[2:0] id_ex_write_addr;
    logic[15:0] id_ex_immediate;
    logic[15:0] id_ex_pc;

    //execute logic stuff
    logic[15:0] branch_addr;
    logic[16:0] alu_result;
    assign branch_addr = id_ex_pc + id_ex_immediate;

    logic zero_flag;
    logic actual_branch;
    assign actual_branch = id_ex_branch & zero_flag;

    logic[16:0] ex_mem_alu_result;
    logic[15:0] ex_mem_read_data2;
    logic[15:0] ex_mem_branch_addr;
    logic[2:0] ex_mem_write_addr;
    logic ex_mem_reg_write_enable;
    logic ex_mem_mem_write_enable;
    logic ex_mem_mem_read;
    logic ex_mem_mem_to_reg;
    logic ex_mem_branch;
    logic ex_mem_halt;
    
    //mem logic stuff

    logic[15:0] mem_read_data;
    
    logic[16:0] mem_wb_alu_result;
    logic[15:0] mem_wb_mem_read_data;
    logic[2:0] mem_wb_write_addr;
    logic mem_wb_mem_to_reg;
    logic mem_wb_reg_write_enable;

    //writeback logic stuff
    logic[15:0] write_back_data;

    //forwarding stuff
    logic[1:0] forward_a;
    logic[1:0] forward_b;
    logic[15:0] alu_input_a;
    logic[15:0] alu_input_b;

    

    assign alu_input_a = (forward_a == 2'b10) ? ex_mem_alu_result[15:0] :
                         (forward_a == 2'b01) ? write_back_data :
                         id_ex_read_data1;
    
    logic [15:0] forward_b_data;
    assign forward_b_data = (forward_b == 2'b10) ? ex_mem_alu_result[15:0] :
                         (forward_b == 2'b01) ? write_back_data :
                         id_ex_read_data2;
    assign alu_input_b = id_ex_alu_src ? id_ex_immediate : forward_b_data;
    

    forwarding_unit forward_inst (
        .id_ex_read_addr1(id_ex_read_addr1),
        .id_ex_read_addr2(id_ex_read_addr2),
        .ex_mem_write_addr(ex_mem_write_addr),
        .ex_mem_reg_write_enable(ex_mem_reg_write_enable),
        .mem_wb_write_addr(mem_wb_write_addr),
        .mem_wb_reg_write_enable(mem_wb_reg_write_enable),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );
    

    //stall logic, if there is a hazard, checks if the instruction in the execute stage its tryna get data from memory, but also trying to access that memory simultaneously, then you halt, basically chill out for a sec 
    //waiting for the next clock so you can actually grab it! this prevents me from putting manual "NOP" commands between each assembly line
    logic stall;
    assign stall = id_ex_mem_read && ((id_ex_write_addr == read_addr1) || (id_ex_write_addr == read_addr2));
    


    //if id pipeline register --> sits between fetch and decode
    // holds the fetched instruction until decode stage reads it
    always_ff @(posedge clk) begin
        if (reset || ex_mem_branch) begin
            if_id_instruction <= 0;
            if_id_pc <= 0;
        //checks if its not stalling so it can then assign new instructions, and as such it'll hold the previous values until the next clock cycle.   
        end
        if (!stall) begin   
            if_id_instruction <= instruction;
            if_id_pc <= pc_out;
        end
    end

    //ID/EX pipeline register --> sits between decode and execute
    //holds decoded control signals and register values until execute reads them
    always_ff @(posedge clk) begin
        //if branch signal is high then u zero out everything here for make way for instructions comin from branch target
        if (reset || ex_mem_branch) begin
            id_ex_read_data1 <= 0;
            id_ex_read_data2 <= 0;
            id_ex_alu_op <= 0;
            id_ex_reg_write_enable <= 0;
            id_ex_mem_write_enable <= 0;
            id_ex_mem_read <= 0;
            id_ex_mem_to_reg <= 0;
            id_ex_branch <= 0;
            id_ex_halt <= 0;
            id_ex_write_addr <= 0;
            id_ex_immediate <= 0;
            id_ex_pc <= 0;
            id_ex_read_addr1 <= 0;
            id_ex_read_addr2 <= 0;
            id_ex_alu_src <= 0;
        end else begin
            id_ex_read_data1 <= read_data1;
            id_ex_read_data2 <= read_data2;
            id_ex_alu_op <= alu_op;
            //IF it is gonna stall, then just write 0, if not then continue on
            id_ex_reg_write_enable <= stall ? 1'b0 : reg_write_enable;
            //same here
            id_ex_mem_write_enable <= stall ? 1'b0 : mem_write_enable;
            //conditional check to prevent stalled instruction from triggering a "second" stall cycle.
            id_ex_mem_read <= stall ? 1'b0 : mem_read;
            id_ex_mem_to_reg <= mem_to_reg;
            //to prevent a "ghost" branch from occurring while the pipeline is paused.
            id_ex_branch <= stall ? 1'b0 : branch;
            id_ex_halt <= halt;
            id_ex_write_addr <= write_addr;
            id_ex_immediate <= immediate;
            id_ex_pc <= if_id_pc;
            id_ex_read_addr1 <= read_addr1;
            id_ex_read_addr2 <= read_addr2;
            id_ex_alu_src <= alu_src;
        end

    end

    //EX/MEM pipeline egister --> sits between execute and memory
    //holds ALU result and control signals until memory stage reads them
    always_ff @(posedge clk) begin
    
    if (reset) begin
        ex_mem_read_data2 <= 0;
        ex_mem_branch_addr <= 0;
        ex_mem_write_addr <= 0;
        ex_mem_reg_write_enable <= 0;
        ex_mem_mem_write_enable <= 0;
        ex_mem_mem_read <= 0;
        ex_mem_mem_to_reg <= 0;
        ex_mem_branch <= 0;
        ex_mem_halt <= 0;
        ex_mem_alu_result <= 0;
    end else begin
        ex_mem_read_data2 <= forward_b_data;
        ex_mem_branch_addr <= branch_addr;
        ex_mem_write_addr <= id_ex_write_addr;
        ex_mem_reg_write_enable <= id_ex_reg_write_enable;
        ex_mem_mem_write_enable <= id_ex_mem_write_enable;
        ex_mem_mem_read <= id_ex_mem_read;
        ex_mem_mem_to_reg <= id_ex_mem_to_reg;
        ex_mem_branch <= actual_branch;
        ex_mem_halt <= id_ex_halt;
        ex_mem_alu_result <= alu_result;

        
    end

    end

    //MEM/WB pipeline register --> sits between memory and wrieback
    //holds memory read data and ALU result until writeback reads it
    always_ff @(posedge clk) begin

        if (reset) begin
            mem_wb_alu_result <= 0;
            mem_wb_mem_read_data <= 0;
            mem_wb_write_addr <= 0;
            mem_wb_mem_to_reg <= 0;
            mem_wb_reg_write_enable <= 0;
        end else begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_read_data <= mem_read_data;
            mem_wb_write_addr <= ex_mem_write_addr;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_reg_write_enable <= ex_mem_reg_write_enable;
        end

    end

    //writeback stage --> no pipeline reg cuz it's the last stage
    // selects between memory read data (for LOAD) or ALU result and writes back to the register file
    //purely combinational
    assign write_back_data = mem_wb_mem_to_reg ? mem_wb_mem_read_data : mem_wb_alu_result[15:0];
    assign result = write_back_data;

    logic cpu_halted;
    logic pc_write_enable;
    //halt logic to actually stop the CPU
    always_ff @(posedge clk) begin
        if (reset) begin
            cpu_halted <= 0;
        end else if (ex_mem_halt) begin
            cpu_halted <= 1;
        end
    end
    //if not stalling and the cpu isnt halted then it can enable writing
    assign pc_write_enable = !stall && !cpu_halted;


    
    
    //instantiating the program counter
    program_counter pc (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .branch(ex_mem_branch),
        .branch_addr(ex_mem_branch_addr),
        .pc_write_enable(pc_write_enable)
        
    );

    //instantiating the alu
    alu alu_inst (
        .x(alu_input_a),
        .y(alu_input_b),
        .operation(id_ex_alu_op),
        .result(alu_result),
        .zero_flag(zero_flag)
    );

    //instantiating the control_unit
    control_unit control_unit_inst (
        .instruction(if_id_instruction),
        .alu_op(alu_op),
        .reg_write_enable(reg_write_enable),
        .mem_write_enable(mem_write_enable),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .halt(halt),
        .alu_src(alu_src)
    );

    //instantiating the data memory
    data_memory data_memory_inst (
        .write_enable(ex_mem_mem_write_enable),
        .write_addr(ex_mem_alu_result[15:0]),
        .write_data(ex_mem_read_data2),
        .read_addr(ex_mem_alu_result[15:0]),
        .read_data(mem_read_data),
        .clk(clk)
    );

    //instantiating the instruction memory
    instruction_memory instruction_memory_inst (
        .address_in(pc_out),
        .instruction_out(instruction)
    );

    //instantiating the reg file
    register_file reg_file_inst(
        .clk(clk),
        .write_enable(mem_wb_reg_write_enable),
        .write_data(write_back_data),
        .write_addr(mem_wb_write_addr),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );



endmodule