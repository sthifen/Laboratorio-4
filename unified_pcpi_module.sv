`timescale 1ns / 1ps
//==============================================================================
// Módulo PCPI Unificado - Integración de ALUs
// Combina: ALU Básica de Steven + Extensiones de Diego (Load/Store/Shift)
//==============================================================================

module unified_pcpi_module (
    input  logic        clk,
    input  logic        resetn,
    
    // Interfaz PCPI estándar (compatible con PicoRV32)
    input  logic        pcpi_valid,      // Instrucción válida del core
    input  logic [31:0] pcpi_insn,       // Instrucción a ejecutar
    input  logic [31:0] pcpi_rs1,        // Valor del registro rs1
    input  logic [31:0] pcpi_rs2,        // Valor del registro rs2
    
    output logic        pcpi_wr,         // Escribir resultado en rd
    output logic [31:0] pcpi_rd,         // Resultado de la operación
    output logic        pcpi_wait,       // Coprocesador ocupado
    output logic        pcpi_ready,      // Operación completada
    
    // Interfaz de memoria (para Load/Store)
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0]  mem_wstrb,
    output logic        mem_valid,
    input  logic        mem_ready,
    input  logic [31:0] mem_rdata,
    
    // PC actual (para JAL)
    input  logic [31:0] pc_current,
    output logic [31:0] pc_next,         // Próximo PC (para saltos)
    output logic        is_jump          // Indica si hay salto
);

    //==========================================================================
    // Decodificación de instrucción
    //==========================================================================
    wire [6:0] opcode = pcpi_insn[6:0];
    wire [2:0] funct3 = pcpi_insn[14:12];
    wire [6:0] funct7 = pcpi_insn[31:25];
    wire [4:0] rd     = pcpi_insn[11:7];
    wire [4:0] rs1    = pcpi_insn[19:15];
    wire [4:0] rs2    = pcpi_insn[24:20];
    
    // Opcodes
    localparam OP_REG   = 7'b0110011;  // Tipo R: add, sub, and, or, xor
    localparam OP_JAL   = 7'b1101111;  // Tipo J: jal
    localparam OP_LOAD  = 7'b0000011;  // Load instructions
    localparam OP_STORE = 7'b0100011;  // Store instructions
    localparam OP_IMM   = 7'b0010011;  // Immediate operations (addi, shifts)
    
    // Inmediato para JAL
    wire [31:0] imm_j = {{12{pcpi_insn[31]}}, pcpi_insn[19:12], 
                         pcpi_insn[20], pcpi_insn[30:21], 1'b0};
    
    // Inmediato para ADDI (I-type)
    wire [31:0] imm_i = {{20{pcpi_insn[31]}}, pcpi_insn[31:20]};
    
    //==========================================================================
    // Detección de tipo de instrucción - ALU Básica (Steven)
    //==========================================================================
    wire is_add = (opcode == OP_REG) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
    wire is_sub = (opcode == OP_REG) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
    wire is_and = (opcode == OP_REG) && (funct3 == 3'b111) && (funct7 == 7'b0000000);
    wire is_or  = (opcode == OP_REG) && (funct3 == 3'b110) && (funct7 == 7'b0000000);
    wire is_xor = (opcode == OP_REG) && (funct3 == 3'b100) && (funct7 == 7'b0000000);
    wire is_jal = (opcode == OP_JAL);
    wire is_addi = (opcode == OP_IMM) && (funct3 == 3'b000);  // ADDI
    
    wire is_steven_alu = is_add | is_sub | is_and | is_or | is_xor | is_jal | is_addi;
    
    //==========================================================================
    // Señales para extensiones de Diego
    //==========================================================================
    logic diego_is_load, diego_is_store, diego_is_shift;
    logic diego_shift_left, diego_shift_arithmetic, diego_shift_immediate;
    logic [4:0] diego_shamt;
    logic [31:0] diego_immediate;
    
    logic [31:0] diego_result;
    logic diego_ready;
    logic diego_wr;
    logic diego_wait;
    
    wire is_diego_extension = diego_is_load | diego_is_store | diego_is_shift;
    
    //==========================================================================
    // Instanciación del Decoder de Diego
    //==========================================================================
    decoder_load_store_shift diego_decoder (
        .instruction_i(pcpi_insn),
        .is_load_o(diego_is_load),
        .is_store_o(diego_is_store),
        .is_shift_o(diego_is_shift),
        .shift_left_o(diego_shift_left),
        .shift_arithmetic_o(diego_shift_arithmetic),
        .shift_immediate_o(diego_shift_immediate),
        .rs1_o(),  // No usado, tomamos directo de pcpi_insn
        .rs2_o(),
        .rd_o(),
        .immediate_o(diego_immediate),
        .shamt_o(diego_shamt)
    );
    
    //==========================================================================
    // Shifter Unit de Diego
    //==========================================================================
    logic [31:0] shift_result;
    logic [4:0] shift_amount;
    
    assign shift_amount = diego_shift_immediate ? diego_shamt : pcpi_rs2[4:0];
    
    shifter_unit diego_shifter (
        .operand_a_i(pcpi_rs1),
        .shift_amount_i(shift_amount),
        .shift_left_i(diego_shift_left),
        .shift_arithmetic_i(diego_shift_arithmetic),
        .result_o(shift_result)
    );
    
    //==========================================================================
    // Load/Store Unit de Diego
    //==========================================================================
    logic [31:0] load_data;
    logic ls_operation_done;
    logic ls_enable;
    
    assign ls_enable = pcpi_valid && (diego_is_load || diego_is_store);
    
    load_store_unit diego_ls_unit (
        .clk_i(clk),
        .rst_i(~resetn),
        .is_load_i(diego_is_load),
        .is_store_i(diego_is_store),
        .enable_i(ls_enable),
        .base_addr_i(pcpi_rs1),
        .offset_i(diego_immediate),
        .store_data_i(pcpi_rs2),
        .mem_addr_o(mem_addr),
        .mem_wdata_o(mem_wdata),
        .mem_wstrb_o(mem_wstrb),
        .mem_valid_o(mem_valid),
        .mem_ready_i(mem_ready),
        .mem_rdata_i(mem_rdata),
        .load_data_o(load_data),
        .operation_done_o(ls_operation_done)
    );
    
    //==========================================================================
    // Lógica de control y multiplexado de resultados
    //==========================================================================
    logic [31:0] steven_result;
    logic steven_ready;
    logic steven_wr;
    logic steven_is_jump;
    logic [31:0] steven_pc_next;
    
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            steven_result <= 32'h0;
            steven_ready <= 1'b0;
            steven_wr <= 1'b0;
            steven_is_jump <= 1'b0;
            steven_pc_next <= 32'h0;
        end
        else begin
            if (pcpi_valid && is_steven_alu) begin
                steven_ready <= 1'b1;
                steven_wr <= 1'b1;
                steven_is_jump <= is_jal;
                steven_pc_next <= is_jal ? (pc_current + imm_j) : (pc_current + 4);
                
                case (1'b1)
                    is_add: begin
                        steven_result <= pcpi_rs1 + pcpi_rs2;
                        $display("[T=%0t] ALU_STEVEN: ADD x%0d = x%0d + x%0d = 0x%08h", 
                                 $time, rd, rs1, rs2, pcpi_rs1 + pcpi_rs2);
                    end
                    
                    is_addi: begin
                        steven_result <= pcpi_rs1 + imm_i;
                        $display("[T=%0t] ALU_STEVEN: ADDI x%0d = x%0d + %0d = 0x%08h", 
                                 $time, rd, rs1, $signed(imm_i), pcpi_rs1 + imm_i);
                    end
                    
                    is_sub: begin
                        steven_result <= pcpi_rs1 - pcpi_rs2;
                        $display("[T=%0t] ALU_STEVEN: SUB x%0d = x%0d - x%0d = 0x%08h", 
                                 $time, rd, rs1, rs2, pcpi_rs1 - pcpi_rs2);
                    end
                    
                    is_and: begin
                        steven_result <= pcpi_rs1 & pcpi_rs2;
                        $display("[T=%0t] ALU_STEVEN: AND x%0d = x%0d & x%0d = 0x%08h", 
                                 $time, rd, rs1, rs2, pcpi_rs1 & pcpi_rs2);
                    end
                    
                    is_or: begin
                        steven_result <= pcpi_rs1 | pcpi_rs2;
                        $display("[T=%0t] ALU_STEVEN: OR x%0d = x%0d | x%0d = 0x%08h", 
                                 $time, rd, rs1, rs2, pcpi_rs1 | pcpi_rs2);
                    end
                    
                    is_xor: begin
                        steven_result <= pcpi_rs1 ^ pcpi_rs2;
                        $display("[T=%0t] ALU_STEVEN: XOR x%0d = x%0d ^ x%0d = 0x%08h", 
                                 $time, rd, rs1, rs2, pcpi_rs1 ^ pcpi_rs2);
                    end
                    
                    is_jal: begin
                        steven_result <= pc_current + 4;
                        $display("[T=%0t] ALU_STEVEN: JAL x%0d = PC+4 = 0x%08h, jump to 0x%08h", 
                                 $time, rd, pc_current + 4, pc_current + imm_j);
                    end
                    
                    default: begin
                        steven_result <= 32'h0;
                        steven_wr <= 1'b0;
                    end
                endcase
            end
            else begin
                steven_ready <= 1'b0;
                steven_wr <= 1'b0;
                steven_is_jump <= 1'b0;
            end
        end
    end
    
    //==========================================================================
    // Control de Diego Extensions
    //==========================================================================
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            diego_ready <= 1'b0;
            diego_wr <= 1'b0;
            diego_result <= 32'h0;
        end
        else begin
            if (pcpi_valid && is_diego_extension) begin
                if (diego_is_shift) begin
                    // Shifts se completan en 1 ciclo
                    diego_ready <= 1'b1;
                    diego_wr <= 1'b1;
                    diego_result <= shift_result;
                    $display("[T=%0t] ALU_DIEGO: SHIFT x%0d = 0x%08h", 
                             $time, rd, shift_result);
                end
                else if (diego_is_load && ls_operation_done) begin
                    diego_ready <= 1'b1;
                    diego_wr <= 1'b1;
                    diego_result <= load_data;
                    $display("[T=%0t] ALU_DIEGO: LOAD x%0d = [0x%08h] = 0x%08h", 
                             $time, rd, mem_addr, load_data);
                end
                else if (diego_is_store && ls_operation_done) begin
                    diego_ready <= 1'b1;
                    diego_wr <= 1'b0;  // Store no escribe registro
                    diego_result <= 32'h0;
                    $display("[T=%0t] ALU_DIEGO: STORE [0x%08h] = 0x%08h", 
                             $time, mem_addr, pcpi_rs2);
                end
                else begin
                    // Esperando load/store
                    diego_ready <= 1'b0;
                    diego_wr <= 1'b0;
                end
            end
            else begin
                diego_ready <= 1'b0;
                diego_wr <= 1'b0;
            end
        end
    end
    
    assign diego_wait = pcpi_valid && (diego_is_load || diego_is_store) && !ls_operation_done;
    
    //==========================================================================
    // Multiplexado de salidas PCPI
    //==========================================================================
    always_comb begin
        if (is_steven_alu) begin
            pcpi_rd = steven_result;
            pcpi_ready = steven_ready;
            pcpi_wr = steven_wr;
            pcpi_wait = 1'b0;
            pc_next = steven_pc_next;
            is_jump = steven_is_jump;
        end
        else if (is_diego_extension) begin
            pcpi_rd = diego_result;
            pcpi_ready = diego_ready;
            pcpi_wr = diego_wr;
            pcpi_wait = diego_wait;
            pc_next = pc_current + 4;
            is_jump = 1'b0;
        end
        else begin
            // Instrucción no reconocida
            pcpi_rd = 32'h0;
            pcpi_ready = 1'b0;
            pcpi_wr = 1'b0;
            pcpi_wait = 1'b0;
            pc_next = pc_current + 4;
            is_jump = 1'b0;
        end
    end
    
endmodule