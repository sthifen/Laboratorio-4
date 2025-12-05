`timescale 1ns/1ps
// ============================================================================
// Unidad de Load/Store
// Autor: Diego
// Instrucciones: LW, SW
// Interfaz con memoria del sistema
// ============================================================================

module load_store_unit (
    input  logic        clk_i,
    input  logic        rst_i,
    
    // Señales de control
    input  logic        is_load_i,
    input  logic        is_store_i,
    input  logic        enable_i,        // Habilitar operación
    
    // Datos de entrada
    input  logic [31:0] base_addr_i,     // Valor de rs1
    input  logic [31:0] offset_i,        // Inmediato
    input  logic [31:0] store_data_i,    // Valor de rs2 (para SW)
    
    // Interfaz de memoria
    output logic [31:0] mem_addr_o,      // Dirección de memoria
    output logic [31:0] mem_wdata_o,     // Datos a escribir
    output logic [3:0]  mem_wstrb_o,     // Write strobe (byte enable)
    output logic        mem_valid_o,     // Solicitud válida
    input  logic        mem_ready_i,     // Memoria lista
    input  logic [31:0] mem_rdata_i,     // Datos leídos de memoria
    
    // Salidas
    output logic [31:0] load_data_o,     // Datos cargados (para LW)
    output logic        operation_done_o // Operación completada
);

    // ========================================================================
    // Cálculo de dirección efectiva
    // ========================================================================
    logic [31:0] effective_addr;
    
    always_comb begin
        // Dirección efectiva = base + offset
        effective_addr = base_addr_i + offset_i;
    end
    
    // ========================================================================
    // Máquina de estados para control de memoria
    // ========================================================================
    typedef enum logic [1:0] {
        IDLE,
        MEM_ACCESS,
        DONE
    } state_t;
    
    state_t current_state, next_state;
    
    // Transiciones de estado
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end
    
    // Lógica de próximo estado
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (enable_i && (is_load_i || is_store_i)) begin
                    next_state = MEM_ACCESS;
                end
            end
            
            MEM_ACCESS: begin
                if (mem_ready_i) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ========================================================================
    // Salidas de control
    // ========================================================================
    always_comb begin
        // Valores por defecto
        mem_addr_o = 32'h0;
        mem_wdata_o = 32'h0;
        mem_wstrb_o = 4'b0000;
        mem_valid_o = 1'b0;
        operation_done_o = 1'b0;
        
        case (current_state)
            MEM_ACCESS: begin
                mem_addr_o = effective_addr;
                mem_valid_o = 1'b1;
                
                if (is_store_i) begin
                    // Store Word: escribir 32 bits
                    mem_wdata_o = store_data_i;
                    mem_wstrb_o = 4'b1111; // Escribir los 4 bytes
                end
                else begin
                    // Load: solo leer (wstrb = 0)
                    mem_wstrb_o = 4'b0000;
                end
            end
            
            DONE: begin
                operation_done_o = 1'b1;
            end
            
            default: begin
                // IDLE: todas las señales en default
            end
        endcase
    end
    
    // ========================================================================
    // Captura de datos leídos
    // ========================================================================
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            load_data_o <= 32'h0;
        end
        else if (current_state == MEM_ACCESS && is_load_i && mem_ready_i) begin
            load_data_o <= mem_rdata_i;
        end
    end

endmodule
