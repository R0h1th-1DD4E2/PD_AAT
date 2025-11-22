# Makefile for CocoTB simulation

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = ../src/booths_multiplier.v
TOPLEVEL = booths_multiplier
MODULE = test_booths_multiplier

# simulation
SIM ?= icarus

# CocoTB parameters
COCOTB_LOG_LEVEL = INFO
WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim
