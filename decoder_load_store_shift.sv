// ============================================================================
// Decoder para instrucciones Load/Store y Shifts
// Autor: Diego
// Fecha: 23 Nov 2024
// Instrucciones: lw, sw, sll, slli, srl, srli, sra, srai
// ============================================================================

module decoder_load_store_shift (
    // Entrada
    input  logic [31:0] instruction_i,
    
    // Señales de control - Load/Store
    output logic is_load_o,
    output logic is_store_o,
    
    // Señales de control - Shifts
    output logic is_shift_o,
    output logic shift_left_o,       // 1=izquierda, 0=derecha
    output logic shift_arithmetic_o, // 1=aritmético, 0=lógico
    output logic shift_immediate_o,  // 1=inmediato, 0=registro
    
    // Campos extraídos
    output logic [4:0]  rs1_o,       // Registro fuente 1
    output logic [4:0]  rs2_o,       // Registro fuente 2
    output logic [4:0]  rd_o,        // Registro destino
    output logic [31:0] immediate_o, // Valor inmediato
    output logic [4:0]  shamt_o      // Shift amount (cantidad de desplazamiento)
);

    // ========================================================================
    // Campos de la instrucción RV32I
    // ========================================================================
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    
    assign opcode = instruction_i[6:0];
    assign funct3 = instruction_i[14:12];
    assign funct7 = instruction_i[31:25];
    
    // Campos de registros
    assign rs1_o = instruction_i[19:15];
    assign rs2_o = instruction_i[24:20];
    assign rd_o  = instruction_i[11:7];
    
    // Shift amount para instrucciones inmediatas
    assign shamt_o = instruction_i[24:20];
    
    // ========================================================================
    // Decodificación de Load/Store
    // ========================================================================
    always_comb begin
        // Detección de instrucciones
        is_load_o  = (opcode == 7'b0000011); // LW - tipo I
        is_store_o = (opcode == 7'b0100011); // SW - tipo S
        
        // Generación de inmediato según el tipo
        if (is_load_o) begin
            // Tipo I: inmediato de 12 bits con signo extendido
            immediate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
        end
        else if (is_store_o) begin
            // Tipo S: inmediato dividido en dos campos
            immediate_o = {{20{instruction_i[31]}}, 
                          instruction_i[31:25], instruction_i[11:7]};
        end
        else begin
            // Para shifts, el inmediato es de 5 bits sin signo
            immediate_o = {27'b0, instruction_i[24:20]};
        end
    end
    
    // ========================================================================
    // Decodificación de Shifts
    // ========================================================================
    always_comb begin
        // Valores por defecto
        is_shift_o = 1'b0;
        shift_left_o = 1'b0;
        shift_arithmetic_o = 1'b0;
        shift_immediate_o = 1'b0;
        
        // Shifts con dos registros (tipo R)
        // Opcode: 0110011 = OP (operaciones registro-registro)
        if (opcode == 7'b0110011) begin
            case (funct3)
                3'b001: begin // SLL - Shift Left Logical
                    is_shift_o = 1'b1;
                    shift_left_o = 1'b1;
                    shift_arithmetic_o = 1'b0;
                    shift_immediate_o = 1'b0;
                end
                
                3'b101: begin // SRL o SRA - Shift Right
                    is_shift_o = 1'b1;
                    shift_left_o = 1'b0;
                    // El bit 30 (funct7[5]) indica si es aritmético
                    shift_arithmetic_o = funct7[5]; 
                    shift_immediate_o = 1'b0;
                end
                
                default: begin
                    is_shift_o = 1'b0;
                end
            endcase
        end
        
        // Shifts con inmediato (tipo I)
        // Opcode: 0010011 = OP-IMM (operaciones con inmediato)
        else if (opcode == 7'b0010011) begin
            case (funct3)
                3'b001: begin // SLLI - Shift Left Logical Immediate
                    is_shift_o = 1'b1;
                    shift_left_o = 1'b1;
                    shift_arithmetic_o = 1'b0;
                    shift_immediate_o = 1'b1;
                end
                
                3'b101: begin // SRLI o SRAI - Shift Right Immediate
                    is_shift_o = 1'b1;
                    shift_left_o = 1'b0;
                    // El bit 30 indica si es aritmético
                    shift_arithmetic_o = instruction_i[30];
                    shift_immediate_o = 1'b1;
                end
                
                default: begin
                    is_shift_o = 1'b0;
                end
            endcase
        end
    end

endmodule
