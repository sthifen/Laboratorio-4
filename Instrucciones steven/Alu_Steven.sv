`timescale 1ns / 1ps
//==============================================================================
// ALU Básica RISC-V
// Instrucciones: add, sub, and, or, xor, jal
//==============================================================================

module alu_basica (
    input clk,
    input resetn,
    
    // Interfaz de instrucción
    input [31:0] instruction,
    input [31:0] pc,           // Program counter (para jal)
    input [31:0] rs1_data,     // Dato del registro rs1
    input [31:0] rs2_data,     // Dato del registro rs2
    input        valid,        // Señal de instrucción válida
    
    // Salidas
    output reg [31:0] result,  // Resultado de la operación
    output reg [31:0] next_pc, // Siguiente PC (para jal)
    output reg        result_valid,
    output reg        is_jump  // Indica si es un salto
);

//==============================================================================
// Decodificación de instrucción
//==============================================================================

wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];
wire [4:0] rd     = instruction[11:7];
wire [4:0] rs1    = instruction[19:15];
wire [4:0] rs2    = instruction[24:20];

// Inmediatos
wire [31:0] imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

// Opcodes
localparam OP_REG  = 7'b0110011; // Tipo R: add, sub, and, or, xor
localparam OP_JAL  = 7'b1101111; // Tipo J: jal

// Decodificación de operaciones tipo R
wire is_add = (opcode == OP_REG) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
wire is_sub = (opcode == OP_REG) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
wire is_and = (opcode == OP_REG) && (funct3 == 3'b111) && (funct7 == 7'b0000000);
wire is_or  = (opcode == OP_REG) && (funct3 == 3'b110) && (funct7 == 7'b0000000);
wire is_xor = (opcode == OP_REG) && (funct3 == 3'b100) && (funct7 == 7'b0000000);
wire is_jal = (opcode == OP_JAL);

//==============================================================================
// Lógica de ejecución
//==============================================================================

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        result       <= 32'h0;
        next_pc      <= 32'h0;
        result_valid <= 1'b0;
        is_jump      <= 1'b0;
    end else begin
        if (valid) begin
            result_valid <= 1'b1;
            is_jump      <= 1'b0;
            next_pc      <= pc + 4; // Default: siguiente instrucción
            
            case (1'b1)
                is_add: begin
                    result <= rs1_data + rs2_data;
                    $display("T=%0t ALU: ADD x%0d = x%0d + x%0d = %h + %h = %h", 
                             $time, rd, rs1, rs2, rs1_data, rs2_data, rs1_data + rs2_data);
                end
                
                is_sub: begin
                    result <= rs1_data - rs2_data;
                    $display("T=%0t ALU: SUB x%0d = x%0d - x%0d = %h - %h = %h", 
                             $time, rd, rs1, rs2, rs1_data, rs2_data, rs1_data - rs2_data);
                end
                
                is_and: begin
                    result <= rs1_data & rs2_data;
                    $display("T=%0t ALU: AND x%0d = x%0d & x%0d = %h & %h = %h", 
                             $time, rd, rs1, rs2, rs1_data, rs2_data, rs1_data & rs2_data);
                end
                
                is_or: begin
                    result <= rs1_data | rs2_data;
                    $display("T=%0t ALU: OR x%0d = x%0d | x%0d = %h | %h = %h", 
                             $time, rd, rs1, rs2, rs1_data, rs2_data, rs1_data | rs2_data);
                end
                
                is_xor: begin
                    result <= rs1_data ^ rs2_data;
                    $display("T=%0t ALU: XOR x%0d = x%0d ^ x%0d = %h ^ %h = %h", 
                             $time, rd, rs1, rs2, rs1_data, rs2_data, rs1_data ^ rs2_data);
                end
                
                is_jal: begin
                    result  <= pc + 4;  // Guardar PC+4 en rd
                    next_pc <= pc + imm_j; // Saltar a PC + offset
                    is_jump <= 1'b1;
                    $display("T=%0t ALU: JAL x%0d = %h (return addr), jump to %h", 
                             $time, rd, pc + 4, pc + imm_j);
                end
                
                default: begin
                    result <= 32'h0;
                    result_valid <= 1'b0;
                    $display("T=%0t ALU: UNKNOWN instruction %h", $time, instruction);
                end
            endcase
        end else begin
            result_valid <= 1'b0;
        end
    end
end

endmodule