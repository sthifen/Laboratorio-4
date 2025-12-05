    .text
    .globl main

# ============================================================
#  Firmware Lab 4 - Control de timer, sensor TMP y displays
#  Registros dedicados:
#    x20 = 0x2000 (switches)
#    x21 = 0x2004 (LEDs)
#    x22 = 0x2008 (display 7 segmentos)
#    x23 = 0x2018 (timer ctrl)
#    x24 = 0x201C (timer data)
#    x25 = 0x2030 (TMP ctrl)
#    x26 = 0x2034 (TMP data)
#    x27..x30 = constantes de periodo
#    x31 = 0xFFF00000 (apaga digitos altos)
# ============================================================

main:
    # Direcciones base
    lui x20, 0x00002         # 0x2000
    addi x21, x20, 4
    addi x22, x20, 8
    addi x23, x20, 24        # 0x2018
    addi x24, x23, 4         # 0x201C
    addi x25, x23, 24        # 0x2030
    addi x26, x25, 4         # 0x2034

    # Constantes de LEDs y control
    addi x11, x0, 1          # LED0 encendido / start bit
    addi x12, x0, 2          # LED1 encendido
    addi x13, x0, 4          # LED2 encendido
    addi x14, x0, 1          # timer/temp start
    addi x15, x0, 2          # clear done/ready

    # Periodos en ticks de 10 MHz
    lui x27, 0x00009         # 1 s  = 10,000,000
    addi x27, x27, 0x680
    lui x28, 0x1313          # 2 s  = 20,000,000
    addi x28, x28, -768
    lui x29, 0x2FAF          # 5 s  = 50,000,000
    addi x29, x29, 128
    lui x30, 0x5F5E          # 10 s = 100,000,000
    addi x30, x30, 256

    # Mascara para apagar digitos superiores
    lui x31, 0xFFF00

loop_main:
    lw x5, 0(x20)            # switches y botones
    andi x5, x5, 15          # solo SW3..SW0
    addi x6, x27, 0          # valor por defecto = 1 s

    andi x7, x5, 8
    beq x7, x0, check_sw2
    addi x6, x30, 0          # 10 segundos
    jal x0, period_ready

check_sw2:
    andi x7, x5, 4
    beq x7, x0, check_sw1
    addi x6, x29, 0          # 5 segundos
    jal x0, period_ready

check_sw1:
    andi x7, x5, 2
    beq x7, x0, check_sw0
    addi x6, x28, 0          # 2 segundos
    jal x0, period_ready

check_sw0:
    andi x7, x5, 1
    beq x7, x0, period_ready
    addi x6, x27, 0          # 1 segundo explicito

period_ready:
    sw x6, 0(x24)            # cargar periodo
    sw x11, 0(x21)           # LED0 = esperando timer
    sw x14, 0(x23)           # iniciar timer

wait_timer_done:
    lw x7, 0(x23)
    andi x7, x7, 2
    beq x7, x0, wait_timer_done

    sw x15, 0(x23)           # limpiar bandera done
    sw x12, 0(x21)           # LED1 = leyendo sensor
    sw x14, 0(x25)           # iniciar conversion TMP

wait_temp_ready:
    lw x7, 0(x25)
    andi x7, x7, 2
    beq x7, x0, wait_temp_ready

    sw x15, 0(x25)           # limpiar bandera ready
    sw x13, 0(x21)           # LED2 = dato listo

    lw x10, 0(x26)           # lectura en decimas de grados C
    jal x1, format_temp
    sw x10, 0(x22)           # mostrar en 7 segmentos

    jal x0, loop_main

# ------------------------------------------------------------
# Subrutina format_temp
# Entrada: x10 = dato crudo (bits 15:0 = decimas, signed)
# Salida:  x10 = palabra con digitos BCD y nibbles 5..7 en blanco
# ------------------------------------------------------------

format_temp:
    slli x10, x10, 16
    srai x10, x10, 16        # extension de signo
    blt x10, x0, fmt_zero_value

    lui x5, 0x00002
    addi x5, x5, 0x70F       # 9999 (maximo mostrado)
    blt x5, x10, fmt_clamp_max
    jal x0, fmt_after_clamp

fmt_zero_value:
    addi x10, x0, 0
    jal x0, fmt_after_clamp

fmt_clamp_max:
    addi x10, x5, 0

fmt_after_clamp:
    addi x6, x0, 0           # cociente = 0

fmt_div_loop:
    addi x7, x10, -10
    blt x7, x0, fmt_div_done
    addi x10, x7, 0
    addi x6, x6, 1
    jal x0, fmt_div_loop

fmt_div_done:
    addi x8, x10, 0          # decima (resto)
    addi x10, x6, 0          # parte entera

    addi x5, x0, 0           # millares
    addi x7, x0, 1000

fmt_thousands_loop:
    blt x10, x7, fmt_thousands_done
    addi x10, x10, -1000
    addi x5, x5, 1
    jal x0, fmt_thousands_loop

fmt_thousands_done:
    addi x9, x0, 0           # centenas
    addi x7, x0, 100

fmt_hundreds_loop:
    blt x10, x7, fmt_hundreds_done
    addi x10, x10, -100
    addi x9, x9, 1
    jal x0, fmt_hundreds_loop

fmt_hundreds_done:
    addi x6, x0, 0           # decenas
    addi x7, x0, 10

fmt_tens_loop:
    blt x10, x7, fmt_tens_done
    addi x10, x10, -10
    addi x6, x6, 1
    jal x0, fmt_tens_loop

fmt_tens_done:
    addi x7, x10, 0          # unidades

    slli x5, x5, 16          # millares -> nibble 4
    slli x9, x9, 12          # centenas -> nibble 3
    or x5, x5, x9

    slli x6, x6, 8           # decenas -> nibble 2
    or x5, x5, x6

    slli x7, x7, 4           # unidades -> nibble 1
    or x5, x5, x7

    or x5, x5, x8            # decima -> nibble 0
    or x10, x5, x31          # blanco en nibbles 5..7

    jalr x0, 0(x1)
