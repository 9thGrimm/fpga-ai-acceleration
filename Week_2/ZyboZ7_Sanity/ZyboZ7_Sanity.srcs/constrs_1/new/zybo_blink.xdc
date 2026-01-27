############################################
## Clock Source (Zybo Z7-20)
############################################
set_property PACKAGE_PIN K17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 8.000 -name sys_clk -waveform {0 4} [get_ports clk]
# 125 MHz clock (8 ns period)

############################################
## Push Button BTN0 → rst_n
############################################
set_property PACKAGE_PIN K18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

############################################
## User LEDs (LD0-LD3)
############################################
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
