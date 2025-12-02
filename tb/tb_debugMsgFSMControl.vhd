LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_debugMsgFSMControl IS
END tb_debugMsgFSMControl;

ARCHITECTURE behavior OF tb_debugMsgFSMControl IS

    COMPONENT debugMsgFSMControl
        PORT(
            GClock       : IN  STD_LOGIC;
            GReset       : IN  STD_LOGIC;
            stateChanged : IN  STD_LOGIC;
            TDRE         : IN  STD_LOGIC;
            msgDone      : IN  STD_LOGIC;
            counterReset : OUT STD_LOGIC;
            counterEn    : OUT STD_LOGIC;
            uartSelect   : OUT STD_LOGIC;
            uartRW       : OUT STD_LOGIC;
            addrBit0     : OUT STD_LOGIC;
            stateOut     : OUT STD_LOGIC_VECTOR(2 downto 0)
        );
    END COMPONENT;

    CONSTANT CLK_PERIOD : TIME := 10 ns;

    SIGNAL GClock       : STD_LOGIC := '0';
    SIGNAL GReset       : STD_LOGIC := '0';
    SIGNAL stateChanged : STD_LOGIC := '0';
    SIGNAL TDRE         : STD_LOGIC := '0';
    SIGNAL msgDone      : STD_LOGIC := '0';
    SIGNAL counterReset : STD_LOGIC;
    SIGNAL counterEn    : STD_LOGIC;
    SIGNAL uartSelect   : STD_LOGIC;
    SIGNAL uartRW       : STD_LOGIC;
    SIGNAL addrBit0     : STD_LOGIC;
    SIGNAL stateOut     : STD_LOGIC_VECTOR(2 downto 0);

    SIGNAL stop_clock   : BOOLEAN := FALSE;
    SIGNAL tests_passed : INTEGER := 0;
    SIGNAL tests_failed : INTEGER := 0;

    -- State constants (NEW ENCODING)
    CONSTANT sIDLE      : STD_LOGIC_VECTOR(2 downto 0) := "000";
    CONSTANT sWAIT_TDRE : STD_LOGIC_VECTOR(2 downto 0) := "001";
    CONSTANT sWRITE_TDR : STD_LOGIC_VECTOR(2 downto 0) := "010";
    CONSTANT sNEXT_CHAR : STD_LOGIC_VECTOR(2 downto 0) := "011";
    CONSTANT sDONE      : STD_LOGIC_VECTOR(2 downto 0) := "100";

    FUNCTION state_name(s : STD_LOGIC_VECTOR(2 downto 0)) RETURN STRING IS
    BEGIN
        CASE s IS
            WHEN "000" => RETURN "IDLE";
            WHEN "001" => RETURN "WAIT_TDRE";
            WHEN "010" => RETURN "WRITE_TDR";
            WHEN "011" => RETURN "NEXT_CHAR";
            WHEN "100" => RETURN "DONE";
            WHEN OTHERS => RETURN "UNKNOWN";
        END CASE;
    END FUNCTION;

