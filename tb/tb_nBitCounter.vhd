LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_nBitCounter IS
END tb_nBitCounter;

ARCHITECTURE behavior OF tb_nBitCounter IS

  -- Component Declaration
  COMPONENT nBitCounter
    GENERIC(n : INTEGER := 4);
    PORT(
      i_resetBar   : IN  STD_LOGIC;
      i_resetCount : IN  STD_LOGIC;
      i_load       : IN  STD_LOGIC;
      i_clock      : IN  STD_LOGIC;
      o_Value      : OUT STD_LOGIC_VECTOR(n-1 downto 0)
    );
  END COMPONENT;

  -- Constants
  CONSTANT n : INTEGER := 4;
  CONSTANT clock_period : TIME := 10 ns;

  -- Test Signals
  SIGNAL i_resetBar   : STD_LOGIC := '0';
  SIGNAL i_resetCount : STD_LOGIC := '0';
  SIGNAL i_load       : STD_LOGIC := '0';
  SIGNAL i_clock      : STD_LOGIC := '0';
  SIGNAL o_Value      : STD_LOGIC_VECTOR(n-1 downto 0);

  -- Clock control
  SIGNAL stop_clock : BOOLEAN := FALSE;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut: nBitCounter
    GENERIC MAP(n => n)
    PORT MAP(
      i_resetBar   => i_resetBar,
      i_resetCount => i_resetCount,
      i_load       => i_load,
      i_clock      => i_clock,
      o_Value      => o_Value
    );

  -- Clock Generation Process
  clock_process: PROCESS
  BEGIN
    WHILE NOT stop_clock LOOP
      i_clock <= '0';
      WAIT FOR clock_period/2;
      i_clock <= '1';
      WAIT FOR clock_period/2;
    END LOOP;
    WAIT;
  END PROCESS;

  -- Stimulus Process
  stim_proc: PROCESS
    VARIABLE held_value : STD_LOGIC_VECTOR(n-1 downto 0);
    VARIABLE test_passed : INTEGER := 0;
    VARIABLE test_failed : INTEGER := 0;
  BEGIN
    -- Initialize signals
    REPORT "========================================";
    REPORT "Starting nBitCounter Testbench";
    REPORT "========================================";
    
    -- Test 1: Asynchronous Reset (Active Low)
    REPORT "Test 1: Testing Asynchronous Reset (i_resetBar = '0')";
    i_resetBar <= '0';
    i_resetCount <= '0';
    i_load <= '0';
    WAIT FOR clock_period * 2;
    IF o_Value = "0000" THEN
      REPORT "  PASS: Async reset correctly sets output to 0000";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Async reset failed - Expected: 0000" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    
    -- Release async reset
    i_resetBar <= '1';
    WAIT FOR clock_period;

    -- Test 2: Normal Counting with Enable
    REPORT "Test 2: Normal Counting (i_load = '1')";
    i_load <= '1';
    i_resetCount <= '0';
    WAIT FOR clock_period;  -- Wait for first clock edge
    WAIT FOR 1 ns;  -- Small delta to sample after clock edge
    IF o_Value = "0001" THEN
      REPORT "  PASS: Counter incremented to 0001";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected 0001 after first increment" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    
    WAIT FOR clock_period * 3;
    WAIT FOR 1 ns;
    IF o_Value = "0100" THEN
      REPORT "  PASS: Counter at 0100 after 4 clocks";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected 0100 after 4 clocks" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    
    WAIT FOR clock_period * 12;  -- Complete the cycle

    -- Test 3: Disable Counting
    REPORT "Test 3: Disable Counting (i_load = '0')";
    WAIT FOR 1 ns;
    held_value := o_Value;  -- Store current value
    i_load <= '0';
    WAIT FOR clock_period * 4;
    WAIT FOR 1 ns;
    IF o_Value = held_value THEN
      REPORT "  PASS: Counter held value when i_load = '0'";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Counter changed when disabled" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;

    -- Test 4: Re-enable Counting
    REPORT "Test 4: Re-enable Counting";
    i_load <= '1';
    WAIT FOR clock_period;
    WAIT FOR 1 ns;
    IF o_Value = "0001" THEN
      REPORT "  PASS: Counter resumed counting correctly";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Counter did not resume correctly" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    WAIT FOR clock_period * 4;

    -- Test 5: Synchronous Reset to Zero (FIXED TIMING)
    REPORT "Test 5: Synchronous Reset (i_resetCount = '1')";
    i_resetCount <= '1';
    WAIT FOR clock_period;  -- Apply for one clock cycle
    WAIT FOR 1 ns;  -- Sample after clock edge
    IF o_Value = "0000" THEN
      REPORT "  PASS: Synchronous reset correctly sets output to 0000";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Synchronous reset failed - Expected: 0000" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    i_resetCount <= '0';  -- De-assert AFTER checking
    WAIT FOR clock_period;

    -- Test 6: Count After Synchronous Reset
    REPORT "Test 6: Continue Counting After Synchronous Reset";
    WAIT FOR 1 ns;
    IF o_Value = "0001" THEN
      REPORT "  PASS: Counter counting after sync reset";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Expected 0001 after sync reset" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    WAIT FOR clock_period * 9;

    -- Test 7: Multiple Synchronous Resets
    REPORT "Test 7: Multiple Synchronous Resets";
    i_resetCount <= '1';
    WAIT FOR clock_period;
    WAIT FOR 1 ns;
    IF o_Value = "0000" THEN
      REPORT "  PASS: First sync reset successful";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: First sync reset failed" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    i_resetCount <= '0';
    WAIT FOR clock_period * 3;
    i_resetCount <= '1';
    WAIT FOR clock_period;
    WAIT FOR 1 ns;
    IF o_Value = "0000" THEN
      REPORT "  PASS: Second sync reset successful";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Second sync reset failed" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    i_resetCount <= '0';
    WAIT FOR clock_period * 3;

    -- Test 8: Asynchronous Reset Override
    REPORT "Test 8: Asynchronous Reset During Active Counting";
    i_load <= '1';
    WAIT FOR clock_period * 3;
    i_resetBar <= '0';  -- Assert async reset
    WAIT FOR 1 ns;
    IF o_Value = "0000" THEN
      REPORT "  PASS: Async reset works during counting";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Async reset during counting failed" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    WAIT FOR clock_period;
    i_resetBar <= '1';  -- Release async reset
    WAIT FOR clock_period * 3;

    -- Test 9: Hold with Synchronous Reset
    REPORT "Test 9: i_load = '0' with i_resetCount = '1'";
    held_value := o_Value;
    i_load <= '0';
    i_resetCount <= '1';
    WAIT FOR clock_period;
    WAIT FOR 1 ns;
    IF o_Value = held_value THEN
      REPORT "  PASS: Counter held when disabled, even with sync reset";
      test_passed := test_passed + 1;
    ELSE
      REPORT "  FAIL: Counter should hold when i_load = '0'" SEVERITY ERROR;
      test_failed := test_failed + 1;
    END IF;
    i_resetCount <= '0';
    WAIT FOR clock_period * 2;
    i_load <= '1';
    WAIT FOR clock_period * 5;

    -- End Simulation - Final Summary
    REPORT "========================================";
    REPORT "Testbench Completed";
    REPORT "========================================";
    
    -- Report results using string concatenation (VHDL-93 compatible)
    IF test_failed = 0 THEN
      REPORT "*** ALL TESTS PASSED ***" SEVERITY NOTE;
    ELSE
      REPORT "*** SOME TESTS FAILED ***" SEVERITY ERROR;
    END IF;
    
    REPORT "========================================";
    
    stop_clock <= TRUE;
    WAIT;
  END PROCESS;

END behavior;
