# Repository Guidelines

## Project Structure & Module Organization
Active HDL now lives in `rtl/` (PCPI datapath glue: `unified_pcpi_module.sv`, `decoder_load_store_shift.sv`, `load_store_unit.sv`, `shifter_unit.sv`) and `sim/` (`tb_unified_pcpi.sv` plus future benches). Firmware sources and artifacts sit under `firmware/` (`firmware_pcpi.asm`, `firmware.hex`, `assemble_firmware.py`), while datasheets/specs are grouped in `docs/`. All legacy material has a home in `legacy/` (`steven_reference/`, `diego_reference/`, `lab4_snapshot/`, `led_demo/`, `firmware_samples/`). The deployable Vivado project is still `lab4_pcpi/` (open `lab4_pcpi/lab4_pcpi.xpr`).

## Build, Test, and Development Commands
Use Vivado for synthesis/implementation: `vivado lab4_pcpi/lab4_pcpi.xpr &` opens the project, while automated runs can call `vivado -mode batch -source scripts/vivado/run_full_flow.tcl`. A quick ROM/HEX sanity check lives in `scripts/vivado/check_rom.tcl`. For fast simulations, rely on the provided testbench stack:
```sh
xvlog -sv rtl/*.sv sim/tb_unified_pcpi.sv
xelab tb_unified_pcpi -debug typical
xsim tb_unified_pcpi -R --testplusarg firmware=firmware/firmware.hex
```
Icarus Verilog also works for smoke tests: `iverilog -g2012 -o build/tb_unified sim/tb_unified_pcpi.sv rtl/*.sv` followed by `vvp build/tb_unified +firmware=firmware/firmware.hex`.

## Coding Style & Naming Conventions
SystemVerilog modules use lower_snake_case identifiers and 4-space indentation (`unified_pcpi_module.sv`). Prefer `logic` types, `always_ff` for sequential blocks, and `always_comb` for combinational glue. Keep display messages consistent with the existing bilingual (mostly Spanish) tone, and gate debug prints with `$display` just like the ALU logs. HDL and firmware filenames should describe their role (`tb_*`, `*_unit`, `firmware_*.asm`).

## Testing Guidelines
`tb_unified_pcpi.sv` is the authoritative regression; always run it with the firmware that matches your change and enable `+vcd` when debugging timing. The legacy unit benches (`legacy/steven_reference/tb_alu_steven.sv` and `legacy/diego_reference/tb_diego_complete.sv`) are useful for focused fixes. Name new tests `tb_<module>_<scenario>.sv` and assert expected register/memory effects. Target full opcode and LED peripheral coverage before posting a PR, and capture console excerpts showing completed load, store, shift, and JAL paths.

## Commit & Pull Request Guidelines
History currently favors short, descriptive Spanish subjects (`Subiendo proyecto completo de Vivado`); follow that pattern, keep subjects under ~60 characters, and describe firmware/HDL deltas in the body. Each PR should summarize scope, list verification commands executed, note any Vivado warnings, and attach screenshots of relevant waveforms or LED outputs when hardware behavior changes. Reference related issues and call out required firmware rebuilds.

## Firmware & Configuration Tips
Edit `firmware/firmware_pcpi.asm` when changing LED demos or memory maps, then rebuild the ROM image with your toolchain (example: `riscv32-unknown-elf-as firmware/firmware_pcpi.asm -o firmware.o && riscv32-unknown-elf-objcopy -O verilog firmware.o firmware/firmware.hex`). `python firmware/assemble_firmware.py` performs the same rebuild without external toolchains and automatically refreshes `lab4_pcpi/lab4_pcpi.srcs/imports/lab4s/firmware.hex`. Never commit bulky generated folders (`lab4_pcpi.gen/`); track only source HDL, constraints, firmware, and documentation.

## Vivado Source & Constraint Paths
- HDL, ROM/RAM IP stubs, and top-level RTL created directly from Vivado live under `lab4_pcpi/lab4_pcpi.srcs/sources_1/new/` (for example `top_pcpi_led_fpga.sv`, `firmware.coe`, IP wrappers).
- Board constraints live in `lab4_pcpi/lab4_pcpi.srcs/constrs_1/new/`. Edit `Const.xdc` there to keep pin mappings synchronized with Nexys 4 DDR.

## Memory Map & Clock Requirements
- Follow the official lab map extracted from `Proyectos_laboratorio4_EL3313_proyecto.pdf`: ROM 0x0000–0x0FFF (512 words), RAM 0x1000–0x1FFF (256 words), switches 0x2000, LEDs 0x2004, seven-segment data 0x2008, timer control 0x2018, timer data 0x201C, temperature control 0x2030, temperature data 0x2034.
- The entire system—including core, interconnect, and peripherals—must run off the single 10 MHz clock exported by the `clk_i` IP; no extra derived domains unless they are generated within that IP block.
- Use ROM.xci (initialized via `firmware.coe`) for instruction memory and RAM.xci (Dual Single Port) for data space; keep the firmware.hex/coe pair updated when rebuilding the assembler.

