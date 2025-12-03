## Clock 100 MHz (CLK100MHZ)
set_property PACKAGE_PIN E3 [get_ports clk_100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

## Botón de reset (CPU_RESET)
set_property PACKAGE_PIN C12 [get_ports reset_btn]
set_property IOSTANDARD LVCMOS33 [get_ports reset_btn]

## LEDs 0-15
set_property PACKAGE_PIN T8  [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN V9  [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN R8  [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN T6  [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN T5  [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN T4  [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN U7  [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN U6  [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

set_property PACKAGE_PIN V4  [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]

set_property PACKAGE_PIN U3  [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]

set_property PACKAGE_PIN V1  [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]

set_property PACKAGE_PIN R1  [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]

set_property PACKAGE_PIN P5  [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]

set_property PACKAGE_PIN U1  [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]

set_property PACKAGE_PIN R2  [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]

set_property PACKAGE_PIN P2  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]
