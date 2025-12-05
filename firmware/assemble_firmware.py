#!/usr/bin/env python3
"""
Assemble firmware_pcpi.asm into firmware.hex without external toolchains.

Supported subset:
  - lui, addi, andi, ori
  - slli, srai
  - lw, sw
  - beq, bne, blt, bge
  - jal, jalr
  - or

Usage:
    python firmware/assemble_firmware.py [input.asm] [output.hex]
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent


REGISTERS: Dict[str, int] = {f"x{i}": i for i in range(32)}


@dataclass
class Instruction:
    pc: int
    text: str


def clean_line(line: str) -> str:
    """Strip comments and whitespace."""
    line = line.split("#", 1)[0]
    line = line.split("//", 1)[0]
    return line.strip()


def parse_register(token: str) -> int:
    token = token.strip()
    if token not in REGISTERS:
        raise ValueError(f"Registro no soportado: {token}")
    return REGISTERS[token]


def parse_immediate(token: str) -> int:
    token = token.strip()
    if not token:
        raise ValueError("Inmediato vacio")
    return int(token, 0)


def parse_mem_operand(token: str) -> Tuple[int, int]:
    match = re.match(r"(-?\d+)\((x\d+)\)$", token.strip())
    if not match:
        raise ValueError(f"Operando de memoria invalido: {token}")
    imm = int(match.group(1), 0)
    rs1 = parse_register(match.group(2))
    return imm, rs1


def sign_check(value: int, bits: int) -> None:
    limit = 1 << (bits - 1)
    if not -limit <= value < limit:
        raise ValueError(f"Inmediato fuera de rango ({bits} bits): {value}")


def encode_r_type(opcode: int, funct3: int, funct7: int, rd: int, rs1: int, rs2: int) -> int:
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_i_type(opcode: int, funct3: int, rd: int, rs1: int, imm: int) -> int:
    sign_check(imm, 12)
    imm &= 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_s_type(opcode: int, funct3: int, rs2: int, rs1: int, imm: int) -> int:
    sign_check(imm, 12)
    imm &= 0xFFF
    imm_hi = (imm >> 5) & 0x7F
    imm_lo = imm & 0x1F
    return (imm_hi << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_lo << 7) | opcode


def encode_b_type(opcode: int, funct3: int, rs1: int, rs2: int, offset: int) -> int:
    sign_check(offset, 13)
    if offset % 2 != 0:
        raise ValueError("Offset de branch no alineado")
    imm = offset
    bit12 = (imm >> 12) & 0x1
    bit11 = (imm >> 11) & 0x1
    bits10_5 = (imm >> 5) & 0x3F
    bits4_1 = (imm >> 1) & 0xF
    return ((bit12 << 31) |
            (bits10_5 << 25) |
            (rs2 << 20) |
            (rs1 << 15) |
            (funct3 << 12) |
            (bits4_1 << 8) |
            (bit11 << 7) |
            opcode)


def encode_u_type(opcode: int, rd: int, imm: int) -> int:
    sign_check(imm, 32)
    value = (imm & 0xFFFFF) << 12
    return value | (rd << 7) | opcode


def encode_j_type(opcode: int, rd: int, offset: int) -> int:
    sign_check(offset, 21)
    if offset % 2 != 0:
        raise ValueError("Offset de salto no alineado")
    imm = offset
    bit20 = (imm >> 20) & 0x1
    bits10_1 = (imm >> 1) & 0x3FF
    bit11 = (imm >> 11) & 0x1
    bits19_12 = (imm >> 12) & 0xFF
    return ((bit20 << 31) |
            (bits19_12 << 12) |
            (bit11 << 20) |
            (bits10_1 << 21) |
            (rd << 7) |
            opcode)


class MiniAssembler:
    def __init__(self, source: Path, target: Path) -> None:
        self.source = source
        self.target = target
        self.labels: Dict[str, int] = {}
        self.instructions: List[Instruction] = []

    def first_pass(self) -> None:
        pc = 0
        for line in self.source.read_text(encoding="ascii").splitlines():
            stripped = clean_line(line)
            if not stripped:
                continue
            if stripped.endswith(":"):
                label = stripped[:-1].strip()
                if label in self.labels:
                    raise ValueError(f"Etiqueta duplicada: {label}")
                self.labels[label] = pc
                continue
            if stripped.startswith("."):
                continue
            self.instructions.append(Instruction(pc=pc, text=stripped))
            pc += 4

    def assemble(self) -> List[str]:
        self.first_pass()
        machine: List[int] = []
        for inst in self.instructions:
            machine.append(self.encode(inst))
        hex_lines = [f"{value:08x}" for value in machine]
        hex_text = "\n".join(hex_lines) + "\n"
        self.target.write_text(hex_text, encoding="ascii")
        return hex_lines

    def encode(self, inst: Instruction) -> int:
        line = inst.text.replace(",", " ")
        tokens = [tok for tok in line.split() if tok]
        if not tokens:
            raise ValueError(f"Instruccion vacia @0x{inst.pc:08x}")
        mnemonic = tokens[0].lower()
        operands = tokens[1:]

        if mnemonic == "lui":
            rd = parse_register(operands[0])
            imm = parse_immediate(operands[1])
            return encode_u_type(0b0110111, rd, imm)

        if mnemonic in {"addi", "andi", "ori"}:
            rd = parse_register(operands[0])
            rs1 = parse_register(operands[1])
            imm = parse_immediate(operands[2])
            funct3 = {"addi": 0b000, "andi": 0b111, "ori": 0b110}[mnemonic]
            return encode_i_type(0b0010011, funct3, rd, rs1, imm)

        if mnemonic in {"slli", "srai"}:
            rd = parse_register(operands[0])
            rs1 = parse_register(operands[1])
            shamt = parse_immediate(operands[2])
            if not 0 <= shamt < 32:
                raise ValueError("Shift fuera de rango")
            if mnemonic == "slli":
                imm = shamt
                funct3 = 0b001
            else:
                imm = shamt | (0b0100000 << 5)
                funct3 = 0b101
            return encode_i_type(0b0010011, funct3, rd, rs1, imm)

        if mnemonic == "lw":
            rd = parse_register(operands[0])
            imm, rs1 = parse_mem_operand(operands[1])
            return encode_i_type(0b0000011, 0b010, rd, rs1, imm)

        if mnemonic == "sw":
            rs2 = parse_register(operands[0])
            imm, rs1 = parse_mem_operand(operands[1])
            return encode_s_type(0b0100011, 0b010, rs2, rs1, imm)

        if mnemonic in {"beq", "bne", "blt", "bge"}:
            rs1 = parse_register(operands[0])
            rs2 = parse_register(operands[1])
            target = operands[2]
            offset = self.resolve_target(target) - inst.pc
            funct3_map = {"beq": 0b000, "bne": 0b001, "blt": 0b100, "bge": 0b101}
            return encode_b_type(0b1100011, funct3_map[mnemonic], rs1, rs2, offset)

        if mnemonic == "jal":
            rd = parse_register(operands[0])
            target = operands[1]
            offset = self.resolve_target(target) - inst.pc
            return encode_j_type(0b1101111, rd, offset)

        if mnemonic == "jalr":
            rd = parse_register(operands[0])
            imm, rs1 = parse_mem_operand(operands[1])
            return encode_i_type(0b1100111, 0b000, rd, rs1, imm)

        if mnemonic == "or":
            rd = parse_register(operands[0])
            rs1 = parse_register(operands[1])
            rs2 = parse_register(operands[2])
            return encode_r_type(0b0110011, 0b110, 0b0000000, rd, rs1, rs2)

        raise ValueError(f"Instruccion no soportada: {mnemonic}")

    def resolve_target(self, token: str) -> int:
        if token in self.labels:
            return self.labels[token]
        return parse_immediate(token)


def write_coe(hex_lines: List[str], path: Path) -> None:
    header = [
        "; COE file generated from firmware.hex",
        "; Memory initialization file for Vivado",
        "memory_initialization_radix=16;",
        "memory_initialization_vector=",
    ]
    body = ",\n".join(hex_lines) + ";"
    content = "\n".join(header) + "\n" + body + "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="ascii")


def copy_hex(hex_lines: List[str], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(hex_lines) + "\n", encoding="ascii")


def main() -> None:
    source = SCRIPT_DIR / "firmware_pcpi.asm"
    target = SCRIPT_DIR / "firmware.hex"
    if len(sys.argv) > 1:
        source = Path(sys.argv[1])
    if len(sys.argv) > 2:
        target = Path(sys.argv[2])
    assembler = MiniAssembler(source, target)
    hex_lines = assembler.assemble()
    print(f"Assembled {source} -> {target}")

    rom_coe = REPO_ROOT / "lab4_pcpi/lab4_pcpi.srcs/sources_1/new/firmware.coe"
    write_coe(hex_lines, rom_coe)
    print(f"Updated {rom_coe}")

    imported_hex = REPO_ROOT / "lab4_pcpi/lab4_pcpi.srcs/sources_1/imports/lab4s/firmware.hex"
    copy_hex(hex_lines, imported_hex)
    print(f"Updated {imported_hex}")


if __name__ == "__main__":
    main()
