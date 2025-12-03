`timescale 1ns/1ps

module top_pcpi_led_fpga (
    input  logic        clk_100MHz,   // reloj de la tarjeta (CLK100MHZ)
    input  logic        reset_btn,    // botón de reset (CPU_RESET)
    output logic [15:0] led           // LEDs físicos de la FPGA
);
    //======================================================================
    // 1) Divisor de reloj: 100 MHz -> 10 MHz
    //======================================================================
    logic clk_10MHz;
    logic [3:0] div_cnt;

    always_ff @(posedge clk_100MHz or posedge reset_btn) begin
        if (reset_btn) begin
            div_cnt   <= 4'd0;
            clk_10MHz <= 1'b0;
        end else begin
            if (div_cnt == 4'd4) begin
                div_cnt   <= 4'd0;
                clk_10MHz <= ~clk_10MHz; // 100 MHz / (2*5) = 10 MHz
            end else begin
                div_cnt <= div_cnt + 4'd1;
            end
        end
    end

    //======================================================================
    // 2) Señales internas (mismas que en tb_unified_pcpi)
    //======================================================================
    logic        resetn;

    // Interfaz PCPI
    logic        pcpi_valid;
    logic [31:0] pcpi_insn;
    logic [31:0] pcpi_rs1;
    logic [31:0] pcpi_rs2;
    logic        pcpi_wr;
    logic [31:0] pcpi_rd;
    logic        pcpi_wait;
    logic        pcpi_ready;

    // Interfaz de memoria hacia el PCPI
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic        mem_valid;
    logic        mem_ready;
    logic [31:0] mem_rdata;

    // PC (program counter)
    logic [31:0] pc_current;
    logic [31:0] pc_next;
    logic        is_jump;

    // ROM / RAM / banco de registros
    localparam ROM_SIZE = 1024;
    localparam RAM_SIZE = 1024;

    logic [31:0] rom [0:ROM_SIZE-1];
    logic [31:0] ram [0:RAM_SIZE-1];
    logic [31:0] registers [0:31];

    // Periférico LED mapeado en memoria
    localparam LED_ADDR = 32'h0000_2004;
    logic [15:0] led_reg;

    // Conectar registro de LEDs a los pines físicos
    assign led = led_reg;

    //======================================================================
    // 3) Reset síncrono (activo bajo resetn)
    //======================================================================
    always_ff @(posedge clk_10MHz or posedge reset_btn) begin
        if (reset_btn) begin
            resetn <= 1'b0;
        end else begin
            resetn <= 1'b1;
        end
    end

    //======================================================================
    // 4) Inicialización de ROM, RAM y registros
    //======================================================================
    // ROM inicializada con firmware.hex
    initial begin
        // NOP por defecto
        for (int i = 0; i < ROM_SIZE; i++) begin
            rom[i] = 32'h00000013;
        end
        // Cargar programa de RISC-V
        $readmemh("firmware.hex", rom);
    end

    // RAM y registros inicializados en 0 (solo power-on, no por reset)
    initial begin
        for (int i = 0; i < 32; i++) begin
            registers[i] = 32'h00000000;
        end
        for (int j = 0; j < RAM_SIZE; j++) begin
            ram[j] = 32'h00000000;
        end
    end

    //======================================================================
    // 5) Instancia del módulo PCPI unificado
    //======================================================================
    unified_pcpi_module dut (
        .clk        (clk_10MHz),
        .resetn     (resetn),
        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_wait  (pcpi_wait),
        .pcpi_ready (pcpi_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_valid  (mem_valid),
        .mem_ready  (mem_ready),
        .mem_rdata  (mem_rdata),
        .pc_current (pc_current),
        .pc_next    (pc_next),
        .is_jump    (is_jump)
    );

    //======================================================================
    // 6) Control de memoria + periférico LED (sin $display)
    //======================================================================
    always_ff @(posedge clk_10MHz or negedge resetn) begin
        if (!resetn) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0;
            led_reg   <= 16'h0000;
        end else begin
            mem_ready <= 1'b0;

            if (mem_valid) begin
                logic [31:0] word_addr;
                word_addr = mem_addr >> 2;

                // Escritura
                if (mem_wstrb != 4'b0000) begin
                    // Mapeo de LEDs en 0x00002004
                    if (mem_addr == LED_ADDR) begin
                        led_reg <= mem_wdata[15:0];
                    end
                    // RAM normal
                    else if (word_addr < RAM_SIZE) begin
                        if (mem_wstrb[0]) ram[word_addr][7:0]   <= mem_wdata[7:0];
                        if (mem_wstrb[1]) ram[word_addr][15:8]  <= mem_wdata[15:8];
                        if (mem_wstrb[2]) ram[word_addr][23:16] <= mem_wdata[23:16];
                        if (mem_wstrb[3]) ram[word_addr][31:24] <= mem_wdata[31:24];
                    end
                end
                // Lectura
                else begin
                    if (word_addr < RAM_SIZE)
                        mem_rdata <= ram[word_addr];
                    else
                        mem_rdata <= 32'hDEADBEEF;
                end

                mem_ready <= 1'b1;
            end
        end
    end

    //======================================================================
    // 7) "Core" sencillo: máquina de estados tipo tb_unified_pcpi
    //    FETCH -> DECODE -> EXECUTE -> WRITEBACK -> (loop / HALT)
    //======================================================================

    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        WRITEBACK,
        HALT
    } state_t;

    state_t      state;
    logic [31:0] current_instruction;
    logic [4:0]  rd_addr, rs1_addr, rs2_addr;
    logic [31:0] instruction_count;
    logic [31:0] cycle_count;

    // PC en words para acceso a ROM
    logic [31:0] pc_word;
    assign pc_word = pc_current >> 2;

    always_ff @(posedge clk_10MHz or negedge resetn) begin
        if (!resetn) begin
            state              <= FETCH;
            pc_current         <= 32'h00000000;
            pcpi_valid         <= 1'b0;
            pcpi_insn          <= 32'h00000013;
            pcpi_rs1           <= 32'h0;
            pcpi_rs2           <= 32'h0;
            current_instruction<= 32'h00000013;
            instruction_count  <= 32'h00000000;
            cycle_count        <= 32'h00000000;
        end else begin
            cycle_count <= cycle_count + 1;

            case (state)
                //----------------------------------------------------------
                // FETCH: leer instrucción de la ROM
                //----------------------------------------------------------
                FETCH: begin
                    if (pc_word < ROM_SIZE) begin
                        current_instruction <= rom[pc_word];

                        // si es 0 o DEADBEEF la tratamos como HALT
                        if (rom[pc_word] == 32'h00000000 ||
                            rom[pc_word] == 32'hDEADBEEF) begin
                            state <= HALT;
                        end else begin
                            state <= DECODE;
                        end
                    end else begin
                        // PC fuera de rango -> HALT
                        state <= HALT;
                    end
                end

                //----------------------------------------------------------
                // DECODE: sacar rd, rs1, rs2 y preparar operandos para PCPI
                //----------------------------------------------------------
                DECODE: begin
                    rd_addr  <= current_instruction[11:7];
                    rs1_addr <= current_instruction[19:15];
                    rs2_addr <= current_instruction[24:20];

                    pcpi_rs1 <= registers[current_instruction[19:15]];
                    pcpi_rs2 <= registers[current_instruction[24:20]];

                    pcpi_insn  <= current_instruction;
                    pcpi_valid <= 1'b1;

                    state <= EXECUTE;
                end

                //----------------------------------------------------------
                // EXECUTE: esperar a que el PCPI termine (ready/wait)
                //----------------------------------------------------------
                EXECUTE: begin
                    if (pcpi_ready) begin
                        // resultado listo
                        pcpi_valid <= 1'b0;
                        state      <= WRITEBACK;
                    end else if (!pcpi_wait) begin
                        // operación combinacional / no soportada
                        pcpi_valid <= 1'b0;
                        state      <= WRITEBACK;
                    end
                    // si pcpi_wait == 1, nos quedamos en EXECUTE
                end

                //----------------------------------------------------------
                // WRITEBACK: escribir registros y actualizar PC
                //----------------------------------------------------------
                WRITEBACK: begin
                    // Escribir resultado si corresponde
                    if (pcpi_wr && (rd_addr != 5'd0)) begin
                        registers[rd_addr] <= pcpi_rd;
                    end

                    // Actualizar PC según salto o secuencial
                    if (is_jump) begin
                        pc_current <= pc_next;
                    end else begin
                        pc_current <= pc_current + 32'd4;
                    end

                    instruction_count <= instruction_count + 1;

                    // Volver a FETCH para la siguiente instrucción
                    state <= FETCH;
                end

                //----------------------------------------------------------
                // HALT: el core se queda parado (no hay $finish en FPGA)
                //----------------------------------------------------------
                HALT: begin
                    pcpi_valid <= 1'b0;
                    pc_current <= pc_current; // mantener PC
                end

                default: state <= FETCH;
            endcase
        end
    end

endmodule
