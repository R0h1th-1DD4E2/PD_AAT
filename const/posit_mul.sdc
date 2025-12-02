################################################################################
# Simple SDC File for posit_mul
# Clock: 5 MHz (200 ns period)
################################################################################

# Create clock - 5 MHz
create_clock -name clk -period 200.0 [get_ports clk]

# Clock uncertainty (jitter/skew)
set_clock_uncertainty 5.0 [get_clocks clk]

# Input delays (30% of clock period)
set_input_delay -clock clk -max 60.0 [all_inputs]
set_input_delay -clock clk -min 10.0 [all_inputs]

# Output delays (30% of clock period)
set_output_delay -clock clk -max 60.0 [all_outputs]
set_output_delay -clock clk -min 10.0 [all_outputs]

# Output load
set_load 0.05 [all_outputs]

# Design rules
set_max_transition 5.0 [current_design]
set_max_fanout 16 [current_design]

# Reset is asynchronous - false path
set_false_path -from [get_ports rst_n]

################################################################################
# End of SDC
################################################################################