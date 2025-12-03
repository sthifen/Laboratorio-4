    .text
    .globl main

# ==========================================
#  Programa de prueba para PCPI unificado
#  - Testea ADD, SUB, AND, OR, XOR
#  - Testea SLLI, SRLI, SRAI
#  - Testea LW y SW
#  - Testea JAL (salto incondicional)
#
#  Valores esperados al final:
#    x1  = 5
#    x2  = 10
#    x3  = 15          (x1 + x2)
#    x4  = 10          (x3 - x1)
#    x5  = 0x0000000F
#    x6  = 0x00000033
#    x7  = 0x00000003  (x5 & x6)
#    x8  = 0x0000003F  (x5 | x6)
#    x9  = 0x0000003C  (x5 ^ x6)
#    x10 = 0x00000100  (1 << 8)
#    x11 = 0xFFFFFFFF  (-1)
#    x12 = 0x7FFFFFFF  (srli x11,1)
#    x13 = 0xFFFFFFFF  (srai x11,1)
#    x14 = 0x00000040  (dirección usada en RAM)
#    x15 = 15          (valor leído de RAM)
#    x17 = 0x00000055  (marca de que se llegó a 'done')
# ==========================================

main:
    # --- Test ADDI y ADD ---
    addi x1, x0, 5           # x1 = 5
    addi x2, x0, 10          # x2 = 10
    add  x3, x1, x2          # x3 = 15

    # --- Test SUB ---
    sub  x4, x3, x1          # x4 = 10

    # --- Test AND / OR / XOR ---
    addi x5, x0, 0x0F        # 0000 1111
    addi x6, x0, 0x33        # 0011 0011

    and  x7, x5, x6          # 0000 0011 = 0x03
    or   x8, x5, x6          # 0011 1111 = 0x3F
    xor  x9, x5, x6          # 0011 1100 = 0x3C

    # --- Test shifts ---
    addi x10, x0, 1
    slli x10, x10, 8         # x10 = 0x00000100

    addi x11, x0, -1         # x11 = 0xFFFFFFFF
    srli x12, x11, 1         # lógico:  0x7FFFFFFF
    srai x13, x11, 1         # aritmético: sigue siendo 0xFFFFFFFF

    # --- Test LW / SW ---
    addi x14, x0, 0x40       # dirección 0x00000040 (dentro de la RAM del tb)
    sw   x3, 0(x14)          # MEM[0x40] = 15
    lw   x15, 0(x14)         # x15 debe quedar en 15

    # --- Test JAL (salto) ---
    jal  x0, done            # salta incondicionalmente

    # Si por algún bug de JAL se ejecuta esto, verás x16 = 123 al final
    addi x16, x0, 123        

done:
    addi x17, x0, 0x55       # marca para saber que se llegó aquí

loop:
    jal  x0, loop            # bucle infinito para que el TB pare por timeout

