#!/usr/bin/env python3
"""
RISC-V RV32I Assembler - Simple assembler for temperature sensor firmware
Genera firmware.hex para simulación
"""

def encode_r_type(opcode, rd, funct3, rs1, rs2, funct7):
    """Codifica instrucción tipo R"""
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i_type(opcode, rd, funct3, rs1, imm):
    """Codifica instrucción tipo I"""
    imm = imm & 0xFFF  # 12 bits
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s_type(opcode, funct3, rs1, rs2, imm):
    """Codifica instrucción tipo S"""
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def encode_b_type(opcode, funct3, rs1, rs2, offset):
    """Codifica instrucción tipo B (branch)"""
    offset = offset & 0x1FFF  # 13 bits (pero bit 0 siempre es 0)
    imm_12 = (offset >> 12) & 0x1
    imm_10_5 = (offset >> 5) & 0x3F
    imm_4_1 = (offset >> 1) & 0xF
    imm_11 = (offset >> 11) & 0x1
    return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | \
           (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode

def encode_u_type(opcode, rd, imm):
    """Codifica instrucción tipo U"""
    imm = (imm >> 12) & 0xFFFFF  # Upper 20 bits
    return (imm << 12) | (rd << 7) | opcode

def encode_j_type(opcode, rd, offset):
    """Codifica instrucción tipo J (JAL)"""
    offset = offset & 0x1FFFFF  # 21 bits
    imm_20 = (offset >> 20) & 0x1
    imm_10_1 = (offset >> 1) & 0x3FF
    imm_11 = (offset >> 11) & 0x1
    imm_19_12 = (offset >> 12) & 0xFF
    return (imm_20 << 31) | (imm_19_12 << 12) | (imm_11 << 20) | \
           (imm_10_1 << 21) | (rd << 7) | opcode

# Aliases de registros
regs = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
    't0': 5, 't1': 6, 't2': 7,
    's0': 8, 'fp': 8, 's1': 9,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
    's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
    't3': 28, 't4': 29, 't5': 30, 't6': 31
}

