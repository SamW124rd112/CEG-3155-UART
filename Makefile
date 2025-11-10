OBJ_DIR = obj
ENTITY_DIR = entities
OUTPUT_DIR = output
TESTBENCH_DIR = tb

VHDL_SOURCES = enARdFF_2.vhd counter.vhd
TESTBENCHES = $(TESTBENCH_DIR)/counter_tb.vhd
TOP_ENTITY = counter_tb

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
	$(ENTITY_DIR)/$(TOP_ENTITY) --vcd=$(OUTPUT_DIR)/counter.vcd --stop-time=200ns

view:
	gtkwave $(OUTPUT_DIR)/counter.vcd &


clean:
	ghdl --clean --workdir=$(OBJ_DIR)
	rm -rf $(ENTITY_DIR)/* $(OUTPUT_DIR)/*.vcd

