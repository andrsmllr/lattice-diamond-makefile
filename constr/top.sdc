create_clock -name clk_i -period 8.333 -waveform {0 50}  [get_ports clk_i]
create_clock -name osc_clk -period 15.037 -waveform {0 50}  [get_pins on_board_rc_oscillator_inst/osc_clk]


set_property PACKAGE_PIN C8  [get_ports {clk_i}];
set_property PACKAGE_PIN H11 [get_ports {led_o[0]}];
set_property PACKAGE_PIN J13 [get_ports {led_o[1]}];
set_property PACKAGE_PIN J11 [get_ports {led_o[2]}];
set_property PACKAGE_PIN L12 [get_ports {led_o[3]}];
set_property PACKAGE_PIN K11 [get_ports {led_o[4]}];
set_property PACKAGE_PIN L13 [get_ports {led_o[5]}];
set_property PACKAGE_PIN N15 [get_ports {led_o[6]}];
set_property PACKAGE_PIN P16 [get_ports {led_o[7]}];
set_property PACKAGE_PIN N2  [get_ports {dip_sw_i[0]}];
set_property PACKAGE_PIN P1  [get_ports {dip_sw_i[1]}];
set_property PACKAGE_PIN M3  [get_ports {dip_sw_i[2]}];
set_property PACKAGE_PIN N1  [get_ports {dip_sw_i[3]}];
