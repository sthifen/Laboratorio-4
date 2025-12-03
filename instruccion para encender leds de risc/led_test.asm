    .text
    .globl main

# Programa: escribe un patrón en LEDs (addr 0x2004)
# Usa:
#   addi, slli, sw, jal

main:
    # x1 = 0x2004 (dirección LEDs)
    addi x1, x0, 0x20      # x1 = 0x20
    slli x1, x1, 8         # x1 = 0x2000
    addi x1, x1, 4         # x1 = 0x2004

    # x2 = patrón de LEDs 0xAA00
    addi x2, x0, 0xAA      # x2 = 0x00AA
    slli x2, x2, 8         # x2 = 0xAA00

    # Escritura en el periférico: MEM[0x2004] = x2
    sw   x2, 0(x1)

loop:
    # Bucle infinito (salto a sí mismo)
    jal  x0, loop

