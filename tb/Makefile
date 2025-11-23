TOPLEVEL_LANG = verilog 
VERILOG_SOURCES = ../src/booths_multiplier.v \
                  booths_multiplier_tb_top.v
TOPLEVEL = booths_multiplier_tb_top
MODULE = test_booths_multiplier 

# Simulation 
SIM ?= icarus

# CocoTB parameters 
COCOTB_LOG_LEVEL = INFO 

include $(shell cocotb-config --makefiles)/Makefile.sim
