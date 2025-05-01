# Clock signal
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]

# Center button for reset
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# Pmod Header JC for OLED
set_property PACKAGE_PIN K17 [get_ports cs]
set_property IOSTANDARD LVCMOS33 [get_ports cs]
set_property PACKAGE_PIN M18 [get_ports sdin]
set_property IOSTANDARD LVCMOS33 [get_ports sdin]
set_property PACKAGE_PIN N17 [get_ports sclk]
set_property IOSTANDARD LVCMOS33 [get_ports sclk]
set_property PACKAGE_PIN P18 [get_ports d_cn]
set_property IOSTANDARD LVCMOS33 [get_ports d_cn]
set_property PACKAGE_PIN L17 [get_ports resn]
set_property IOSTANDARD LVCMOS33 [get_ports resn]
set_property PACKAGE_PIN M19 [get_ports vccen]
set_property IOSTANDARD LVCMOS33 [get_ports vccen]
set_property PACKAGE_PIN P17 [get_ports pmoden]
set_property IOSTANDARD LVCMOS33 [get_ports pmoden]