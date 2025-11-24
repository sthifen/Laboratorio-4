`timescale 1ns/1ps

module tb_diego_complete;

    logic        clk;
    logic        rst;
    logic        pcpi_valid;
    logic [31:0] pcpi_insn;
    logic [31:0] pcpi_rs1;
    logic [31:0] pcpi_rs2;
    logic        pcpi_wr;
    logic [31:0] pcpi_rd;
    logic        pcpi_wait;
    logic        pcpi_ready;
    
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic        mem_valid;
    logic        mem_ready;
    logic [31:0] mem_rdata;
    
    // Función helper para generar instrucciones tipo S
    function automatic [31:0] gen_s_type(
        input [6:0] opcode,
        input [2:0] funct3,
        input [4:0] rs1,
        input [4:0] rs2,
        input [11:0] imm
    );
        gen_s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction
    
    // Instanciación del DUT
    diego_alu_extension dut (
        .clk_i(clk),
        .rst_i(rst),
        .pcpi_valid_i(pcpi_valid),
        .pcpi_insn_i(pcpi_insn),
        .pcpi_rs1_i(pcpi_rs1),
        .pcpi_rs2_i(pcpi_rs2),
        .pcpi_wr_o(pcpi_wr),
        .pcpi_rd_o(pcpi_rd),
        .pcpi_wait_o(pcpi_wait),
        .pcpi_ready_o(pcpi_ready),
        .mem_addr_o(mem_addr),
        .mem_wdata_o(mem_wdata),
        .mem_wstrb_o(mem_wstrb),
        .mem_valid_o(mem_valid),
        .mem_ready_i(mem_ready),
        .mem_rdata_i(mem_rdata)
    );
    
    // Generación de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end
    
    // Memoria simple para el testbench
    logic [31:0] memory [0:1023];
    
    // Controlador de memoria (CORREGIDO)
    always @(posedge clk) begin
        if (rst) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0;
        end
        else begin
            mem_ready <= 1'b0;
            
            if (mem_valid) begin
                if (|mem_wstrb) begin
                    // Escritura - byte por byte según mem_wstrb
                    if (mem_wstrb[0]) memory[mem_addr[11:2]][7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) memory[mem_addr[11:2]][15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) memory[mem_addr[11:2]][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
                    $display("    [MEM WRITE] Addr=0x%h Data=0x%h Index=%0d", 
                             mem_addr, mem_wdata, mem_addr[11:2]);
                end
                else begin
                    // Lectura
                    mem_rdata <= memory[mem_addr[11:2]];
                    $display("    [MEM READ] Addr=0x%h Data=0x%h Index=%0d", 
                             mem_addr, memory[mem_addr[11:2]], mem_addr[11:2]);
                end
                mem_ready <= 1'b1;
            end
        end
    end
    
    // ========================================================================
    // PROCESO DE TESTS
    // ========================================================================
    initial begin
        $display("========================================");
        $display("  Test de Instrucciones de Diego");
        $display("========================================\n");
        
        // Inicialización
        rst = 1;
        pcpi_valid = 0;
        pcpi_insn = 0;
        pcpi_rs1 = 0;
        pcpi_rs2 = 0;
        
        // Inicializar memoria con valores de prueba
        for (int i = 0; i < 1024; i++) begin
            memory[i] = 32'h0;
        end
        memory[16] = 32'hDEADBEEF;  // Para el test de LW
        
        #20;
        rst = 0;
        #20;
        
        // ====================================================================
        // TEST 1: SLLI - Shift Left Logical Immediate
        // ====================================================================
        $display("TEST 1: SLLI x1, x2, 4");
        $display("  rs1 = 0x0000000F (15)");
        pcpi_valid = 1;
        pcpi_insn = 32'b0000000_00100_00010_001_00001_0010011; // SLLI x1, x2, 4
        pcpi_rs1 = 32'h0000_000F;
        pcpi_rs2 = 32'h0;
        #10;
        wait(pcpi_ready);
        $display("  Resultado: 0x%h (esperado: 0xF0)", pcpi_rd);
        if (pcpi_rd == 32'hF0)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("SLLI falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 2: SRLI - Shift Right Logical Immediate
        // ====================================================================
        $display("TEST 2: SRLI x1, x2, 2");
        $display("  rs1 = 0xFFFFFFFF");
        pcpi_valid = 1;
        pcpi_insn = 32'b0000000_00010_00010_101_00001_0010011; // SRLI x1, x2, 2
        pcpi_rs1 = 32'hFFFF_FFFF;
        #10;
        wait(pcpi_ready);
        $display("  Resultado: 0x%h (esperado: 0x3FFFFFFF)", pcpi_rd);
        if (pcpi_rd == 32'h3FFF_FFFF)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("SRLI falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 3: SRAI - Shift Right Arithmetic Immediate
        // ====================================================================
        $display("TEST 3: SRAI x1, x2, 2");
        $display("  rs1 = 0xFFFFFFFF (signed: -1)");
        pcpi_valid = 1;
        pcpi_insn = 32'b0100000_00010_00010_101_00001_0010011; // SRAI x1, x2, 2
        pcpi_rs1 = 32'hFFFF_FFFF;
        #10;
        wait(pcpi_ready);
        $display("  Resultado: 0x%h (esperado: 0xFFFFFFFF)", pcpi_rd);
        if (pcpi_rd == 32'hFFFF_FFFF)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("SRAI falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 4: SLL - Shift Left Logical (registro)
        // ====================================================================
        $display("TEST 4: SLL x1, x2, x3");
        $display("  rs1 = 0x00000001, rs2 = 8");
        pcpi_valid = 1;
        pcpi_insn = 32'b0000000_00011_00010_001_00001_0110011; // SLL x1, x2, x3
        pcpi_rs1 = 32'h0000_0001;
        pcpi_rs2 = 32'h0000_0008;
        #10;
        wait(pcpi_ready);
        $display("  Resultado: 0x%h (esperado: 0x100)", pcpi_rd);
        if (pcpi_rd == 32'h100)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("SLL falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 5: SRL - Shift Right Logical (registro)
        // ====================================================================
        $display("TEST 5: SRL x1, x2, x3");
        $display("  rs1 = 0xF0000000, rs2 = 4");
        pcpi_valid = 1;
        pcpi_insn = 32'b0000000_00011_00010_101_00001_0110011; // SRL x1, x2, x3
        pcpi_rs1 = 32'hF000_0000;
        pcpi_rs2 = 32'h0000_0004;
        #10;
        wait(pcpi_ready);
        $display("  Resultado: 0x%h (esperado: 0x0F000000)", pcpi_rd);
        if (pcpi_rd == 32'h0F00_0000)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("SRL falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 6: SRA - Shift Right Arithmetic (registro)
        // ====================================================================
        $display("TEST 6: SRA x1, x2, x3");
        $display("  rs1 = 0xF0000000 (signed), rs2 = 4");
        pcpi_valid = 1;
        pcpi_insn = 32'b0100000_00011_00010_101_00001_0110011; // SRA x1, x2, x3
        pcpi_rs1 = 32'hF000_0000;
        pcpi_rs2 = 32'h0000_0004;
        #10;
        wait(pcpi_ready);
        $display("  Resultado: 0x%h (esperado: 0xFF000000)", pcpi_rd);
        if (pcpi_rd == 32'hFF00_0000)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("SRA falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 7: LW - Load Word
        // ====================================================================
        $display("TEST 7: LW x1, 64(x2)");
        $display("  rs1 = 0x00000000, offset = 64");
        $display("  Dirección efectiva: 0x00000040 (índice 16)");
        pcpi_valid = 1;
        pcpi_insn = 32'b000001000000_00010_010_00001_0000011; // LW x1, 64(x2)
        pcpi_rs1 = 32'h0000_0000;
        #10;
        wait(pcpi_ready);
        $display("  Dato cargado: 0x%h (esperado: 0xDEADBEEF)", pcpi_rd);
        if (pcpi_rd == 32'hDEAD_BEEF)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL\n");
            $error("LW falló!");
        end
        pcpi_valid = 0;
        #20;
        
        // ====================================================================
        // TEST 8: SW - Store Word (CORREGIDO)
        // ====================================================================
        $display("TEST 8: SW x3, 8(x2)");
        $display("  rs1 = 0x00000000, offset = 8, rs2 = 0xCAFEBABE");
        $display("  Dirección efectiva: 0x00000008 (índice 2)");
        pcpi_valid = 1;
        // Usar la función helper para generar la instrucción correctamente
        pcpi_insn = gen_s_type(7'b0100011, 3'b010, 5'd2, 5'd3, 12'd8); // SW x3, 8(x2)
        pcpi_rs1 = 32'h0000_0000;
        pcpi_rs2 = 32'hCAFE_BABE;
        #10;
        wait(pcpi_ready);
        pcpi_valid = 0;
        #20; // Esperar a que se complete la escritura
        $display("  Verificando memoria[2]: 0x%h (esperado: 0xCAFEBABE)", memory[2]);
        if (memory[2] == 32'hCAFE_BABE)
            $display("  ✓ PASS\n");
        else begin
            $display("  ✗ FAIL");
            $display("  Valor encontrado: 0x%h\n", memory[2]);
            $error("SW falló!");
        end
        
        // ====================================================================
        // RESUMEN FINAL
        // ====================================================================
        $display("========================================");
        $display("  ✓✓✓ TODOS LOS TESTS PASARON ✓✓✓");
        $display("========================================");
        
        #100;
        $finish;
    end
    
    // Timeout de seguridad
    initial begin
        #10000;
        $display("\n========================================");
        $display("  ✗ ERROR: TIMEOUT!");
        $display("========================================");
        $finish;
    end

endmodule
