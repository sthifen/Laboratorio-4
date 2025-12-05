`timescale 1ns / 1ps
//==============================================================================
// Testbench Completo para Módulo PCPI Unificado
// Simula un procesador simple con ROM que lee firmware.hex
//==============================================================================

module tb_unified_pcpi;

    //==========================================================================
    // Señales del testbench
    //==========================================================================
    logic clk;
    logic resetn;
    
    // Señales PCPI
    logic        pcpi_valid;
    logic [31:0] pcpi_insn;
    logic [31:0] pcpi_rs1;
    logic [31:0] pcpi_rs2;
    logic        pcpi_wr;
    logic [31:0] pcpi_rd;
    logic        pcpi_wait;
    logic        pcpi_ready;
    
    // Señales de memoria
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic        mem_valid;
    logic        mem_ready;
    logic [31:0] mem_rdata;
    
    // Señales de PC
    logic [31:0] pc_current;
    logic [31:0] pc_next;
    logic        is_jump;
    
    //==========================================================================
    // ROM y RAM
    //==========================================================================
    parameter ROM_SIZE = 1024;  // 1K words = 4KB
    parameter RAM_SIZE = 1024;  // 1K words = 4KB
    localparam string DEFAULT_FIRMWARE = "firmware/firmware.hex";
    
    logic [31:0] rom [0:ROM_SIZE-1];
    logic [31:0] ram [0:RAM_SIZE-1];
    
    // Banco de registros simulado
    logic [31:0] registers [0:31];
    
    // Periférico de LEDs mapeado en memoria (16 LSBs en 0x00002004)
    localparam LED_ADDR = 32'h0000_2004;
    logic [15:0] led_reg;

    
    //==========================================================================
    // Generación de reloj
    //==========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Periodo de 10ns = 100MHz
    end
    
    //==========================================================================
    // Carga del firmware desde archivo HEX
    //==========================================================================
    initial begin
        $display("=============================================================");
        $display("Testbench para Módulo PCPI Unificado (Steven + Diego)");
        $display("=============================================================");
        
        // Inicializar memorias
        for (int i = 0; i < ROM_SIZE; i++) rom[i] = 32'h00000013; // NOP
        for (int i = 0; i < RAM_SIZE; i++) ram[i] = 32'h00000000;
        for (int i = 0; i < 32; i++) registers[i] = 32'h00000000;
        
        // Cargar firmware
        if ($test$plusargs("firmware")) begin
            string firmware_file;
            if ($value$plusargs("firmware=%s", firmware_file)) begin
                $display("[INFO] Cargando firmware desde: %s", firmware_file);
                $readmemh(firmware_file, rom);
            end
        end else begin
            $display("[INFO] Cargando %s por defecto", DEFAULT_FIRMWARE);
            $readmemh(DEFAULT_FIRMWARE, rom);
        end
        
        // Mostrar primeras instrucciones cargadas
        $display("\n[INFO] Primeras 10 instrucciones en ROM:");
        for (int i = 0; i < 10; i++) begin
            $display("  ROM[0x%03h] = 0x%08h", i*4, rom[i]);
        end
        $display("");
    end
    
    //==========================================================================
    // Secuencia de reset
    //==========================================================================
    initial begin
        resetn = 0;
        pcpi_valid = 0;
        pc_current = 32'h00000000;
        
        #20;
        resetn = 1;
        $display("[T=%0t] Reset liberado\n", $time);
    end
    
    //==========================================================================
    // Control de simulación (timeout y VCD)
    //==========================================================================
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_unified_pcpi.vcd");
            $dumpvars(0, tb_unified_pcpi);
            $display("[INFO] Generando archivo VCD: tb_unified_pcpi.vcd\n");
        end
        
        // Timeout de simulación
        #100000;  // 100 us
        $display("\n[TIMEOUT] Simulación terminada por timeout");
        $finish;
    end
    
    //==========================================================================
    // Instancia del módulo PCPI unificado
    //==========================================================================
    unified_pcpi_module dut (
        .clk(clk),
        .resetn(resetn),
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready),
        .mem_rdata(mem_rdata),
        .pc_current(pc_current),
        .pc_next(pc_next),
        .is_jump(is_jump)
    );
    
    //==========================================================================
    // Modelo de memoria (RAM + periférico LEDs)
    //==========================================================================
    // Mapa de memoria según especificación:
    // 0x0000-0x0FFF: ROM (instruction)
    // 0x1000-0x1FFF: RAM (data)
    // 0x2004:        LEDs (write)

    logic [31:0] word_addr_ram;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0;
            led_reg   <= 16'h0000;
        end
        else begin
            // Valor por defecto cada ciclo
            mem_ready <= 1'b0;

            if (mem_valid) begin
                // Calcular dirección de RAM (base 0x1000)
                word_addr_ram = (mem_addr - 32'h1000) >> 2;

                //=====================
                //     ESCRITURA
                //=====================
                if (mem_wstrb != 4'b0000) begin
                    // Escritura en LEDs (0x2004)
                    if (mem_addr == LED_ADDR) begin
                        logic [15:0] led_next;
                        led_next = led_reg;
                        if (mem_wstrb[0]) led_next[7:0]  = mem_wdata[7:0];
                        if (mem_wstrb[1]) led_next[15:8] = mem_wdata[15:8];
                        led_reg <= led_next;
                        $display("[T=%0t] [LED] WRITE: leds = 0x%04h (wdata=0x%08h)",
                                 $time, led_next, mem_wdata);
                    end
                    // Escritura en RAM (0x1000-0x1FFF)
                    else if (mem_addr >= 32'h1000 && mem_addr < 32'h2000 && word_addr_ram < RAM_SIZE) begin
                        logic [31:0] ram_next;
                        ram_next = ram[word_addr_ram];
                        if (mem_wstrb[0]) ram_next[7:0]   = mem_wdata[7:0];
                        if (mem_wstrb[1]) ram_next[15:8]  = mem_wdata[15:8];
                        if (mem_wstrb[2]) ram_next[23:16] = mem_wdata[23:16];
                        if (mem_wstrb[3]) ram_next[31:24] = mem_wdata[31:24];
                        ram[word_addr_ram] <= ram_next;
                        $display("[T=%0t] [MEM] WRITE: ram[0x%08h] = 0x%08h",
                                 $time, mem_addr, ram_next);
                    end
                    else begin
                        $display("[T=%0t] [MEM] WRITE fuera de rango en 0x%08h",
                                 $time, mem_addr);
                    end
                end

                //=====================
                //      LECTURA
                //=====================
                else begin
                    // Lectura desde LEDs (0x2004)
                    if (mem_addr == LED_ADDR) begin
                        mem_rdata <= {16'h0000, led_reg};
                        $display("[T=%0t] [LED] READ:  leds = 0x%04h",
                                 $time, led_reg);
                    end
                    // Lectura desde RAM (0x1000-0x1FFF)
                    else if (mem_addr >= 32'h1000 && mem_addr < 32'h2000 && word_addr_ram < RAM_SIZE) begin
                        mem_rdata <= ram[word_addr_ram];
                        $display("[T=%0t] [MEM] READ:  ram[0x%08h] = 0x%08h",
                                 $time, mem_addr, ram[word_addr_ram]);
                    end
                    else begin
                        mem_rdata <= 32'hDEADBEEF;
                        $display("[T=%0t] [MEM] READ fuera de rango en 0x%08h, devolviendo 0xDEADBEEF",
                                 $time, mem_addr);
                    end
                end

                // Respondemos en 1 ciclo
                mem_ready <= 1'b1;
            end
        end
    end

    
    //==========================================================================
    // Simulador simple de fetch/execute
    //==========================================================================
    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        WRITEBACK,
        HALT
    } state_t;
    
    state_t state;
    logic [31:0] current_instruction;
    logic [4:0] rd_addr, rs1_addr, rs2_addr;
    integer instruction_count;
    integer cycle_count;
    
    initial begin
        state = FETCH;
        instruction_count = 0;
        cycle_count = 0;
    end
    
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= FETCH;
            pc_current <= 32'h00000000;
            pcpi_valid <= 1'b0;
            instruction_count <= 0;
            cycle_count <= 0;
        end
        else begin
            cycle_count <= cycle_count + 1;
            
            case (state)
                FETCH: begin
                    // Leer instrucción de ROM
                    logic [31:0] pc_word;
                    pc_word = pc_current >> 2;
                    
                    if (pc_word < ROM_SIZE) begin
                        current_instruction = rom[pc_word];
                        $display("\n[T=%0t] [FETCH] PC=0x%08h  Inst=0x%08h", 
                                 $time, pc_current, rom[pc_word]);
                        
                        // Instrucción de terminación
                        if (current_instruction == 32'h00000000 || 
                            current_instruction == 32'hDEADBEEF) begin
                            $display("\n[INFO] Instrucción de HALT detectada");
                            state <= HALT;
                        end else begin
                            state <= DECODE;
                        end
                    end else begin
                        $display("\n[ERROR] PC fuera de rango: 0x%08h", pc_current);
                        state <= HALT;
                    end
                end
                
                DECODE: begin
                    // Decodificar campos
                    rd_addr  = current_instruction[11:7];
                    rs1_addr = current_instruction[19:15];
                    rs2_addr = current_instruction[24:20];
                    
                    // Leer operandos
                    pcpi_rs1 = registers[rs1_addr];
                    pcpi_rs2 = registers[rs2_addr];
                    
                    $display("[T=%0t] [DECODE] rd=x%0d rs1=x%0d(0x%08h) rs2=x%0d(0x%08h)", 
                             $time, rd_addr, rs1_addr, pcpi_rs1, rs2_addr, pcpi_rs2);
                    
                    // Enviar a PCPI
                    pcpi_insn <= current_instruction;
                    pcpi_valid <= 1'b1;
                    
                    state <= EXECUTE;
                end
                
                EXECUTE: begin
                    if (pcpi_ready) begin
                        $display("[T=%0t] [EXECUTE] Operación completada", $time);
                        pcpi_valid <= 1'b0;
                        state <= WRITEBACK;
                    end
                    else if (pcpi_wait) begin
                        $display("[T=%0t] [EXECUTE] Esperando...", $time);
                        // Mantener valid alto
                    end
                    else begin
                        // Instrucción no reconocida
                        $display("[T=%0t] [EXECUTE] Instrucción no reconocida por PCPI", $time);
                        pcpi_valid <= 1'b0;
                        state <= WRITEBACK;
                    end
                end
                
                WRITEBACK: begin
                    // Escribir resultado si es necesario
                    if (pcpi_wr && rd_addr != 0) begin
                        registers[rd_addr] <= pcpi_rd;
                        $display("[T=%0t] [WRITEBACK] x%0d = 0x%08h", 
                                 $time, rd_addr, pcpi_rd);
                    end
                    
                    // Actualizar PC
                    if (is_jump) begin
                        pc_current <= pc_next;
                        $display("[T=%0t] [WRITEBACK] JUMP to PC=0x%08h\n", 
                                 $time, pc_next);
                    end else begin
                        pc_current <= pc_current + 4;
                        $display("[T=%0t] [WRITEBACK] PC=0x%08h\n", 
                                 $time, pc_current + 4);
                    end
                    
                    instruction_count <= instruction_count + 1;
                    
                    // Limitar instrucciones para prueba
                    if (instruction_count >= 50) begin
                        $display("\n[INFO] Límite de instrucciones alcanzado");
                        state <= HALT;
                    end else begin
                        state <= FETCH;
                    end
                end
                
                HALT: begin
                    $display("\n=============================================================");
                    $display("Simulación finalizada");
                    $display("=============================================================");
                    $display("Instrucciones ejecutadas: %0d", instruction_count);
                    $display("Ciclos de reloj:          %0d", cycle_count);
                    $display("CPI:                      %.2f", 
                             real'(cycle_count) / real'(instruction_count));
                    $display("=============================================================\n");
                    
                    // Mostrar contenido de registros
                    $display("Estado final de registros:");
                    for (int i = 0; i < 32; i++) begin
                        if (registers[i] != 0)
                            $display("  x%02d = 0x%08h", i, registers[i]);
                    end
                    $display("");
                    
                    $finish;
                end
            endcase
        end
    end
    
endmodule
