# Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]

# Center Button (Reset)
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports btnC]

# Pmod Header JA
set_property -dict { PACKAGE_PIN J18  IOSTANDARD LVCMOS33 } [get_ports cs]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports sdin]
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33 } [get_ports sclk]
set_property -dict { PACKAGE_PIN F18  IOSTANDARD LVCMOS33 } [get_ports d_cn]
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS33 } [get_ports resn]
set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports vccen]
set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVCMOS33 } [get_ports pmoden]