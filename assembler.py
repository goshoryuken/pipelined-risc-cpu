opcodes = {
    "ADD": 0,
    "SUB": 1,
    "AND": 2,
    "OR": 3,
    "SHIFT_LEFT": 4,
    "SHIFT_RIGHT": 5,
    "LOAD": 6,
    "STORE": 7,
    "BEQ": 8,
    "HALT": 9,
    "XOR" : 10,
    "NOT" : 11
}

reg_dict = {
    "r0": 0,
    "r1": 1,
    "r2": 2,
    "r3": 3,
    "r4": 4,
    "r5": 5,
    "r6": 6,
    "r7": 7
}


def encode(assembly_line):

    split_line = assembly_line.split()
    instruction = 0

    match split_line[0]:
        #in order: opcode is [0], dest is [1], src1 is [2], src2 is [3], imm is [4]

        #ALU ops
        case "ADD" | "SUB" | "AND" | "OR" | "SHIFT_LEFT" | "SHIFT_RIGHT" | "XOR":
            instruction = (opcodes[split_line[0]] << 12) | (reg_dict[split_line[1]] << 9) | (int(reg_dict[split_line[2]]) << 6) | (int(reg_dict[split_line[3]]) << 3) 
        #HALT op
        case "HALT":
            instruction = opcodes["HALT"] << 12
        #LOAD op
        case "LOAD":
            instruction = opcodes["LOAD"] << 12 | (reg_dict[split_line[1]] << 9) | int(split_line[2])
        #STORE op
        case "STORE":
            instruction = opcodes["STORE"] << 12 | (reg_dict[split_line[1]] << 3) | int(split_line[2])
        #BEQ op
        case "BEQ":

            #get raw offset (like -2)
            raw_offset = int(split_line[3])

            #mask into 3 bits using the & 0x7(111 in binary)
            three_bit_offset = raw_offset & 0x7

            #pack into uinstruction
            instruction = opcodes["BEQ"] << 12 | (int(reg_dict[split_line[1]]) << 6) | (int(reg_dict[split_line[2]]) << 3) | three_bit_offset
        case "NOT":
            instruction = (opcodes["NOT"] << 12) | (reg_dict[split_line[1]] << 9) | (reg_dict[split_line[2]] << 6)
    

    return instruction

def asm_to_hex(file_path):


    with open(file_path, 'r') as f, open('program.hex','w') as outfile:
        for line in f:
            line = line.strip()
            if line:
                encodedLine = encode(line)
                outfile.write(f"{encodedLine:04X}\n")

asm_to_hex("program.asm")