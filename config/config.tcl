set ::env(DESIGN_NAME) posit_mul
set ::env(VERILOG_FILES) "$::env(DESIGN_DIR)/src/*.v"

# Clock settings — adjust if needed
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) 200.0

# Auto pin placement mode (good for many pins)
set ::env(FP_IO_MODE) 1

set ::env(PL_TARGET_DENSITY) 0.62