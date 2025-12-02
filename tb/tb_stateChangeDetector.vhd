LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;  -- ADD THIS LINE

ENTITY tb_stateChangeDetector IS
END tb_stateChangeDetector;

ARCHITECTURE behavior OF tb_stateChangeDetector IS

    COMPONENT stateChangeDetector
        PORT(
            GClock       : IN  STD_LOGIC;
            GReset       : IN  STD_LOGIC;
            currentState : IN  STD_LOGIC_VECTOR(1 downto 0);
            stateChanged : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT CLK_PERIOD : TIME := 10 ns;

    SIGNAL GClock       : STD_LOGIC := '0';
    SIGNAL GReset       : STD_LOGIC := '0';
    SIGNAL currentState : STD_LOGIC_VECTOR(1 downto 0) := "00";
    SIGNAL stateChanged : STD_LOGIC;

    SIGNAL stop_clock   : BOOLEAN := FALSE;
    SIGNAL tests_passed : INTEGER := 0;
    SIGNAL tests_failed : INTEGER := 0;

BEGIN

    UUT: stateChangeDetector
        PORT MAP(
            GClock       => GClock,
            GReset       => GReset,
            currentState => currentState,
            stateChanged => stateChanged
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

        PROCEDURE check_changed(
            expected : STD_LOGIC;
            test_name : STRING
        ) IS
        BEGIN
            IF stateChanged = expected THEN
                REPORT test_name & ": PASS";
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT test_name & ": FAIL - Expected " & STD_LOGIC'IMAGE(expected) &
                       ", Got " & STD_LOGIC'IMAGE(stateChanged) SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            END IF;
        END PROCEDURE;
        
        PROCEDURE wait_edge IS
        BEGIN
            WAIT UNTIL rising_edge(GClock);
            WAIT FOR 1 ns;
        END PROCEDURE;

    BEGIN
        REPORT "========================================";
        REPORT "Starting stateChangeDetector Testbench";
        REPORT "========================================";

        -- Reset
        GReset <= '0';
        currentState <= "00";
        WAIT FOR CLK_PERIOD * 2;
        GReset <= '1';
        wait_edge;

        -- Test 1: No change - should be 0
        REPORT "--- Test 1: No State Change ---";
        wait_edge;
        check_changed('0', "Same state (00)");

        -- Test 2: Change from 00 to 01
        REPORT "--- Test 2: Change 00 -> 01 ---";
        currentState <= "01";
        WAIT FOR 1 ns;  -- Combinational output updates immediately
        check_changed('1', "State change detected");
        
        wait_edge;
        check_changed('0', "Change pulse ended");

        -- Test 3: Stay at 01
        REPORT "--- Test 3: Stay at 01 ---";
        wait_edge;
        wait_edge;
        check_changed('0', "No change at 01");

        -- Test 4: Change from 01 to 10
        REPORT "--- Test 4: Change 01 -> 10 ---";
        currentState <= "10";
        WAIT FOR 1 ns;
        check_changed('1', "State change 01->10");
        
        wait_edge;
        check_changed('0', "Change pulse ended");

        -- Test 5: Change from 10 to 11
        REPORT "--- Test 5: Change 10 -> 11 ---";
        currentState <= "11";
        WAIT FOR 1 ns;
        check_changed('1', "State change 10->11");
        
        wait_edge;
        check_changed('0', "Change pulse ended");

        -- Test 6: Change from 11 to 00
        REPORT "--- Test 6: Change 11 -> 00 ---";
        currentState <= "00";
        WAIT FOR 1 ns;
        check_changed('1', "State change 11->00");
        
        wait_edge;
        check_changed('0', "Change pulse ended");

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