BEGIN

    UUT: debugMsgFSMControl
        PORT MAP(
            GClock       => GClock,
            GReset       => GReset,
            stateChanged => stateChanged,
            TDRE         => TDRE,
            msgDone      => msgDone,
            counterReset => counterReset,
            counterEn    => counterEn,
            uartSelect   => uartSelect,
            uartRW       => uartRW,
            addrBit0     => addrBit0,
            stateOut     => stateOut
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

        PROCEDURE check_state(
            expected : STD_LOGIC_VECTOR(2 downto 0);
            test_name : STRING
        ) IS
        BEGIN
            IF stateOut = expected THEN
                REPORT test_name & ": PASS - State = " & state_name(stateOut);
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT test_name & ": FAIL - Expected " & state_name(expected) &
                       ", Got " & state_name(stateOut) SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            END IF;
        END PROCEDURE;

        PROCEDURE check_outputs(
            exp_cntRst, exp_cntEn, exp_uartSel, exp_rw, exp_addr0 : STD_LOGIC;
            test_name : STRING
        ) IS
            VARIABLE all_match : BOOLEAN;
        BEGIN
            all_match := (counterReset = exp_cntRst) AND (counterEn = exp_cntEn) AND
                         (uartSelect = exp_uartSel) AND (uartRW = exp_rw) AND
                         (addrBit0 = exp_addr0);
            
            IF all_match THEN
                REPORT test_name & " outputs: PASS";
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT test_name & " outputs: FAIL" SEVERITY ERROR;
                REPORT "  counterReset: exp=" & STD_LOGIC'IMAGE(exp_cntRst) & 
                       " got=" & STD_LOGIC'IMAGE(counterReset);
                REPORT "  counterEn: exp=" & STD_LOGIC'IMAGE(exp_cntEn) & 
                       " got=" & STD_LOGIC'IMAGE(counterEn);
                REPORT "  uartSelect: exp=" & STD_LOGIC'IMAGE(exp_uartSel) & 
                       " got=" & STD_LOGIC'IMAGE(uartSelect);
                REPORT "  uartRW: exp=" & STD_LOGIC'IMAGE(exp_rw) & 
                       " got=" & STD_LOGIC'IMAGE(uartRW);
                REPORT "  addrBit0: exp=" & STD_LOGIC'IMAGE(exp_addr0) & 
                       " got=" & STD_LOGIC'IMAGE(addrBit0);
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
        REPORT "Starting debugMsgFSMControl Testbench";
        REPORT "State Encoding:";
        REPORT "  IDLE=000, WAIT_TDRE=001, WRITE_TDR=010";
        REPORT "  NEXT_CHAR=011, DONE=100";
        REPORT "========================================";

        -- Reset
        REPORT "--- Test 1: Reset ---";
        GReset <= '0';
        stateChanged <= '0';
        TDRE <= '0';
        msgDone <= '0';
        WAIT FOR CLK_PERIOD * 2;
        GReset <= '1';
        wait_edge;
        check_state(sIDLE, "Reset to IDLE");
        check_outputs('1', '0', '0', '0', '0', "IDLE");

        -- Test 2: Stay in IDLE when no state change
        REPORT "--- Test 2: Stay in IDLE ---";
        stateChanged <= '0';
        wait_edge;
        wait_edge;
        check_state(sIDLE, "Stay in IDLE");

        -- Test 3: IDLE -> WAIT_TDRE on state change
        REPORT "--- Test 3: IDLE -> WAIT_TDRE ---";
        stateChanged <= '1';
        wait_edge;
        stateChanged <= '0';
        check_state(sWAIT_TDRE, "Transition to WAIT_TDRE");
        check_outputs('0', '0', '1', '1', '1', "WAIT_TDRE");

        -- Test 4: Stay in WAIT_TDRE when TDRE=0
        REPORT "--- Test 4: Stay in WAIT_TDRE ---";
        TDRE <= '0';
        wait_edge;
        wait_edge;
        check_state(sWAIT_TDRE, "Stay in WAIT_TDRE");

        -- Test 5: WAIT_TDRE -> WRITE_TDR when TDRE=1
        REPORT "--- Test 5: WAIT_TDRE -> WRITE_TDR ---";
        TDRE <= '1';
        wait_edge;
        check_state(sWRITE_TDR, "Transition to WRITE_TDR");
        check_outputs('0', '0', '1', '0', '0', "WRITE_TDR");
        TDRE <= '0';  -- Clear TDRE for next test

        -- Test 6: WRITE_TDR -> NEXT_CHAR
        REPORT "--- Test 6: WRITE_TDR -> NEXT_CHAR ---";
        wait_edge;
        check_state(sNEXT_CHAR, "Transition to NEXT_CHAR");
        check_outputs('0', '1', '0', '0', '0', "NEXT_CHAR");

        -- Test 7: NEXT_CHAR -> WAIT_TDRE when msgDone=0
        REPORT "--- Test 7: NEXT_CHAR -> WAIT_TDRE ---";
        msgDone <= '0';
        wait_edge;
        check_state(sWAIT_TDRE, "Back to WAIT_TDRE");

        -- Test 8: Full message cycle (6 characters)
        REPORT "--- Test 8: Send 6 Characters ---";
        FOR i IN 1 TO 5 LOOP
            -- WAIT_TDRE: Simulate TDRE going high
            TDRE <= '1';
            wait_edge;
            check_state(sWRITE_TDR, "Char " & INTEGER'IMAGE(i) & " WRITE_TDR");
            TDRE <= '0';
            
            -- WRITE_TDR -> NEXT_CHAR
            wait_edge;
            check_state(sNEXT_CHAR, "Char " & INTEGER'IMAGE(i) & " NEXT_CHAR");
            
            -- NEXT_CHAR -> WAIT_TDRE (msgDone still 0)
            wait_edge;
            check_state(sWAIT_TDRE, "Char " & INTEGER'IMAGE(i) & " back to WAIT");
        END LOOP;
        
        -- 6th character
        TDRE <= '1';
        wait_edge;
        check_state(sWRITE_TDR, "Char 6 WRITE_TDR");
        TDRE <= '0';
        
        wait_edge;
        check_state(sNEXT_CHAR, "Char 6 NEXT_CHAR");
        
        -- Now msgDone goes high
        msgDone <= '1';
        wait_edge;
        check_state(sDONE, "Message complete - DONE");

        -- Test 9: DONE -> IDLE
        REPORT "--- Test 9: DONE -> IDLE ---";
        wait_edge;
        check_state(sIDLE, "Return to IDLE");
        msgDone <= '0';

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