    .data
var:    .word 0          # variable en memoria

    .text
    .globl main
main:
    la   x1, var         # x1 = dirección de 'var'
    li   x2, 10          # x2 = 10

    sw   x2, 0(x1)       # MEM[var] = 10   (STORE)
    lw   x3, 0(x1)       # x3 = MEM[var]   (LOAD)

    # aquí x3 debería valer 10

