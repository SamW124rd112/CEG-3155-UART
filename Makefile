OBJ_DIR = obj
ENTITY_DIR = entities
OUTPUT_DIR = output
TESTBENCH_DIR = tb
ENTITY_NAME = receiverFSM
TEST_NAME = tb_receiverFSM

#VHDL_SOURCES = oneBitMux2to1.vhd oneBitMux8to1.vhd nBitMux8to1.vhd
#VHDL_SOURCES = enARdFF_2.vhd tFF_2.vhd baudRateGen.vhd nBitComparator.vhd nBitCounter.vhd oneBitMux8to1.vhd dFF_2.vhd oneBitComparator.vhd oneBitMux2to1.vhd
#VHDL_SOURCES = enARdFF_2.vhd nBitComparator.vhd oneBitComparator.vhd receiverFSMControl.vhd nBitRightShiftRegister.vhd nBitCounter.vhd counter.vhd receiverFSM.vhd nBitRegister.vhd oneBitMux2to1.vhd
VHDL_SOURCES = $(wildcard *.vhd)
TESTBENCHES = $(TESTBENCH_DIR)/$(TEST_NAME).vhd
TOP_ENTITY = $(TEST_NAME)

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
	$(ENTITY_DIR)/$(TOP_ENTITY) --vcd=$(OUTPUT_DIR)/$(ENTITY_NAME).vcd --stop-time=100us

view:
	gtkwave $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &

surfer:
	surfer $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &

clean:
	ghdl --clean --workdir=$(OBJ_DIR)
	rm -rf $(ENTITY_DIR)/* #$(OUTPUT_DIR)/$(ENTITY_NAME).vcd 
