TOPLEVEL_LANG = verilog
SIM ?= icarus
COCOTB_LOG_LEVEL = INFO

# Path to cocotb distributed makefile
COCOTB_MAKEFILE := $(shell cocotb-config --makefiles)/Makefile.sim

# Include CocoTB's makefile so its rules are available (optional, we call it explicitly below)
include $(COCOTB_MAKEFILE)

# Virtual environment setup
VENV_DIR = venv
PYTHON = $(VENV_DIR)/bin/python3
PIP = $(VENV_DIR)/bin/pip
ACTIVATE = . $(VENV_DIR)/bin/activate

# Path variables
SRC_DIR = ../src
TB = .

# Check if running in virtual environment
ifndef VIRTUAL_ENV
    RUN_IN_VENV = $(ACTIVATE) &&
else
    RUN_IN_VENV =
endif

# Default target
.PHONY: all
all: setup booths

# Setup virtual environment
.PHONY: setup
setup:
	@echo "==================================="
	@echo "Setting up CocoTB environment..."
	@echo "==================================="
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "Creating virtual environment..."; \
		python3 -m venv $(VENV_DIR); \
		echo "Installing requirements..."; \
		$(PIP) install --upgrade pip; \
		if [ -f "requirements.txt" ]; then \
			$(PIP) install -r requirements.txt; \
		else \
			$(PIP) install cocotb; \
		fi; \
		echo "Setup complete!"; \
	else \
		echo "Virtual environment already exists."; \
		echo "To recreate, run: make clean-venv setup"; \
	fi
	@echo "==================================="

# Booth's multiplier testbench
.PHONY: booths
booths:
	@echo "Running Booth's Multiplier tests..."
	$(RUN_IN_VENV) $(MAKE) -f $(COCOTB_MAKEFILE) sim \
		VERILOG_SOURCES="../src/booths_multiplier.v booths_multiplier_tb_top.v" \
		TOPLEVEL=booths_multiplier_tb_top \
		MODULE=test_booths_multiplier

# exp_adder testbench
.PHONY: exp_adder
exp_adder:
	@echo "Running Exponent Adder tests..."
	iverilog -g2012 -o exp_adder_tb.vvp $(SRC_DIR)/exp_adder.v $(TB)/exp_adder_tb.v
	vvp exp_adder_tb.vvp

# POSIT decoder testbench
.PHONY: posit_decode
posit_decode:
	@echo "Running Posit Decoder tests..."
	iverilog -g2012 -o posit_decoder_tb.vvp $(SRC_DIR)/posit_decoder.v $(TB)/posit_decoder_tb.v
	vvp posit_decoder_tb.vvp

# POSIT encoder testbench
.PHONY: posit_encode
posit_encode:
	@echo "Running Posit Encoder tests..."
	iverilog -g2012 -o posit_encoder_tb.vvp $(SRC_DIR)/posit_encoder.v $(TB)/posit_encoder_tb.v
	vvp posit_encoder_tb.vvp

# Run all tests
.PHONY: test-all
test-all: booths
	@echo "All tests completed!"

# Clean simulation files (extends CocoTB's clean)
.PHONY: clean-sim
clean-sim: clean
	rm -f *.vcd *.vvp
	rm -rf __pycache__
	rm -rf .pytest_cache

# Clean virtual environment
.PHONY: clean-venv
clean-venv:
	@echo "Removing virtual environment..."
	rm -rf $(VENV_DIR)

# Clean everything
.PHONY: clean-all
clean-all: clean-sim clean-venv
	@echo "All clean!"

# Help target
.PHONY: help
help:
	@echo "CocoTB Makefile Targets:"
	@echo "  make setup      - Setup virtual environment"
	@echo "  make booths     - Run Booth's multiplier tests"
	@echo "  make posit      - Run Posit decoder tests"
	@echo "  make test-all   - Run all tests"
	@echo "  make clean      - Clean simulation files (CocoTB default)"
	@echo "  make clean-sim  - Clean simulation files + extras"
	@echo "  make clean-venv - Remove virtual environment"
	@echo "  make clean-all  - Clean everything"
	@echo "  make help       - Show this help message"
