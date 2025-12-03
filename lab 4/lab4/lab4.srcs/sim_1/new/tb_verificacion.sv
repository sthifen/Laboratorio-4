`timescale 1ns / 1ps

module tb_verificacion;
    
    // Señales del testbench
    reg clk = 1;
    reg resetn = 0;
    wire trap;
    
    // Memoria simulada (4KB = 1024 palabras)
    reg [31:0] memory [0:1023];
    
    // Señales de interfaz con PicoRV32
    wire        mem_valid;
    wire        mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;
    
    // Instanciar el core PicoRV32
    picorv32 #(
        .ENABLE_COUNTERS(0),
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .LATCHED_MEM_RDATA(0),
        .TWO_STAGE_SHIFT(0),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(0),
        .CATCH_ILLINSN(0),
        .ENABLE_PCPI(0),
        .ENABLE_MUL(0),
        .ENABLE_FAST_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
        .ENABLE_TRACE(0),
        .REGS_INIT_ZERO(1),
        .MASKED_IRQ(32'h00000000),
        .LATCHED_IRQ(32'hffffffff),
        .PROGADDR_RESET(32'h00000000),
        .PROGADDR_IRQ(32'h00000010),
        .STACKADDR(32'hffffffff)
    ) uut (
        .clk       (clk),
        .resetn    (resetn),
        .trap      (trap),
        
        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata)
    );
    
    // Generador de reloj (10 MHz = 100ns período)
    always #50 clk = ~clk;
    
    // Controlador de memoria SÍNCRONO
    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 0;
            mem_rdata <= 32'h00000000;
        end else begin
            mem_ready <= mem_valid;
            
            if (mem_valid) begin
                // Escritura
                if (|mem_wstrb && mem_addr < 32'h1000) begin
                    if (mem_wstrb[0]) memory[mem_addr[11:2]][7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) memory[mem_addr[11:2]][15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) memory[mem_addr[11:2]][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
                end
                
                // Lectura
                if (mem_addr < 32'h1000) begin
                    mem_rdata <= memory[mem_addr[11:2]];
                end else begin
                    mem_rdata <= 32'h00000000;
                end
            end
        end
    end
    
    // Acceso a registros internos para monitoreo
    wire [31:0] x1 = uut.cpuregs[1];
    wire [31:0] x2 = uut.cpuregs[2];
    wire [31:0] x3 = uut.cpuregs[3];
    wire [31:0] x5 = uut.cpuregs[5];
    wire [31:0] x6 = uut.cpuregs[6];
    wire [31:0] pc = uut.reg_pc;
    
    integer i;
    integer ciclos;
    
    initial begin
        $dumpfile("test_verificacion.vcd");
        $dumpvars(0, tb_verificacion);
        
        // Inicializar TODA la memoria con NOP (addi x0, x0, 0)
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'h00000013;  // NOP
        end
        
        $display("========================================");
        $display("  CARGANDO PROGRAMA DE PRUEBA");
        $display("========================================");
        
        // PROGRAMA SIMPLIFICADO PARA PROBAR BEQ
        // Addr 0x00: addi x1, x0, 10    (x1 = 10)
        memory[0] = 32'h00a00093;
        $display("[0x00] addi x1, x0, 10");
        
        // Addr 0x04: addi x2, x0, 20    (x2 = 20)
        memory[1] = 32'h01400113;
        $display("[0x04] addi x2, x0, 20");
        
        // Addr 0x08: addi x3, x0, 10    (x3 = 10)
        memory[2] = 32'h00a00193;
        $display("[0x08] addi x3, x0, 10");
        
        // Addr 0x0C: beq x1, x3, +12    (si x1==x3, saltar a 0x18)
        memory[3] = 32'h00308663;
        $display("[0x0C] beq x1, x3, +12");
        
        // Addr 0x10: addi x5, x0, 0xFF  (x5 = 0xFF - ERROR)
        memory[4] = 32'h0ff00293;
        $display("[0x10] addi x5, x0, 0xFF");
        
        // Addr 0x14: jal x0, +8          (saltar a 0x1C)
        memory[5] = 32'h0080006f;
        $display("[0x14] jal x0, +8");
        
        // Addr 0x18: addi x5, x0, 1     (x5 = 1 - OK)
        memory[6] = 32'h00100293;
        $display("[0x18] addi x5, x0, 1");
        
        // Addr 0x1C: jal x0, 0          (loop infinito)
        memory[7] = 32'h0000006f;
        $display("[0x1C] jal x0, 0 (loop infinito)");
        
        $display("========================================");
        $display("  INICIANDO SIMULACIÓN");
        $display("========================================");
        
        ciclos = 0;
        
        // Reset del sistema
        resetn = 0;
        repeat(10) @(posedge clk);
        resetn = 1;
        
        $display("[t=%0t] Reset liberado", $time);
        
        // Esperar ejecución (100 ciclos debería ser suficiente)
        repeat(100) @(posedge clk);
        
        // Mostrar resultados
        $display("");
        $display("========================================");
        $display("  RESULTADOS FINALES");
        $display("========================================");
        $display("PC final    = 0x%h", pc);
        $display("x1 (dato 1) = %0d (esperado: 10)", x1);
        $display("x2 (dato 2) = %0d (esperado: 20)", x2);
        $display("x3 (dato 3) = %0d (esperado: 10)", x3);
        $display("x5 (result) = 0x%h", x5);
        $display("");
        
        if (x5 == 32'h00000001) begin
            $display("✓✓✓ TEST BEQ: PASÓ ✓✓✓");
            $display("El procesador saltó correctamente cuando x1 == x3");
        end else if (x5 == 32'h000000FF) begin
            $display("✗✗✗ TEST BEQ: FALLÓ ✗✗✗");
            $display("El procesador NO saltó cuando debía (x1 == x3)");
        end else begin
            $display("??? Estado desconocido: x5 = 0x%h", x5);
        end
        
        $display("========================================");
        $display("Ciclos ejecutados: %0d", ciclos);
        $display("========================================");
        
        #1000;
        $finish;
    end
    
    // Monitor de actividad
    always @(posedge clk) begin
        if (resetn) begin
            ciclos = ciclos + 1;
            
            if (mem_valid && mem_ready && mem_instr) begin
                $display("[Ciclo %0d] Fetch: PC=0x%h, Instr=0x%h", 
                         ciclos, mem_addr, mem_rdata);
            end
            
            // Detectar cambios en x5
            if (x5 != 0) begin
                $display("[Ciclo %0d] *** x5 cambió a 0x%h ***", ciclos, x5);
            end
        end
    end
    
    // Timeout de seguridad
    initial begin
        #100000;  // 100us
        $display("TIMEOUT: Simulación muy larga");
        $finish;
    end
    
endmodule