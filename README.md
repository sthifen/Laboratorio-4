# 🌡️ Sistema Lector de Temperatura RISC-V

<div align="center">

![RISC-V](https://img.shields.io/badge/RISC--V-RV32I-blue?style=for-the-badge)
![FPGA](https://img.shields.io/badge/FPGA-Artix--7-orange?style=for-the-badge)
![Vivado](https://img.shields.io/badge/Vivado-2025.1-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Laboratorio 4**  
Instituto Tecnológico de Costa Rica

</div>

---

## Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Características](#-características)
- [Arquitectura del Sistema](#-arquitectura-del-sistema)
- [Componentes Hardware](#-componentes-hardware)
- [Mapa de Memoria](#-mapa-de-memoria)
- [Software (Firmware)](#-software-firmware)
- [Instalación y Uso](#-instalación-y-uso)
- [Simulación](#-simulación)
- [Síntesis e Implementación](#-síntesis-e-implementación)
- [Equipo](#-equipo)
- [Licencia](#-licencia)

---

##  Descripción General

Sistema embebido basado en arquitectura **RISC-V (RV32I)** implementado en FPGA que funciona como **termómetro digital de oficina**. El sistema lee temperatura mediante el sensor XADC integrado, la muestra en displays de 7 segmentos, y permite configurar el período de muestreo mediante switches.

### Objetivos del Proyecto

Implementar un procesador RISC-V de 32 bits  
Desarrollar firmware en ensamblador (bare-metal)  
Integrar periféricos memory-mapped  
Utilizar IP-Cores de Xilinx (BRAM, XADC)  
Diseñar sistema de adquisición de datos en tiempo real  

---

##  Características

### Hardware
-  **Procesador**: rv32i_core (RISC-V 32-bit Integer)
-  **Memoria ROM**: 2 KB (almacena programa)
-  **Memoria RAM**: 4 KB (datos y stack)
-  **Sensor**: XADC de 12 bits (0-1V, 1 MSPS)
-  **Display**: 8 dígitos de 7 segmentos
-  **Timer**: Temporizador programable
-  **I/O**: 16 switches, 5 botones, 16 LEDs

### Software
-  Programación en **ensamblador RISC-V**
-  **Bare-metal** (sin sistema operativo)
-  Actualización periódica configurable (1, 2, 5, 10 segundos)
-  Conversión de temperatura (valor RAW → °C decimal)
-  Interfaz visual en display de 7 segmentos

---

##  Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                     SISTEMA COMPLETO                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐      ┌─────────────┐                    │
│  │  Clk Wizard  │──────▶│ rv32i_core  │                    │
│  │  (100→10MHz) │      │  (RISC-V)   │                    │
│  └──────────────┘      └──────┬──────┘                    │
│                               │                            │
│                      ┌────────┴────────┐                   │
│                      │                 │                   │
│               ┌──────▼─────┐    ┌─────▼──────┐           │
│               │   ROM IP   │    │   RAM IP   │           │
│               │   (2 KB)   │    │   (4 KB)   │           │
│               └────────────┘    └────────────┘           │
│                                                            │
│        ┌───────────────── Bus de Datos ─────────────────┐ │
│        │                                                 │ │
│  ┌─────▼──────┐  ┌────────┐  ┌────────┐  ┌───────────┐ │
│  │   Switches │  │  LEDs  │  │ 7-Seg  │  │   Timer   │ │
│  │   (0x2000) │  │(0x2004)│  │(0x2008)│  │ (0x2018)  │ │
│  └────────────┘  └────────┘  └────────┘  └───────────┘ │
│                                                          │ │
│  ┌──────────────────────────┐                          │ │
│  │  Sensor Temperatura      │                          │ │
│  │  (XADC)                  │                          │ │
│  │  • Control: 0x2030       │                          │ │
│  │  • Data:    0x2034       │                          │ │
│  └──────────────────────────┘                          │ │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

---

##  Componentes Hardware

### 1. Procesador RISC-V (rv32i_core)
- Arquitectura Harvard (buses separados para instrucciones y datos)
- Frecuencia: 10 MHz
- Conjunto de instrucciones: RV32I base
- Pipeline de ejecución optimizado

### 2. Memorias (IP-Cores Xilinx)

#### ROM (Block Memory Generator)
- **Tamaño**: 2 KB (512 palabras × 32 bits)
- **Función**: Almacenar firmware (programa en ensamblador)
- **Inicialización**: Archivo `.hex` con código compilado

#### RAM (Block Memory Generator)
- **Tamaño**: 4 KB (1024 palabras × 32 bits)
- **Función**: Variables, stack, datos temporales
- **Configuración**: True Dual-Port RAM

### 3. Sensor de Temperatura (XADC)

| Característica | Valor |
|----------------|-------|
| Resolución | 12 bits |
| Tasa de muestreo | 1 MSPS |
| Rango de entrada | 0 - 1.0 V |
| Resolución térmica | ~244 µV/nivel |
| Ciclos por conversión | 26 |
| Canales externos | 17 |
| Sensor interno | Temperatura del chip |

**Modos de operación:**
- `SIMULATION=1`: Genera temperaturas sintéticas (22-36°C)
- `SIMULATION=0`: Lee temperatura real del chip FPGA

### 4. Display de 7 Segmentos
- 8 dígitos multiplexados
- Frecuencia de refresco: 60 Hz
- Formato: `XX.X °C` (temperatura con un decimal)

### 5. Timer Programable
- Contador descendente de 32 bits
- Configurable mediante switches
- Genera señal de expiración periódica

---

##  Mapa de Memoria

| Dirección | Periférico | Tipo | Descripción |
|-----------|-----------|------|-------------|
| `0x0000_0000` - `0x0000_07FF` | ROM | R | Memoria de programa (2 KB) |
| `0x0000_1000` - `0x0000_1FFF` | RAM | R/W | Memoria de datos (4 KB) |
| `0x0000_2000` | Switches | R | Lectura de 16 switches + 4 botones |
| `0x0000_2004` | LEDs | W | Control de 16 LEDs |
| `0x0000_2008` | Display | W | Control de 7 segmentos (32 bits) |
| `0x0000_2018` | Timer Control | R/W | Control del timer |
| `0x0000_201C` | Timer Data | R/W | Valor del timer (32 bits) |
| `0x0000_2030` | Temp Control | R/W | Control del sensor XADC |
| `0x0000_2034` | Temp Data | R | Lectura de temperatura (12 bits) |

### Registros del Sensor de Temperatura

#### TEMP_CTRL (0x2030)
```
Bit 0: CONVERSION_START (W) / DATA_READY (R)
Bit 1: CLEAR_FLAG (W)
```

**Uso:**
- Escribir `1`: Iniciar conversión
- Leer bit 0: `1` = dato listo, `0` = conversión en proceso
- Escribir `2`: Limpiar flag de dato listo

#### TEMP_DATA (0x2034)
```
Bits [11:0]: Temperatura en décimas de °C
Bits [31:12]: No usados (cero)
```

**Ejemplo:** `0x00DC` (220 decimal) = 22.0 °C

---

## 💻 Software (Firmware)

### Diagrama de Flujo

```
┌─────────────┐
│    INICIO   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  Inicialización:    │
│  • Timer            │
│  • Sensor XADC      │
│  • Display          │
│  • LEDs             │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Leer Switches      │
│  (período: 1-10s)   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Configurar Timer   │
│  Iniciar cuenta     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Esperar Timer      │◄──────────┐
│  (polling)          │           │
└──────┬──────────────┘           │
       │ Timer Done               │
       ▼                          │
┌─────────────────────┐           │
│  Iniciar Conversión │           │
│  TEMP_CTRL = 1      │           │
└──────┬──────────────┘           │
       │                          │
       ▼                          │
┌─────────────────────┐           │
│  Esperar Flag       │           │
│  (polling TEMP_CTRL)│           │
└──────┬──────────────┘           │
       │ Data Ready               │
       ▼                          │
┌─────────────────────┐           │
│  Leer Temperatura   │           │
│  temp = TEMP_DATA   │           │
└──────┬──────────────┘           │
       │                          │
       ▼                          │
┌─────────────────────┐           │
│  Limpiar Flag       │           │
│  TEMP_CTRL = 2      │           │
└──────┬──────────────┘           │
       │                          │
       ▼                          │
┌─────────────────────┐           │
│  Convertir a BCD    │           │
│  y Actualizar       │           │
│  Display            │           │
└──────┬──────────────┘           │
       │                          │
       └──────────────────────────┘
```

### Ejemplo de Código Ensamblador

```assembly
# ====================================
# Firmware: Lector de Temperatura
# ====================================

.equ TEMP_CTRL, 0x2030
.equ TEMP_DATA, 0x2034
.equ DISPLAY,   0x2008

# --- Iniciar conversión ---
li t0, TEMP_CTRL
li t1, 1
sw t1, 0(t0)           # TEMP_CTRL = 1

# --- Esperar dato listo ---
wait_temp:
    lw t2, 0(t0)       # Leer TEMP_CTRL
    andi t2, t2, 1     # Verificar bit 0
    beqz t2, wait_temp # Si no está listo, seguir esperando

# --- Leer temperatura ---
li t0, TEMP_DATA
lw t3, 0(t0)           # t3 = temperatura (décimas °C)

# --- Limpiar flag ---
li t0, TEMP_CTRL
li t1, 2
sw t1, 0(t0)           # TEMP_CTRL = 2

# --- Actualizar display ---
li t0, DISPLAY
sw t3, 0(t0)           # Mostrar temperatura

# --- Repetir ---
j wait_timer
```

---

##  Instalación y Uso

### Requisitos

- **Software**:
  - Xilinx Vivado 2025.1 o superior
  - RISC-V GNU Toolchain (ensamblador/compilador)
  
- **Hardware**:
  - FPGA Artix-7 (Basys 3 o Nexys A7)
  - Cable USB para programación

### Pasos de Instalación

#### 1. Clonar el Repositorio
```bash
git clone https://github.com/tu-usuario/lab4-temperatura-riscv.git
cd lab4-temperatura-riscv
```

#### 2. Abrir Proyecto en Vivado
```bash
vivado lab4_pcpi.xpr &
```

#### 3. Compilar Firmware
```bash
cd firmware/
riscv32-unknown-elf-as -o firmware.o firmware.s
riscv32-unknown-elf-ld -Ttext=0x0 -o firmware.elf firmware.o
riscv32-unknown-elf-objcopy -O binary firmware.elf firmware.bin
python3 bin2hex.py firmware.bin firmware.hex
```

#### 4. Cargar Firmware en ROM
- En Vivado: `IP Catalog → Block Memory Generator → Customize IP`
- Cargar archivo `firmware.hex` como contenido inicial

---

##  Simulación

### Testbench Incluido

El proyecto incluye `tb_temperature_system.sv` que simula el sistema completo:

```tcl
# En Vivado TCL Console
launch_simulation
run 20ms
```

### Características del Testbench

Genera reloj de 100 MHz  
Simula conversiones de temperatura (22-36°C)  
Monitorea bus de datos  

```
╔══════════════════════════════════════════════════════════════╗
║              LECTURA DE TEMPERATURA #1                    ║
╠══════════════════════════════════════════════════════════════╣
║  Tiempo:       850000 ns                                     ║
║    Temperatura: 22.0 °C                                    ║
║   Valor RAW:    0x0DC (220)                                ║
║   Display:      0x000000DC                                 ║
║   Instrucciones: 1542                                      ║
╚══════════════════════════════════════════════════════════════╝
```

### Verificación

```tcl
# Ver ondas
add_wave_divider "CPU Signals"
add_wave /tb_temperature_system/dut/core_inst/*

add_wave_divider "Temperature Sensor"
add_wave /tb_temperature_system/dut/temp_inst/*

# Correr más tiempo
run 50ms
```

---

## ⚡ Síntesis e Implementación

### Síntesis
```tcl
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
```

### Implementación
```tcl
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
```

### Programar FPGA
```tcl
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [get_hw_devices xc7a*]
```

### Recursos Utilizados (Estimado)

| Recurso | Utilizado | Disponible | % |
|---------|-----------|------------|---|
| LUTs | ~3,500 | 33,280 | ~10% |
| FFs | ~2,000 | 66,560 | ~3% |
| BRAM | 8 | 50 | 16% |
| DSPs | 0 | 120 | 0% |

---

## 🎮 Modo de Uso

### Configuración Inicial

1. **Encender la FPGA**: Conectar y programar bitstream
2. **Configurar período**: Usar switches SW[1:0]
   - `00`: 1 segundo
   - `01`: 2 segundos
   - `10`: 5 segundos
   - `11`: 10 segundos

### Operación Normal

1. El sistema lee temperatura automáticamente
2. La temperatura se muestra en el display: `XX.X °C`
3. Los LEDs indican el estado del sistema
4. Cambiar switches actualiza el período de muestreo

### Botones

- **btnC**: Reset del sistema
- **btnL/R/U/D**: Funciones adicionales (según firmware)

---

##  Equipo

| Nombre | Carné | Rol |
|--------|-------|-----|
| **Kimberly Morales Alvarado** | 2019244146 | Coordinadora, Documentación |
| **Steven Andrey Fonseca Bermúdez** | 2021067613 | Integración Hardware |
| **Diego Reyes** | 2022256814 | Firmware Assembly |
| **Juan Gabriel Alfaro Alfaro** | 2021135556 | Testing y Validación |

**Institución**: Instituto Tecnológico de Costa Rica  
**Semestre**: II-2025  

---

##  Referencias

1. [RISC-V Instruction Set Manual](https://riscv.org/technical/specifications/)
2. [Xilinx 7 Series FPGAs XADC User Guide (UG480)](https://www.xilinx.com/support/documentation/user_guides/ug480_7Series_XADC.pdf)
3. [Block Memory Generator v8.4 Product Guide (PG058)](https://www.xilinx.com/support/documentation/ip_documentation/blk_mem_gen/v8_4/pg058-blk-mem-gen.pdf)
4. Apuntes del curso EL3313 - Arquitectura de Computadoras

---

##  Licencia

Este proyecto fue desarrollado con fines educativos como parte del curso Taller de sistemas digitals en el Instituto Tecnológico de Costa Rica.

```
MIT License

Copyright (c) 2025 Equipo Lab 4 - 

Se concede permiso para usar, copiar, modificar y distribuir este software
con fines educativos.
```

---



<div align="center">




</div>
