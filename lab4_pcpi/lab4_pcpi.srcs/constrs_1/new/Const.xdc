set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock 100 MHz (CLK100MHZ)
set_property PACKAGE_PIN E3 [get_ports clk_100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
# El PLL IP (clk_i) maneja automáticamente la definición del reloj
# create_clock se genera en el archivo .xdc del IP
# create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

## Boton de reset (CPU_RESET) - usa btnC
set_property PACKAGE_PIN E16 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# ===========================================
#   SWITCHES Nexys4 (SW0 - SW15)
# ===========================================
set_property PACKAGE_PIN U9 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]

set_property PACKAGE_PIN U8 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]

set_property PACKAGE_PIN R7 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]

set_property PACKAGE_PIN R6 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]

set_property PACKAGE_PIN R5 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]

set_property PACKAGE_PIN V7 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]

set_property PACKAGE_PIN V6 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]

set_property PACKAGE_PIN V5 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]

set_property PACKAGE_PIN U4 [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]

set_property PACKAGE_PIN V2 [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]

set_property PACKAGE_PIN U2 [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]

set_property PACKAGE_PIN T3 [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]

set_property PACKAGE_PIN T1 [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]

set_property PACKAGE_PIN R3 [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]

set_property PACKAGE_PIN P3 [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]

set_property PACKAGE_PIN P4 [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

# ===========================================
#   BUTTONS Nexys4 (BTNL, BTNR, BTNU, BTND, BTNC)
# ===========================================
set_property PACKAGE_PIN T16 [get_ports {btnL}]
set_property IOSTANDARD LVCMOS33 [get_ports {btnL}]

set_property PACKAGE_PIN R10 [get_ports {btnR}]
set_property IOSTANDARD LVCMOS33 [get_ports {btnR}]

set_property PACKAGE_PIN F15 [get_ports {btnU}]
set_property IOSTANDARD LVCMOS33 [get_ports {btnU}]

set_property PACKAGE_PIN V10 [get_ports {btnD}]
set_property IOSTANDARD LVCMOS33 [get_ports {btnD}]


# ===========================================
#   LEDS Nexys4 (LD0 - LD15)
# ===========================================
set_property PACKAGE_PIN T8 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN V9 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN R8 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN T6 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN T5 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN T4 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN U7 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN U6 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

set_property PACKAGE_PIN V4 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]

set_property PACKAGE_PIN U3 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]

set_property PACKAGE_PIN V1 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]

set_property PACKAGE_PIN R1 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]

set_property PACKAGE_PIN P5 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]

set_property PACKAGE_PIN U1 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]

set_property PACKAGE_PIN R2 [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]

set_property PACKAGE_PIN P2 [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

# ================================
#  DISPLAY 7 SEGMENTOS NEXYS
# ================================
# ANODOS
set_property PACKAGE_PIN M1 [get_ports {AN[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[7]}]

set_property PACKAGE_PIN L1 [get_ports {AN[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[6]}]

set_property PACKAGE_PIN N4 [get_ports {AN[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[5]}]

set_property PACKAGE_PIN N2 [get_ports {AN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[4]}]

set_property PACKAGE_PIN N5 [get_ports {AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]

set_property PACKAGE_PIN M3 [get_ports {AN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]

set_property PACKAGE_PIN M6 [get_ports {AN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]

set_property PACKAGE_PIN N6 [get_ports {AN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]

# SEGMENTOS
set_property PACKAGE_PIN L3 [get_ports {SEG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]

set_property PACKAGE_PIN N1 [get_ports {SEG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]

set_property PACKAGE_PIN L5 [get_ports {SEG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]

set_property PACKAGE_PIN L4 [get_ports {SEG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]

set_property PACKAGE_PIN K3 [get_ports {SEG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]

set_property PACKAGE_PIN M2 [get_ports {SEG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]

set_property PACKAGE_PIN L6 [get_ports {SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]

set_property PACKAGE_PIN M4 [get_ports {SEG[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[7]}]

# ===========================================
#   Temperature Sensor ADT7420 - I2C + alerts
# ===========================================
set_property PACKAGE_PIN F16 [get_ports {SCL}]
set_property IOSTANDARD LVCMOS33 [get_ports {SCL}]
set_property PULLUP true [get_ports {SCL}]

set_property PACKAGE_PIN G16 [get_ports {SDA}]
set_property IOSTANDARD LVCMOS33 [get_ports {SDA}]
set_property PULLUP true [get_ports {SDA}]

set_property PACKAGE_PIN D14 [get_ports {TMP_INT}]
set_property IOSTANDARD LVCMOS33 [get_ports {TMP_INT}]

set_property PACKAGE_PIN C14 [get_ports {TMP_CT}]
set_property IOSTANDARD LVCMOS33 [get_ports {TMP_CT}]
