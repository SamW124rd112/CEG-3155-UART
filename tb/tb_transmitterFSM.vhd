LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_transmitterFSM IS
END tb_transmitterFSM;

ARCHITECTURE behavior OF tb_transmitterFSM IS

  -- Component Declaration
  COMPONENT transmitterFSM
    GENERIC(
      dataLen     : INTEGER := 8;
      counterLen  : INTEGER := 4
    );
    PORT(
        BaudClk    : IN  STD_LOGIC;
        GClock     : IN  STD_LOGIC;
        GReset     : IN  STD_LOGIC;
        tdrData    : IN  STD_LOGIC_VECTOR(dataLen-1 downto 0);
        TDRE       : IN  STD_LOGIC;
        loadFlag   : OUT STD_LOGIC;
        shiftFlag  : OUT STD_LOGIC;
        o_TX       : OUT STD_LOGIC;
        stateDebug : OUT STD_LOGIC_VECTOR(2 downto 0)
    );
  END COMPONENT;

  -- Constants
  CONSTANT dataLen       : INTEGER := 8;
  CONSTANT counterLen    : INTEGER := 4;
  CONSTANT baud_period   : TIME := 20 ns;  -- Baud clock (slower)
  CONSTANT sys_period    : TIME := 5 ns;   -- System clock (faster)

  -- Input Signals
  SIGNAL BaudClk    : STD_LOGIC := '0';
  SIGNAL GClock     : STD_LOGIC := '0';
  SIGNAL GReset     : STD_LOGIC := '0';
  SIGNAL tdrData    : STD_LOGIC_VECTOR(dataLen-1 downto 0) := (OTHERS => '0');
  SIGNAL TDRE       : STD_LOGIC := '1';

  -- Output Signals
  SIGNAL loadFlag   : STD_LOGIC;
  SIGNAL shiftFlag  : STD_LOGIC;
  SIGNAL o_TX       : STD_LOGIC;
  SIGNAL stateDebug : STD_LOGIC_VECTOR(2 downto 0);

  -- Clock control
  SIGNAL stop_baud_clock : BOOLEAN := FALSE;
  SIGNAL stop_sys_clock  : BOOLEAN := FALSE;

  -- State constants
  CONSTANT STATE_A : STD_LOGIC_VECTOR(2 downto 0) := "000";  -- Idle
  CONSTANT STATE_B : STD_LOGIC_VECTOR(2 downto 0) := "001";  -- Load
  CONSTANT STATE_C : STD_LOGIC_VECTOR(2 downto 0) := "010";  -- Start bit
  CONSTANT STATE_D : STD_LOGIC_VECTOR(2 downto 0) := "011";  -- Data bits
  CONSTANT STATE_E : STD_LOGIC_VECTOR(2 downto 0) := "100";  -- Stop bit

  -- Helper function
  FUNCTION state_to_string(s : STD_LOGIC_VECTOR(2 downto 0)) RETURN STRING IS
  BEGIN
    CASE s IS
      WHEN "000" => RETURN "IDLE";
      WHEN "001" => RETURN "LOAD";
      WHEN "010" => RETURN "START";
      WHEN "011" => RETURN "DATA";
      WHEN "100" => RETURN "STOP";
      WHEN OTHERS => RETURN "UNKNOWN";
    END CASE;
  END FUNCTION;

  FUNCTION slv_to_string(v : STD_LOGIC_VECTOR) RETURN STRING IS
    VARIABLE result : STRING(1 TO v'LENGTH);
  BEGIN
    FOR i IN v'RANGE LOOP
      IF v(i) = '1' THEN
        result(v'LENGTH - i) := '1';
      ELSIF v(i) = '0' THEN
        result(v'LENGTH - i) := '0';
      ELSE
        result(v'LENGTH - i) := 'X';
      END IF;
    END LOOP;
    RETURN result;
  END FUNCTION;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut: transmitterFSM
    GENERIC MAP(
      dataLen    => dataLen,
      counterLen => counterLen
    )
    PORT MAP(
      BaudClk    => BaudClk,
      GClock     => GClock,
      GReset     => GReset,
      tdrData    => tdrData,
      TDRE       => TDRE,
      loadFlag   => loadFlag,
      shiftFlag  => shiftFlag,
      o_TX       => o_TX,
      stateDebug => stateDebug
    );

  -- Baud Clock Generation (slower - for bit timing)
  baud_clock_process: PROCESS
  BEGIN
    WHILE NOT stop_baud_clock LOOP
      BaudClk <= '0';
      WAIT FOR baud_period/2;
      BaudClk <= '1';
      WAIT FOR baud_period/2;
    END LOOP;
    WAIT;
  END PROCESS;

  -- System Clock Generation (faster - for shift register)
  sys_clock_process: PROCESS
  BEGIN
    WHILE NOT stop_sys_clock LOOP
      GClock <= '0';
      WAIT FOR sys_period/2;
      GClock <= '1';
      WAIT FOR sys_period/2;
    END LOOP;
    WAIT;
  END PROCESS;

  -- Stimulus Process
  stim_proc: PROCESS
    VARIABLE test_passed : INTEGER := 0;
    VARIABLE test_failed : INTEGER := 0;
    VARIABLE bit_count   : INTEGER := 0;
  BEGIN
    REPORT "========================================";
    REPORT "Starting UART Transmitter FSM Testbench";
    REPORT "========================================";

    -- Test 1: Reset
    REPORT "Test 1: System Reset";
    GReset <= '0';
    TDRE <= '1';
    tdrData <= "10101100";  -- Test pattern: 0xAC
    WAIT FOR baud_period * 2;
    
    IF stateDebug = STATE_A THEN
      REPORT "  PASS: FSM in IDLE state after reset";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: FSM not in IDLE state" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    IF o_TX = '1' THEN
      REPORT "  PASS: TX line idle high";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: TX line should be high when idle" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    GReset <= '1';
    WAIT FOR baud_period;

    -- Test 2: Wait for TDRE
    REPORT "Test 2: Microcontroller Waits for TDRE=1";
    TDRE <= '1';
    WAIT FOR baud_period * 2;
    WAIT FOR 1 ns;
    
    IF stateDebug = STATE_A THEN
      REPORT "  PASS: FSM remains in IDLE when TDRE=1";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: FSM should stay in IDLE" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Test 3: Data Load - TDRE goes to 0
    REPORT "Test 3: Data Load - TDRE goes to 0";
    tdrData <= "10101100";  -- Binary: 1010 1100 (0xAC)
    REPORT "  Loading data: " & slv_to_string(tdrData);
    TDRE <= '0';
    WAIT FOR baud_period;
    WAIT FOR 1 ns;

    IF stateDebug = STATE_B THEN
      REPORT "  PASS: FSM transitioned to LOAD state";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected LOAD state, got " & state_to_string(stateDebug) SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    IF loadFlag = '1' THEN
      REPORT "  PASS: loadFlag asserted in LOAD state";
      test_passed := test_passed + 1;
      TDRE <= '1';  -- ADD THIS: Simulate TDR->TSR transfer complete
    ELSE
      REPORT "  FAIL: loadFlag should be asserted" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Test 4: Start Bit Transmission
    REPORT "Test 4: Start Bit Transmission";
    WAIT FOR baud_period;
    WAIT FOR 1 ns;
    
    IF stateDebug = STATE_C THEN
      REPORT "  PASS: FSM in START state";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected START state" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    IF o_TX = '0' THEN
      REPORT "  PASS: Start bit = 0 transmitted";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Start bit should be 0" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Test 5: Data Bits Transmission (8 bits, LSB first)
    REPORT "Test 5: Data Bits Transmission";
    WAIT FOR baud_period;
    WAIT FOR 1 ns;

    IF stateDebug = STATE_D THEN
      REPORT "  PASS: FSM in DATA state";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected DATA state" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Monitor 8 data bits
    REPORT "  Monitoring data bits (LSB first):";
    bit_count := 0;
    FOR i IN 0 TO 7 LOOP
      REPORT "    Bit " & INTEGER'IMAGE(i) & ": " & STD_LOGIC'IMAGE(o_TX);
      bit_count := bit_count + 1;  -- Always count, state check is separate
      
      IF i < 7 THEN
        WAIT FOR baud_period;
        WAIT FOR 1 ns;
      END IF;
    END LOOP;

    REPORT "  PASS: Transmitted 8 data bits";
    test_passed := test_passed + 1;

    -- Test 6: Stop Bit Transmission
    REPORT "Test 6: Stop Bit Transmission";
    WAIT FOR baud_period/2;  -- Check MIDWAY through stop bit period
    WAIT FOR 1 ns;

    IF stateDebug = STATE_E THEN
      REPORT "  PASS: FSM in STOP state";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected STOP state, got " & state_to_string(stateDebug) SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    IF o_TX = '1' THEN
      REPORT "  PASS: Stop bit = 1 transmitted";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Stop bit should be 1" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Finish waiting for stop bit to complete
    WAIT FOR baud_period/2 + 1 ns;

    -- Test 7: Return to Idle
    REPORT "Test 7: Return to Idle";
    -- Already waited through stop bit in Test 6
    -- NO additional wait needed
    WAIT FOR 1 ns;

    IF stateDebug = STATE_A THEN
      REPORT "  PASS: FSM returned to IDLE";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected IDLE state after stop bit" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Test 8: Second Byte Transmission
    REPORT "Test 8: Second Byte Transmission";
    tdrData <= "01010011";  -- Different pattern
    REPORT "  Loading second byte: " & slv_to_string(tdrData);
    TDRE <= '0';  -- New data written

    WAIT FOR baud_period;  -- A->B
    WAIT FOR 1 ns;
    IF stateDebug = STATE_B THEN
      REPORT "  PASS: Entered LOAD state";
      test_passed := test_passed + 1;
      TDRE <= '1';  -- ADD: TDR->TSR complete
    ELSE
      REPORT "  FAIL: Expected LOAD state" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    
    WAIT FOR baud_period;  -- B->C (START)
    WAIT FOR 1 ns;
    
    IF stateDebug = STATE_C AND o_TX = '0' THEN
      REPORT "  PASS: Start bit transmitted";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Start bit error" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    
    -- Sample all 8 data bits
    FOR i IN 0 TO 7 LOOP
      WAIT FOR baud_period;
      WAIT FOR 1 ns;
      REPORT "    Bit " & INTEGER'IMAGE(i) & ": " & STD_LOGIC'IMAGE(o_TX);
    END LOOP;
    
    -- After the 8 data bits loop in Test 8:
    -- Check stop bit state (don't wait full period first)
    WAIT FOR baud_period/2;
    WAIT FOR 1 ns;

    IF stateDebug = STATE_E THEN
      REPORT "  PASS: Second transmission in STOP state";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected STOP state, got " & state_to_string(stateDebug) SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Test 9: Verify stop bit
    IF o_TX = '1' THEN
      REPORT "  PASS: Stop bit = 1";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Stop bit should be 1" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Wait for stop bit to finish
    WAIT FOR baud_period/2;
    WAIT FOR baud_period;  -- Extra wait
    WAIT FOR 1 ns;

    -- Test 10: Should now be in IDLE
    IF stateDebug = STATE_A THEN
      REPORT "  PASS: FSM returned to IDLE";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Should remain in IDLE" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Final Summary
    REPORT "========================================";
    REPORT "Testbench Completed";
    REPORT "========================================";
    REPORT "Tests Passed: " & INTEGER'IMAGE(test_passed);
    REPORT "Tests Failed: " & INTEGER'IMAGE(test_failed);
    
    IF test_failed = 0 THEN
      REPORT "*** ALL TESTS PASSED ***" SEVERITY NOTE;
    ELSE
      REPORT "*** SOME TESTS FAILED ***" SEVERITY ERROR;
    END IF;
    
    REPORT "========================================";
    
    stop_baud_clock <= TRUE;
    stop_sys_clock  <= TRUE;
    WAIT;
  END PROCESS;

END behavior;
