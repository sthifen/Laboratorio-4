# Test de instrucciones Branch y Compare
# Para verificar: beq, bne, blt, bge, slt, slti, sltu, sltiu

.section .text
.globl _start

_start:
    # Inicializar valores de prueba
    li x1, 10       # x1 = 10
    li x2, 20       # x2 = 20  
    li x3, 10       # x3 = 10
    li x4, -5       # x4 = -5
    li x5, 0        # x5 = resultado

# TEST 1: BEQ
test_beq:
    beq x1, x3, beq_ok     # 10 == 10 → debe saltar
    li x5, 0xE1            # Error
    j end
beq_ok:
    li x5, 0x01            # OK

# TEST 2: BNE  
test_bne:
    bne x1, x2, bne_ok     # 10 != 20 → debe saltar
    li x5, 0xE2            # Error
    j end
bne_ok:
    li x5, 0x02            # OK

# TEST 3: BLT
test_blt:
    blt x4, x1, blt_ok     # -5 < 10 → debe saltar
    li x5, 0xE3            # Error
    j end
blt_ok:
    li x5, 0x03            # OK

# TEST 4: BGE
test_bge:
    bge x2, x1, bge_ok     # 20 >= 10 → debe saltar
    li x5, 0xE4            # Error
    j end
bge_ok:
    li x5, 0x04            # OK

# TEST 5: SLT
test_slt:
    slt x5, x1, x2         # 10 < 20 → x5 = 1
    li x6, 1
    beq x5, x6, slt_ok
    li x5, 0xE5            # Error
    j end
slt_ok:
    li x5, 0x05            # OK

# TEST 6: SLTI
test_slti:
    slti x5, x1, 15        # 10 < 15 → x5 = 1
    li x6, 1
    beq x5, x6, slti_ok
    li x5, 0xE6            # Error
    j end
slti_ok:
    li x5, 0x06            # OK

# TEST 7: SLTU
test_sltu:
    sltu x5, x1, x2        # 10 < 20 → x5 = 1
    li x6, 1
    beq x5, x6, sltu_ok
    li x5, 0xE7            # Error
    j end
sltu_ok:
    li x5, 0x07            # OK

# TEST 8: SLTIU
test_sltiu:
    sltiu x5, x1, 15       # 10 < 15 → x5 = 1
    li x6, 1
    beq x5, x6, sltiu_ok
    li x5, 0xE8            # Error
    j end
sltiu_ok:
    li x5, 0x08            # OK

# TODOS PASARON
all_pass:
    li x5, 0xAA            # Código de éxito

end:
    j end                  # Loop infinito