OBJ_DIR = obj
ENTITY_DIR = entities
OUTPUT_DIR = output
TESTBENCH_DIR = tb
ENTITY_NAME = nBitMux8to1

VHDL_SOURCES = oneBitMux2to1.vhd oneBitMux8to1.vhd nBitMux8to1.vhd
#VHDL_SOURCES = enARdFF_2.vhd nBitLeftShiftRegister.vhd
TESTBENCHES = $(TESTBENCH_DIR)/tb_nBitMux8to1.vhd
TOP_ENTITY = tb_nBitMux8to1

all: run

analyze:
	mkdir -p $(OBJ_DIR) $(ENTITY_DIR) $(OUTPUT_DIR)
	ghdl -a --workdir=$(OBJ_DIR) $(VHDL_SOURCES)
	ghdl -a --workdir=$(OBJ_DIR) $(TESTBENCHES)

elaborate: analyze
	# Elaborate using the same workdir, create executable in ENTITY_DIR
	ghdl -e --workdir=$(OBJ_DIR) -o $(ENTITY_DIR)/$(TOP_ENTITY) $(TOP_ENTITY)

run: elaborate
	# Run the simulation using the executable in ENTITY_DIR
	$(ENTITY_DIR)/$(TOP_ENTITY) --vcd=$(OUTPUT_DIR)/$(ENTITY_NAME).vcd --stop-time=500ns

view:
	gtkwave $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &


clean:
	ghdl --clean --workdir=$(OBJ_DIR)
	rm -rf $(ENTITY_DIR)/* #$(OUTPUT_DIR)/$(ENTITY_NAME).vcd

