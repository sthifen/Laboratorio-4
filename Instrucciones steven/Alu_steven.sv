`timescale 1ns / 1ps
//==============================================================================
// Testbench para ALU Básica RISC-V
// Prueba: add, sub, and, or, xor, jal
//==============================================================================

module tb_alu_basica();

reg clk;
reg resetn;
reg [31:0] instruction;
reg [31:0] pc;
reg [31:0] rs1_data;
reg [31:0] rs2_data;
reg valid;

wire [31:0] result;
wire [31:0] next_pc;
wire result_valid;
wire is_jump;

// Instancia de la ALU
alu_basica uut (
    .clk(clk),
    .resetn(resetn),
    .instruction(instruction),
    .pc(pc),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .valid(valid),
    .result(result),
    .next_pc(next_pc),
    .result_valid(result_valid),
    .is_jump(is_jump)
);

// Generación de reloj (100 MHz = 10ns periodo)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Contador de tests
integer test_num = 0;
integer passed = 0;
integer failed = 0;

// Task para verificar resultados
task check_result;
    input [31:0] expected;
    input string operation;
begin
    @(posedge clk);
    #1; // Pequeño delay para estabilización
    test_num = test_num + 1;
    
    if (result === expected && result_valid) begin
        $display("✓ TEST %0d PASSED: %s = %h (expected %h)", 
                 test_num, operation, result, expected);
        passed = passed + 1;
    end else begin
        $display("✗ TEST %0d FAILED: %s = %h (expected %h)", 
                 test_num, operation, result, expected);
        failed = failed + 1;
    end
end
endtask

// Secuencia de pruebas
initial begin
    $display("====================================================");
    $display("  TESTBENCH ALU BÁSICA RISC-V");
    $display("  Instrucciones: add, sub, and, or, xor, jal");
    $display("====================================================");
    
    // Inicialización
    resetn = 0;
    instruction = 32'h0;
    pc = 32'h0;
    rs1_data = 32'h0;
    rs2_data = 32'h0;
    valid = 0;
    
    // Reset
    #20;
    resetn = 1;
    #10;
    
    $display("\n>>> Iniciando tests...\n");
    
    //==========================================================================
    // TEST 1: ADD - 15 + 20 = 35
    //==========================================================================
    pc = 32'h00000000;
    instruction = 32'h00208133; // add x2, x1, x2
    rs1_data = 32'd15;
    rs2_data = 32'd20;
    valid = 1;
    @(posedge clk);
    check_result(32'd35, "ADD 15+20");
    valid = 0;
    #10;
    
    //==========================================================================
    // TEST 2: SUB - 50 - 30 = 20
    //==========================================================================
    pc = 32'h00000004;
    instruction = 32'h402081B3; // sub x3, x1, x2
    rs1_data = 32'd50;
    rs2_data = 32'd30;
    valid = 1;
    @(posedge clk);
    check_result(32'd20, "SUB 50-30");
    valid = 0;
    #10;
    
    //==========================================================================
    // TEST 3: AND - 0xFF & 0x0F = 0x0F
    //==========================================================================
    pc = 32'h00000008;
    instruction = 32'h0020F233; // and x4, x1, x2
    rs1_data = 32'h000000FF;
    rs2_data = 32'h0000000F;
    valid = 1;
    @(posedge clk);
    check_result(32'h0000000F, "AND 0xFF&0x0F");
    valid = 0;
    #10;
    
    //==========================================================================
    // TEST 4: OR - 0xF0 | 0x0F = 0xFF
    //==========================================================================
    pc = 32'h0000000C;
    instruction = 32'h002062B3; // or x5, x1, x2
    rs1_data = 32'h000000F0;
    rs2_data = 32'h0000000F;
    valid = 1;
    @(posedge clk);
    check_result(32'h000000FF, "OR 0xF0|0x0F");
    valid = 0;
    #10;
    
    //==========================================================================
    // TEST 5: XOR - 0xFF ^ 0xAA = 0x55
    //==========================================================================
    pc = 32'h00000010;
    instruction = 32'h00204333; // xor x6, x1, x2
    rs1_data = 32'h000000FF;
    rs2_data = 32'h000000AA;
    valid = 1;
    @(posedge clk);
    check_result(32'h00000055, "XOR 0xFF^0xAA");
    valid = 0;
    #10;
    
    //==========================================================================
    // TEST 6: JAL - Jump and Link
    //==========================================================================
    pc = 32'h00000014;
    instruction = 32'h008000EF; // jal x1, 8 (offset = 8)
    rs1_data = 32'h0; // No usado en jal
    rs2_data = 32'h0; // No usado en jal
    valid = 1;
    @(posedge clk);
    #1;
    test_num = test_num + 1;
    if (result === 32'h00000018 && next_pc === 32'h0000001C && is_jump) begin
        $display("✓ TEST %0d PASSED: JAL return_addr=%h, next_pc=%h", 
                 test_num, result, next_pc);
        passed = passed + 1;
    end else begin
        $display("✗ TEST %0d FAILED: JAL return_addr=%h (exp 0x18), next_pc=%h (exp 0x1C)", 
                 test_num, result, next_pc);
        failed = failed + 1;
    end
    valid = 0;
    #10;
    
    //==========================================================================
    // TEST 7: ADD con números negativos - (-5) + 10 = 5
    //==========================================================================
    pc = 32'h00000018;
    instruction = 32'h002083B3; // add x7, x1, x2
    rs1_data = 32'hFFFFFFFB; // -5 en complemento a 2
    rs2_data = 32'd10;
    valid = 1;
    @(posedge clk);
    check_result(32'd5, "ADD (-5)+10");
    valid = 0;
    #10;
    
    //==========================================================================
    // Resumen de resultados
    //==========================================================================
    $display("\n====================================================");
    $display("  RESUMEN DE TESTS");
    $display("====================================================");
    $display("Total tests: %0d", test_num);
    $display("Passed:      %0d", passed);
    $display("Failed:      %0d", failed);
    
    if (failed == 0) begin
        $display("\n✓✓✓ TODOS LOS TESTS PASARON ✓✓✓");
    end else begin
        $display("\n✗✗✗ ALGUNOS TESTS FALLARON ✗✗✗");
    end
    $display("====================================================\n");
    
    #50;
    $finish;
end

// Timeout de seguridad
initial begin
    #10000;
    $display("\n⚠ TIMEOUT: Simulación excedió 10us");
    $finish;
end

endmodule