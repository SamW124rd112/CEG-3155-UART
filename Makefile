OBJ_DIR = obj
ENTITY_DIR = entities
OUTPUT_DIR = output
TESTBENCH_DIR = tb
ENTITY_NAME = tb_debugMsgFSM
TEST_NAME = tb_debugMsgFSM

# Source files
VHDL_SOURCES = $(wildcard *.vhd)

# Testbench Logic
ALL_TB_SOURCES = $(wildcard $(TESTBENCH_DIR)/*.vhd)
ALL_TB_ENTITIES = $(basename $(notdir $(ALL_TB_SOURCES)))

TESTBENCHES = $(TESTBENCH_DIR)/$(TEST_NAME).vhd
TOP_ENTITY = $(TEST_NAME)

all: run

# 1. Create Directories
init:
	mkdir -p $(OBJ_DIR) $(ENTITY_DIR) $(OUTPUT_DIR)

# 2. Analyze (Compile)
analyze: init
	@echo "--- Analyzing Core Sources ---"
	ghdl -a -fsynopsys --workdir=$(OBJ_DIR) $(VHDL_SOURCES)
	@echo "--- Analyzing Testbenches ---"
	# We use || true so compilation continues even if one testbench is broken
	ghdl -a --workdir=$(OBJ_DIR) $(ALL_TB_SOURCES) || true

# 3. Run Specific Test (make run)
elaborate: analyze
	ghdl -e --workdir=$(OBJ_DIR) -o $(ENTITY_DIR)/$(TOP_ENTITY) $(TOP_ENTITY)

run: elaborate
	$(ENTITY_DIR)/$(TOP_ENTITY) --vcd=$(OUTPUT_DIR)/$(ENTITY_NAME).vcd --stop-time=100ms

# 4. Run ALL Tests (make run_all)
# IMPORTANT: Do not add comments inside this block or put spaces after the backslashes!
run_all: analyze
	@echo "============================================="
	@echo "       RUNNING ALL TESTBENCHES"
	@echo "============================================="
	@for tb in $(ALL_TB_ENTITIES); do \
		echo "---------------------------------------------"; \
		echo "Target: $$tb"; \
		if ghdl -e --workdir=$(OBJ_DIR) -o $(ENTITY_DIR)/$$tb $$tb 2>/dev/null; then \
			echo " [OK] Running simulation..."; \
			$(ENTITY_DIR)/$$tb --vcd=$(OUTPUT_DIR)/$$tb.vcd --stop-time=100ms || true; \
		else \
			echo " [ERROR] Elaboration failed (Check entity name matches filename)"; \
		fi; \
	done
	@echo "---------------------------------------------"
	@echo "All tests finished."

view:
	gtkwave $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &

surfer:
	surfer $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &

clean:
	ghdl --clean --workdir=$(OBJ_DIR)
	rm -rf $(ENTITY_DIR)/* $(OUTPUT_DIR)/*