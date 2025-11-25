`timescale 1ns / 1ps
//==============================================================================
// Testbench para ALU Básica RISC-V
// Instrucciones: add, sub, and, or, xor, jal
//==============================================================================

module tb_alu_steven();

  reg clk;
  reg resetn;
  reg [31:0] instruction;
  reg [31:0] pc;
  reg [31:0] rs1_data;
  reg [31:0] rs2_data;
  reg        valid;

  wire [31:0] result;
  wire [31:0] next_pc;
  wire        result_valid;
  wire        is_jump;

  // Instancia de la ALU
  alu_basica uut (
      .clk        (clk),
      .resetn     (resetn),
      .instruction(instruction),
      .pc         (pc),
      .rs1_data   (rs1_data),
      .rs2_data   (rs2_data),
      .valid      (valid),
      .result     (result),
      .next_pc    (next_pc),
      .result_valid(result_valid),
      .is_jump    (is_jump)
  );

  // Reloj 100 MHz
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Contadores
  integer test_num = 0;
  integer passed   = 0;
  integer failed   = 0;

  //==========================================================================
  // TASK GENÉRICA PARA TIPO R (add, sub, and, or, xor)
  // Verifica: result, result_valid, next_pc = pc+4, is_jump = 0
  //==========================================================================
  task automatic run_rtype_test;
    input [31:0] instr;
    input [31:0] rs1_val;
    input [31:0] rs2_val;
    input [31:0] expected;
    input [31:0] pc_val;
    input string  op_name;
    reg   [31:0] expected_pc_next;
  begin
    pc          = pc_val;
    instruction = instr;
    rs1_data    = rs1_val;
    rs2_data    = rs2_val;
    valid       = 1'b1;

    expected_pc_next = pc_val + 4;

    @(posedge clk);
    #1;
    test_num = test_num + 1;

    if (result === expected &&
        result_valid &&
        next_pc === expected_pc_next &&
        is_jump == 1'b0) begin
      $display("✓ TEST %0d OK: %-15s rs1=%h rs2=%h -> result=%h (esperado=%h), next_pc=%h",
               test_num, op_name, rs1_val, rs2_val, result, expected, next_pc);
      passed = passed + 1;
    end else begin
      $display("✗ TEST %0d FAIL: %-15s rs1=%h rs2=%h -> result=%h (esperado=%h), next_pc=%h (esp=%h), result_valid=%b, is_jump=%b",
               test_num, op_name, rs1_val, rs2_val,
               result, expected, next_pc, expected_pc_next, result_valid, is_jump);
      failed = failed + 1;
    end

    valid = 1'b0;
    #5;
  end
  endtask

  //==========================================================================
  // TASK PARA JAL
  // Verifica: result = pc+4, next_pc = pc + offset, is_jump = 1
  //==========================================================================
  task automatic run_jal_test;
    input [31:0] instr;
    input [31:0] pc_val;
    input [31:0] expected_offset; // offset ya en bytes (lo que suma a pc)
    input string  op_name;
    reg   [31:0] expected_ret;
    reg   [31:0] expected_pc_next;
  begin
    pc          = pc_val;
    instruction = instr;
    rs1_data    = 32'h0;
    rs2_data    = 32'h0;
    valid       = 1'b1;

    expected_ret     = pc_val + 4;
    expected_pc_next = pc_val + expected_offset;

    @(posedge clk);
    #1;
    test_num = test_num + 1;

    if (result === expected_ret &&
        next_pc === expected_pc_next &&
        result_valid &&
        is_jump == 1'b1) begin
      $display("✓ TEST %0d OK: %-15s return=%h (esp=%h), next_pc=%h (esp=%h)",
               test_num, op_name, result, expected_ret, next_pc, expected_pc_next);
      passed = passed + 1;
    end else begin
      $display("✗ TEST %0d FAIL: %-15s return=%h (esp=%h), next_pc=%h (esp=%h), rv=%b, is_jump=%b",
               test_num, op_name, result, expected_ret,
               next_pc, expected_pc_next, result_valid, is_jump);
      failed = failed + 1;
    end

    valid = 1'b0;
    #5;
  end
  endtask

  //==========================================================================
  // CÓDIGOS DE MÁQUINA (R-TYPE)
  // opcode = 0x33, rs1 = x1, rs2 = x2 (no importa el rd para la ALU)
  //==========================================================================
  localparam [31:0] INSTR_ADD = 32'h00208133; // add x2, x1, x2
  localparam [31:0] INSTR_SUB = 32'h402081B3; // sub x3, x1, x2
  localparam [31:0] INSTR_AND = 32'h0020F233; // and x4, x1, x2
  localparam [31:0] INSTR_OR  = 32'h0020E2B3; // or  x5, x1, x2  (CORREGIDO)
  localparam [31:0] INSTR_XOR = 32'h0020C333; // xor x6, x1, x2  (CORREGIDO)

  // JAL: jal x1, 8  (offset = 8 bytes)
  localparam [31:0] INSTR_JAL_8 = 32'h008000EF;

  //==========================================================================
  // SECUENCIA DE PRUEBAS
  //==========================================================================
  initial begin
    $display("====================================================");
    $display("   TESTBENCH ALU BASICA RISC-V (Steven)");
    $display("====================================================");

    // Reset
    resetn      = 0;
    instruction = 32'h0;
    pc          = 32'h0;
    rs1_data    = 32'h0;
    rs2_data    = 32'h0;
    valid       = 0;
    #20;
    resetn = 1;
    #10;

    // ------------------ ADD ------------------
    run_rtype_test(INSTR_ADD, 32'd15,        32'd20,        32'd35,        32'h0000_0000, "ADD 15+20");
    run_rtype_test(INSTR_ADD, 32'hFFFF_FFFB, 32'd10,        32'd5,         32'h0000_0004, "ADD -5+10");
    run_rtype_test(INSTR_ADD, 32'hFFFF_FFFB, 32'hFFFF_FFFB, 32'hFFFF_FFF6, 32'h0000_0008, "ADD -5-5");

    // ------------------ SUB ------------------
    run_rtype_test(INSTR_SUB, 32'd50,        32'd30,        32'd20,        32'h0000_000C, "SUB 50-30");
    run_rtype_test(INSTR_SUB, 32'd10,        32'd20,        32'hFFFF_FFF6, 32'h0000_0010, "SUB 10-20");

    // ------------------ AND ------------------
    run_rtype_test(INSTR_AND, 32'h0000_00FF, 32'h0000_000F, 32'h0000_000F, 32'h0000_0014, "AND FF,0F");
    run_rtype_test(INSTR_AND, 32'hAAAA_AAAA, 32'h0F0F_0F0F, 32'h0A0A_0A0A, 32'h0000_0018, "AND patrones");

    // ------------------ OR -------------------
    run_rtype_test(INSTR_OR,  32'h0000_00F0, 32'h0000_000F, 32'h0000_00FF, 32'h0000_001C, "OR F0,0F");
    run_rtype_test(INSTR_OR,  32'h1234_0000, 32'h0000_5678, 32'h1234_5678, 32'h0000_0020, "OR mezcla");

    // ------------------ XOR ------------------
    run_rtype_test(INSTR_XOR, 32'h0000_00FF, 32'h0000_00AA, 32'h0000_0055, 32'h0000_0024, "XOR FF,AA");
    run_rtype_test(INSTR_XOR, 32'hFFFF_0000, 32'h0000_FFFF, 32'hFFFF_FFFF, 32'h0000_0028, "XOR inverso");

    // ------------------ JAL ------------------
    // PC = 0x00000030, offset = 8 -> next_pc = 0x00000038
    run_jal_test(INSTR_JAL_8, 32'h0000_0030, 32'd8, "JAL pc+8");

    // Resumen
    $display("\n====================================================");
    $display("  RESUMEN DE TESTS");
    $display("====================================================");
    $display("Total tests: %0d", test_num);
    $display("Passed:      %0d", passed);
    $display("Failed:      %0d", failed);
    if (failed == 0)
      $display(">>> TODOS LOS TESTS PASARON <<<");
    else
      $display(">>> HAY TESTS FALLADOS <<<");
    $display("====================================================\n");

    #50;
    $finish;
  end

  // Timeout de seguridad
  initial begin
    #10000;
    $display("\n[TIMEOUT] Simulación excedió 10 us");
    $finish;
  end

endmodule
