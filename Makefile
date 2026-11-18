IVERILOG ?= iverilog
VVP ?= vvp

BUILD_DIR := build
SIM := $(BUILD_DIR)/alu32_sim
SOURCES := rtl/alu32.v tb/tb_alu32.sv

.PHONY: all test waves lint clean

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(SIM): $(SOURCES) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_alu32 -o $(SIM) $(SOURCES)

test: $(SIM)
	$(VVP) $(SIM)

waves: $(SIM)
	$(VVP) $(SIM) +vcd

lint:
	$(IVERILOG) -g2005 -Wall -tnull -s alu32 rtl/alu32.v

clean:
	rm -rf $(BUILD_DIR)
