// ============================================================================
// Unidad de Shift (Desplazamiento)
// Autor: Diego
// Implementación: Barrel Shifter combinacional (1 ciclo)
// Soporta: SLL, SLLI, SRL, SRLI, SRA, SRAI
// ============================================================================

module shifter_unit (
    // Entradas
    input  logic [31:0] operand_a_i,       // Valor a desplazar
    input  logic [4:0]  shift_amount_i,    // Cantidad de desplazamiento (0-31)
    input  logic        shift_left_i,      // 1=izquierda, 0=derecha
    input  logic        shift_arithmetic_i, // 1=aritmético, 0=lógico
    
    // Salida
    output logic [31:0] result_o
);

    // ========================================================================
    // Implementación de Barrel Shifter
    // Desplaza en 1 ciclo usando lógica combinacional
    // ========================================================================
    
    logic [31:0] reversed_operand;
    logic [31:0] shift_right_result;
    logic [31:0] final_result;
    
    // Para shifts a la izquierda, invertimos, hacemos shift a la derecha, y volvemos a invertir
    always_comb begin
        // Revertir bits para shift izquierdo
        for (int i = 0; i < 32; i++) begin
            reversed_operand[i] = operand_a_i[31-i];
        end
    end
    
    // Shift a la derecha (lógico o aritmético)
    always_comb begin
        if (shift_arithmetic_i) begin
            // Shift aritmético: preserva el bit de signo
            shift_right_result = $signed(operand_a_i) >>> shift_amount_i;
        end
        else begin
            // Shift lógico: rellena con ceros
            shift_right_result = operand_a_i >> shift_amount_i;
        end
    end
    
    // Multiplexor final según dirección
    always_comb begin
        if (shift_left_i) begin
            // Para shift izquierdo: revertir, shift derecho, revertir
            logic [31:0] temp_shift;
            temp_shift = reversed_operand >> shift_amount_i;
            
            // Revertir el resultado
            for (int i = 0; i < 32; i++) begin
                final_result[i] = temp_shift[31-i];
            end
        end
        else begin
            // Shift derecho directo
            final_result = shift_right_result;
        end
    end
    
    assign result_o = final_result;

endmodule