def assemble_firmware():
    """Genera firmware para leer temperatura y mostrar en display"""
    instructions = []
    
    # _start:
    # Inicializar registros base
    instructions.append(encode_u_type(0x37, regs['sp'], 0x2000))  # lui sp, 0x2000
    instructions.append(encode_u_type(0x37, regs['a0'], 0x0))     # lui a0, 0x0
    
    # Cargar direcciones de periféricos
    instructions.append(encode_i_type(0x13, regs['s0'], 0, regs['a0'], 0x008))  # addi s0, a0, 0x008 (SEVENSEG)
    instructions.append(encode_i_type(0x13, regs['s1'], 0, regs['a0'], 0x018))  # addi s1, a0, 0x018 (TIMER_CTRL)
    instructions.append(encode_i_type(0x13, regs['s2'], 0, regs['a0'], 0x01C))  # addi s2, a0, 0x01C (TIMER_DATA)
    instructions.append(encode_i_type(0x13, regs['s3'], 0, regs['a0'], 0x030))  # addi s3, a0, 0x030 (TEMP_CTRL)
    instructions.append(encode_i_type(0x13, regs['s4'], 0, regs['a0'], 0x034))  # addi s4, a0, 0x034 (TEMP_DATA)
    
    # Configurar timer: cargar 10,000,000 (0x989680)
    instructions.append(encode_u_type(0x37, regs['t0'], 0x989))    # lui t0, 0x989
    instructions.append(encode_i_type(0x13, regs['t0'], 0, regs['t0'], 0x680))  # addi t0, t0, 0x680
    instructions.append(encode_s_type(0x23, 2, regs['s2'], regs['t0'], 0))      # sw t0, 0(s2)
    
    # Habilitar timer
    instructions.append(encode_i_type(0x13, regs['t1'], 0, regs['zero'], 1))    # addi t1, zero, 1
    instructions.append(encode_s_type(0x23, 2, regs['s1'], regs['t1'], 0))      # sw t1, 0(s1)
    
    # main_loop: (PC = 0x2C = 11*4)
    # Iniciar conversión de temperatura
    instructions.append(encode_i_type(0x13, regs['t0'], 0, regs['zero'], 1))    # addi t0, zero, 1
    instructions.append(encode_s_type(0x23, 2, regs['s3'], regs['t0'], 0))      # sw t0, 0(s3)
    
    # wait_temp_ready: (PC = 0x34 = 13*4)
    instructions.append(encode_i_type(0x03, regs['t1'], 2, regs['s3'], 0))      # lw t1, 0(s3)
    instructions.append(encode_i_type(0x13, regs['t2'], 7, regs['t1'], 2))      # andi t2, t1, 2
    instructions.append(encode_b_type(0x63, 0, regs['t2'], regs['zero'], -8))   # beq t2, zero, wait_temp_ready
    
    # Leer temperatura
    instructions.append(encode_i_type(0x03, regs['t3'], 2, regs['s4'], 0))      # lw t3, 0(s4)
    
    # Limpiar flag
    instructions.append(encode_i_type(0x13, regs['t0'], 0, regs['zero'], 2))    # addi t0, zero, 2
    instructions.append(encode_s_type(0x23, 2, regs['s3'], regs['t0'], 0))      # sw t0, 0(s3)
    
    # Convertir temperatura a BCD (versión simplificada)
    # Para simplificar, solo mostramos el valor raw en hex
    # Escritura al display
    instructions.append(encode_s_type(0x23, 2, regs['s0'], regs['t3'], 0))      # sw t3, 0(s0)
    
    # wait_timer: (PC = 0x50 = 20*4)
    instructions.append(encode_i_type(0x03, regs['t1'], 2, regs['s2'], 0))      # lw t1, 0(s2)
    instructions.append(encode_b_type(0x63, 1, regs['t1'], regs['zero'], -4))   # bne t1, zero, wait_timer
    
    # Reiniciar timer
    instructions.append(encode_u_type(0x37, regs['t0'], 0x989))    # lui t0, 0x989
    instructions.append(encode_i_type(0x13, regs['t0'], 0, regs['t0'], 0x680))  # addi t0, t0, 0x680
    instructions.append(encode_s_type(0x23, 2, regs['s2'], regs['t0'], 0))      # sw t0, 0(s2)
    
    # Saltar a main_loop (offset = 0x2C - current_pc)
    # current_pc = 0x60 (24*4), target = 0x2C, offset = 0x2C - 0x60 = -0x34
    instructions.append(encode_j_type(0x6F, regs['zero'], -0x34))  # j main_loop
    
    return instructions

def write_hex_file(instructions, filename):
    """Escribe las instrucciones en formato .hex"""
    with open(filename, 'w') as f:
        for instr in instructions:
            f.write(f"{instr:08x}\n")
    print(f"✓ Generated {filename} with {len(instructions)} instructions")

def write_coe_file(instructions, filename):
    """Escribe las instrucciones en formato .coe para Vivado"""
    with open(filename, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        for i, instr in enumerate(instructions):
            if i < len(instructions) - 1:
                f.write(f"{instr:08x},\n")
            else:
                f.write(f"{instr:08x};\n")
    print(f"✓ Generated {filename}")

if __name__ == "__main__":
    print("=" * 70)
    print("RISC-V Temperature Sensor Firmware Generator")
    print("=" * 70)
    
    instructions = assemble_firmware()
    
    write_hex_file(instructions, "firmware_temp_real.hex")
    write_coe_file(instructions, "firmware_temp_real.coe")
    
    print("\nFirmware Summary:")
    print(f"  Total instructions: {len(instructions)}")
    print(f"  Memory footprint: {len(instructions) * 4} bytes")
    print("\nMemory Map:")
    print("  0x2008 - Seven Segment Display")
    print("  0x2018 - Timer Control")
    print("  0x201C - Timer Data")
    print("  0x2030 - Temperature Control")
    print("  0x2034 - Temperature Data")
    print("\nOperation:")
    print("  1. Configure timer for 1-second intervals")
    print("  2. Start temperature conversion")
    print("  3. Wait for data ready flag")
    print("  4. Read temperature value")
    print("  5. Display on 7-segment (raw hex format)")
    print("  6. Wait for timer")
    print("  7. Repeat")
    print("=" * 70)
