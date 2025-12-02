LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_counter3Bit IS
END tb_counter3Bit;

ARCHITECTURE behavior OF tb_counter3Bit IS

    COMPONENT counter3Bit
        PORT(
            GClock     : IN  STD_LOGIC;
            GReset     : IN  STD_LOGIC;
            i_reset    : IN  STD_LOGIC;
            i_enable   : IN  STD_LOGIC;
            o_count    : OUT STD_LOGIC_VECTOR(2 downto 0);
            o_maxReach : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT CLK_PERIOD : TIME := 10 ns;

    SIGNAL GClock     : STD_LOGIC := '0';
    SIGNAL GReset     : STD_LOGIC := '0';
    SIGNAL i_reset    : STD_LOGIC := '0';
    SIGNAL i_enable   : STD_LOGIC := '0';
    SIGNAL o_count    : STD_LOGIC_VECTOR(2 downto 0);
    SIGNAL o_maxReach : STD_LOGIC;

    SIGNAL stop_clock   : BOOLEAN := FALSE;
    SIGNAL tests_passed : INTEGER := 0;
    SIGNAL tests_failed : INTEGER := 0;

BEGIN

    UUT: counter3Bit
        PORT MAP(
            GClock     => GClock,
            GReset     => GReset,
            i_reset    => i_reset,
            i_enable   => i_enable,
            o_count    => o_count,
            o_maxReach => o_maxReach
        );

    clock_process: PROCESS
    BEGIN
        WHILE NOT stop_clock LOOP
            GClock <= '0';
            WAIT FOR CLK_PERIOD/2;
            GClock <= '1';
            WAIT FOR CLK_PERIOD/2;
        END LOOP;
        WAIT;
    END PROCESS;

    stim_proc: PROCESS

        PROCEDURE check_count(
            expected : INTEGER;
            max_expected : STD_LOGIC;
            test_name : STRING
        ) IS
            VARIABLE actual : INTEGER;
        BEGIN
            actual := to_integer(unsigned(o_count));
            IF actual = expected AND o_maxReach = max_expected THEN
                REPORT test_name & ": PASS - Count=" & INTEGER'IMAGE(actual) &
                       ", MaxReach=" & STD_LOGIC'IMAGE(o_maxReach);
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT test_name & ": FAIL - Expected Count=" & INTEGER'IMAGE(expected) &
                       ", MaxReach=" & STD_LOGIC'IMAGE(max_expected) &
                       " Got Count=" & INTEGER'IMAGE(actual) &
                       ", MaxReach=" & STD_LOGIC'IMAGE(o_maxReach) SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            END IF;
        END PROCEDURE;
        
        -- Wait for rising edge then small delta for outputs to settle
        PROCEDURE wait_and_check(
            expected : INTEGER;
            max_expected : STD_LOGIC;
            test_name : STRING
        ) IS
        BEGIN
            WAIT UNTIL rising_edge(GClock);
            WAIT FOR 1 ns;
            check_count(expected, max_expected, test_name);
        END PROCEDURE;

    BEGIN
        REPORT "========================================";
        REPORT "Starting counter3Bit Testbench";
        REPORT "Counter counts 0-5, wraps to 0";
        REPORT "o_maxReach = 1 when count = 5";
        REPORT "========================================";

        -- Test 1: Async Reset
        REPORT "--- Test 1: Async Reset ---";
        GReset <= '0';
        i_reset <= '0';
        i_enable <= '0';
        WAIT FOR CLK_PERIOD * 2;
        WAIT FOR 1 ns;
        check_count(0, '0', "Async reset");
        
        GReset <= '1';
        WAIT FOR CLK_PERIOD;

        -- Test 2: Count sequence 0 -> 5
        REPORT "--- Test 2: Count Sequence 0-5 ---";
        i_enable <= '1';
        i_reset <= '0';
        
        -- Check initial value (before first enabled clock edge)
        WAIT FOR 1 ns;
        check_count(0, '0', "Initial count 0");
        
        -- Now count through 0 to 5
        wait_and_check(1, '0', "Count 1");
        wait_and_check(2, '0', "Count 2");
        wait_and_check(3, '0', "Count 3");
        wait_and_check(4, '0', "Count 4");
        wait_and_check(5, '1', "Count 5 (MAX)");

        -- Test 3: Wrap around
        REPORT "--- Test 3: Wrap Around ---";
        wait_and_check(0, '0', "Wrap to 0");

        -- Test 4: Continue counting
        REPORT "--- Test 4: Continue After Wrap ---";
        wait_and_check(1, '0', "Count 1 after wrap");
        wait_and_check(2, '0', "Count 2 after wrap");

        -- Test 5: Sync reset
        REPORT "--- Test 5: Sync Reset ---";
        i_reset <= '1';
        wait_and_check(0, '0', "Sync reset to 0");
        i_reset <= '0';

        -- Test 6: Resume counting
        REPORT "--- Test 6: Resume Counting ---";
        wait_and_check(1, '0', "Count 1 after reset");
        wait_and_check(2, '0', "Count 2 after reset");

        -- Test 7: Disable counting
        REPORT "--- Test 7: Disable Counting ---";
        i_enable <= '0';
        WAIT UNTIL rising_edge(GClock);
        WAIT UNTIL rising_edge(GClock);
        WAIT UNTIL rising_edge(GClock);
        WAIT FOR 1 ns;
        check_count(2, '0', "Count held when disabled");

        -- Test 8: Re-enable
        REPORT "--- Test 8: Re-enable ---";
        i_enable <= '1';
        wait_and_check(3, '0', "Count 3 after re-enable");

        -- Test 9: Multiple full cycles
        REPORT "--- Test 9: Multiple Cycles ---";
        i_reset <= '1';
        WAIT UNTIL rising_edge(GClock);
        i_reset <= '0';
        WAIT FOR 1 ns;
        check_count(0, '0', "Reset before cycles");
        
        -- Count through 2 full cycles
        FOR cycle IN 1 TO 2 LOOP
            wait_and_check(1, '0', "Cycle " & INTEGER'IMAGE(cycle) & " count 1");
            wait_and_check(2, '0', "Cycle " & INTEGER'IMAGE(cycle) & " count 2");
            wait_and_check(3, '0', "Cycle " & INTEGER'IMAGE(cycle) & " count 3");
            wait_and_check(4, '0', "Cycle " & INTEGER'IMAGE(cycle) & " count 4");
            wait_and_check(5, '1', "Cycle " & INTEGER'IMAGE(cycle) & " count 5 (MAX)");
            wait_and_check(0, '0', "Cycle " & INTEGER'IMAGE(cycle) & " wrap to 0");
        END LOOP;

        -- Final Summary
        WAIT FOR CLK_PERIOD * 2;
        REPORT "========================================";
        REPORT "Testbench Complete";
        REPORT "Passed: " & INTEGER'IMAGE(tests_passed);
        REPORT "Failed: " & INTEGER'IMAGE(tests_failed);
        REPORT "========================================";

        IF tests_failed = 0 THEN
            REPORT "*** ALL TESTS PASSED ***" SEVERITY NOTE;
        ELSE
            REPORT "*** SOME TESTS FAILED ***" SEVERITY ERROR;
        END IF;

        stop_clock <= TRUE;
        WAIT;
    END PROCESS;

END behavior;