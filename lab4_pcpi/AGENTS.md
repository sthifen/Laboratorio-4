# Repository Guidelines

## Project Structure & Module Organization
Active HDL resides in `rtl/` (PCPI datapath glue such as `unified_pcpi_module.sv`, `decoder_load_store_shift.sv`, `load_store_unit.sv`, `shifter_unit.sv`). Simulation benches live in `sim/` (`tb_unified_pcpi.sv` plus targeted regressions). Firmware sources and artifacts sit under `firmware/` (`firmware_pcpi.asm`, `firmware.hex`, `assemble_firmware.py`), while datasheets/specs stay in `docs/`. Legacy references remain compartmentalized in `legacy/`. Open the deployable Vivado project at `lab4_pcpi/lab4_pcpi.xpr`; its HDL is under `lab4_pcpi/lab4_pcpi.srcs/sources_1/new/` and constraints under `lab4_pcpi/lab4_pcpi.srcs/constrs_1/new/`.

## Build, Test, and Development Commands
Use `vivado lab4_pcpi/lab4_pcpi.xpr &` for interactive work or `vivado -mode batch -source scripts/vivado/run_full_flow.tcl` for automated synthesis/implementation. Run the ROM sanity script with `vivado -mode batch -source scripts/vivado/check_rom.tcl`. Fast simulation flow:
```
xvlog -sv rtl/*.sv sim/tb_unified_pcpi.sv
xelab tb_unified_pcpi -debug typical
xsim tb_unified_pcpi -R --testplusarg firmware=firmware/firmware.hex
```
Icarus smoke tests: `iverilog -g2012 -o build/tb_unified sim/tb_unified_pcpi.sv rtl/*.sv` then `vvp build/tb_unified +firmware=firmware/firmware.hex`. Refresh firmware artifacts with `python firmware/assemble_firmware.py`.

## Coding Style & Naming Conventions
SystemVerilog modules and signals use lower_snake_case with 4-space indentation, `logic` types, and `always_ff`/`always_comb` blocks. Keep display text bilingual (matching existing ALU logs) and guard verbose `$display` statements with enables. File names describe roles (`tb_*`, `*_unit`, `firmware_*.asm`). Preserve the documented memory map from `docs/Proyectos_laboratorio4_EL3313_proyecto.pdf`.

## Testing Guidelines
`sim/tb_unified_pcpi.sv` is the authoritative regression; always run it with the firmware hex that matches your RTL edits and pass `+vcd` when debugging timing. Legacy benches (`legacy/steven_reference/tb_alu_steven.sv`, `legacy/diego_reference/tb_diego_complete.sv`) help isolate ALU/decoder issues. Tests should assert register/memory side effects, cover loads/stores/shifts/JAL, and capture console excerpts or waveforms showing successful paths before submission.

## Commit & Pull Request Guidelines
Commits favor short Spanish subjects (e.g., `Actualizando timer y firmware`, under ~60 chars) plus bodies summarizing HDL and firmware deltas. PRs must list scope, verification commands (Vivado runs, sims, assembler), warnings encountered, and screenshots or logs for new LED/display behavior. Reference necessary firmware rebuild steps and link related issues.

## Firmware & Configuration Tips
Modify `firmware/firmware_pcpi.asm` for behavior changes, then run the GNU toolchain or `python firmware/assemble_firmware.py` to regenerate both `firmware/firmware.hex` and `lab4_pcpi/lab4_pcpi.srcs/imports/lab4s/firmware.hex`. Keep the SoC on the single 10 MHz `clk_i` and respect the ROM/RAM/peripheral map (ROM 0x0000-0x0FFF, RAM 0x1000-0x1FFF, peripherals from 0x2000). Avoid committing Vivado-generated `.gen/` or run directories; only source HDL, constraints, firmware, and docs belong in version control.