## Brecha y cómo cerrarla
1. **CPU completo vs coprocesador** – Actualmente solo existe el acelerador PCPI. Se necesita un núcleo RV32I completo (fetch/decode/execute, PC, pipeline/FSM) que lea la ROM, genere el PC, maneje branches y escriba RAM; decide si reutilizas PicoRV32 completo o escribes un core propio integrando el PCPI como backend.
2. **Cobertura de instrucciones** – El PCPI cubre add/sub/lógicos, addi, jal y unidades de load/store/shift. Faltan slt/sltu y variantes inmediatas, branches (beq/bne/blt/bge) y comparaciones adicionales; amplía decodificador + ALU/módulos para cumplir el mínimo rv32i.
3. **Interconexión y mapa de memoria reales** – El testbench usa memorias internas, sin bus compartido ni multiplexor que arbitre RAM y periféricos. Diseña un bloque de interconexión que, según DataAddress, habilite RAM, timer, LED driver, etc., generando write_enable/read_enable/mem_ready respetando offsets desde 0x2000.
4. **Periféricos mapeados** – Aún no existen módulos HDL para switches/botones, LEDs, displays ni timer. Crea: (a) registro de entrada con sincronizador/antirrebote en 0x2000, (b) registro de salida de LEDs en 0x2004, (c) driver multiplexado de 7 segmentos con registro en 0x2008, (d) temporizador programable con registros 0x2018/0x201C y bandera/interrupción, (e) bloque TMP que controle el ADC.
5. **Sensor de temperatura real** – Instancia el XADC Wizard para el sensor interno de la Nexys 4 DDR (o VP/VN) con reloj dclk_in (~50 MHz del IP), habilita secuencia continua y captura do_out/drdy_out/channel_out. Convierte el código de 12 bits a °C usando T = (raw/4096)*503.975 – 273.15, guarda el resultado (ej. décimas de grado) en 0x2034 y una bandera en 0x2030 que se borre al escribir para iniciar nueva conversión.
6. **Temporizador y aplicación** – Implementa un timer que cuente 1/2/5/10 s según switches (ej. 2 bits en 0x2000). El firmware debe programar el timer (0x201C ticks, 0x2018 start), esperar la bandera de fin, pedir conversión TMP (escribir control), esperar dato listo, convertir a decimal y enviar a 7 segmentos/LEDs.
7. **Firmware completo** – La rutina actual solo prueba la ALU. Se requiere firmware final que inicialice periféricos, programe PLL/clock si aplica, ejecute un bucle principal con timer + sensor, convierta binario a decimal, maneje displays y LEDs de estado, y documente el flujo para la revisión final.
8. **Integración física** – Más allá del testbench, el proyecto Vivado debe instanciar todo el sistema en el toplevel, usar el clock externo de 100 MHz hacia el IP `clk_i` de 10 MHz, mapear switches/LEDs/7seg/I2C/XADC, y sintetizar/implementar para la Nexys 4 DDR con constraints (LVCMOS33) actualizados.

## Implementación SoC actual
- `top_pcpi_led_fpga.sv` es el toplevel sintetizable para Nexys 4 DDR: instancia `clk_i` (PLL 10 MHz), el núcleo `rv32i_core`, `ROM.xci`, `RAM.xci`, el hub de memoria/periféricos, `timer_peripheral`, `seven_seg_driver` y `temp_sensor_xadc` (que usa el XADC interno para leer la temperatura on-chip). `SCL/SDA/TMP_*` se exponen en puertos y quedan en alta impedancia hasta que se implemente el ADT7420 externo.
- El registro de entrada 0x2000 entrega `{10'b0, TMP_CT, TMP_INT, btnU, btnD, btnL, btnR, sw15..sw0}` con sincronización/antirrebote.
- LEDs (0x2004) y siete segmentos (0x2008) son registros de salida de 16 bits y 32 bits respectivamente; los displays se manejan como 8 nibbles hexadecimales (AN0 corresponde al nibble menos significativo).
- Timer: 0x2018 control (bit0 inicia la cuenta usando el valor escrito en 0x201C, bit1 limpia la bandera de fin). La lectura de 0x2018 expone bit0 = running, bit1 = done. El registro 0x201C almacena/expone el número de ticks de 10 MHz a contar.
- Sensor: 0x2030 control (bit0 escritura = solicitar nueva conversión, bit1 escritura = limpiar la bandera `ready`; lectura entrega bit0 = busy, bit1 = ready). 0x2034 entrega la temperatura en décimas de grado Celsius, codificada en complemento a dos de 16 bits.
