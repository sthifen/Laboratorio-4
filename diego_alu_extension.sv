// ============================================================================
// Wrapper de las extensiones de ALU - Diego
// Integra: Decoder, Shifter, Load/Store
// Este módulo se conectará al PCPI de PicoRV32
// ============================================================================

module diego_alu_extension (
    input  logic        clk_i,
    input  logic        rst_i,
    
    // Interfaz PCPI (compatible con PicoRV32)
    input  logic        pcpi_valid_i,     // Instrucción válida
    input  logic [31:0] pcpi_insn_i,      // Instrucción a ejecutar
    input  logic [31:0] pcpi_rs1_i,       // Valor de rs1
    input  logic [31:0] pcpi_rs2_i,       // Valor de rs2
    
    output logic        pcpi_wr_o,        // Escribir resultado
    output logic [31:0] pcpi_rd_o,        // Resultado
    output logic        pcpi_wait_o,      // Esperando
    output logic        pcpi_ready_o,     // Listo
    
    // Interfaz de memoria (para Load/Store)
    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wdata_o,
    output logic [3:0]  mem_wstrb_o,
    output logic        mem_valid_o,
    input  logic        mem_ready_i,
    input  logic [31:0] mem_rdata_i
);

    // ========================================================================
    // Señales internas del decoder
    // ========================================================================
    logic is_load, is_store, is_shift;
    logic shift_left, shift_arithmetic, shift_immediate;
    logic [4:0] rs1, rs2, rd, shamt;
    logic [31:0] immediate;
    
    // ========================================================================
    // Instanciación del Decoder
    // ========================================================================
    decoder_load_store_shift decoder_inst (
        .instruction_i(pcpi_insn_i),
        .is_load_o(is_load),
        .is_store_o(is_store),
        .is_shift_o(is_shift),
        .shift_left_o(shift_left),
        .shift_arithmetic_o(shift_arithmetic),
        .shift_immediate_o(shift_immediate),
        .rs1_o(rs1),
        .rs2_o(rs2),
        .rd_o(rd),
        .immediate_o(immediate),
        .shamt_o(shamt)
    );
    
    // ========================================================================
    // Señales para Shifter
    // ========================================================================
    logic [31:0] shift_result;
    logic [4:0]  shift_amount;
    
    // Cantidad de shift: inmediato o registro rs2[4:0]
    assign shift_amount = shift_immediate ? shamt : pcpi_rs2_i[4:0];
    
    // Instanciación del Shifter
    shifter_unit shifter_inst (
        .operand_a_i(pcpi_rs1_i),
        .shift_amount_i(shift_amount),
        .shift_left_i(shift_left),
        .shift_arithmetic_i(shift_arithmetic),
        .result_o(shift_result)
    );
    
    // ========================================================================
    // Señales para Load/Store
    // ========================================================================
    logic [31:0] load_data;
    logic        ls_operation_done;
    logic        ls_enable;
    
    // Instanciación de Load/Store Unit
    load_store_unit ls_unit_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .is_load_i(is_load),
        .is_store_i(is_store),
        .enable_i(ls_enable),
        .base_addr_i(pcpi_rs1_i),
        .offset_i(immediate),
        .store_data_i(pcpi_rs2_i),
        .mem_addr_o(mem_addr_o),
        .mem_wdata_o(mem_wdata_o),
        .mem_wstrb_o(mem_wstrb_o),
        .mem_valid_o(mem_valid_o),
        .mem_ready_i(mem_ready_i),
        .mem_rdata_i(mem_rdata_i),
        .load_data_o(load_data),
        .operation_done_o(ls_operation_done)
    );
    
    // ========================================================================
    // Control PCPI
    // ========================================================================
    logic instruction_recognized;
    
    assign instruction_recognized = is_shift || is_load || is_store;
    
    // Habilitar load/store solo cuando hay instrucción válida
    assign ls_enable = pcpi_valid_i && (is_load || is_store);
    
    // ========================================================================
    // Generación de salidas PCPI
    // ========================================================================
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            pcpi_wr_o <= 1'b0;
            pcpi_ready_o <= 1'b0;
            pcpi_rd_o <= 32'h0;
        end
        else begin
            if (pcpi_valid_i && instruction_recognized) begin
                if (is_shift) begin
                    // Shifts se completan en 1 ciclo
                    pcpi_wr_o <= 1'b1;
                    pcpi_ready_o <= 1'b1;
                    pcpi_rd_o <= shift_result;
                end
                else if (is_load && ls_operation_done) begin
                    // Load completado
                    pcpi_wr_o <= 1'b1;
                    pcpi_ready_o <= 1'b1;
                    pcpi_rd_o <= load_data;
                end
                else if (is_store && ls_operation_done) begin
                    // Store completado (no escribe registro)
                    pcpi_wr_o <= 1'b0;
                    pcpi_ready_o <= 1'b1;
                    pcpi_rd_o <= 32'h0;
                end
                else begin
                    // Esperando...
                    pcpi_wr_o <= 1'b0;
                    pcpi_ready_o <= 1'b0;
                end
            end
            else begin
                pcpi_wr_o <= 1'b0;
                pcpi_ready_o <= 1'b0;
            end
        end
    end
    
    // Wait signal: activo mientras procesamos load/store
    assign pcpi_wait_o = pcpi_valid_i && (is_load || is_store) && !ls_operation_done;

endmodule
