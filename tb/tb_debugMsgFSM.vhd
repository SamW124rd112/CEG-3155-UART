LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_debugMsgFSM IS
END tb_debugMsgFSM;

ARCHITECTURE behavior OF tb_debugMsgFSM IS

    COMPONENT debugMsgFSM
        PORT(
            GClock      : IN  STD_LOGIC;
            GReset      : IN  STD_LOGIC;
            TL_State    : IN  STD_LOGIC_VECTOR(1 downto 0);
            TDRE        : IN  STD_LOGIC;
            UART_Select : OUT STD_LOGIC;
            ADDR        : OUT STD_LOGIC_VECTOR(1 downto 0);
            RW          : OUT STD_LOGIC;
            DataOut     : OUT STD_LOGIC_VECTOR(7 downto 0);
            stateDebug  : OUT STD_LOGIC_VECTOR(2 downto 0)
        );
    END COMPONENT;

    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT TIMEOUT    : TIME := 1 ms;

    SIGNAL GClock      : STD_LOGIC := '0';
    SIGNAL GReset      : STD_LOGIC := '0';
    SIGNAL TL_State    : STD_LOGIC_VECTOR(1 downto 0) := "00";
    SIGNAL TDRE        : STD_LOGIC := '1';
    SIGNAL UART_Select : STD_LOGIC;
    SIGNAL ADDR        : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL RW          : STD_LOGIC;
    SIGNAL DataOut     : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL stateDebug  : STD_LOGIC_VECTOR(2 downto 0);

    SIGNAL stop_clock  : BOOLEAN := FALSE;
    SIGNAL tests_passed : INTEGER := 0;
    SIGNAL tests_failed : INTEGER := 0;

    -- State constants
    CONSTANT sIDLE      : STD_LOGIC_VECTOR(2 downto 0) := "000";
    CONSTANT sWAIT_TDRE : STD_LOGIC_VECTOR(2 downto 0) := "001";
    CONSTANT sWRITE_TDR : STD_LOGIC_VECTOR(2 downto 0) := "010";
    CONSTANT sNEXT_CHAR : STD_LOGIC_VECTOR(2 downto 0) := "011";
    CONSTANT sDONE      : STD_LOGIC_VECTOR(2 downto 0) := "100";

    -- ASCII constants (for verification)
    CONSTANT CHAR_M  : INTEGER := 77;   -- 0x4D
    CONSTANT CHAR_g  : INTEGER := 103;  -- 0x67
    CONSTANT CHAR_y  : INTEGER := 121;  -- 0x79
    CONSTANT CHAR_r  : INTEGER := 114;  -- 0x72
    CONSTANT CHAR_SP : INTEGER := 32;   -- 0x20
    CONSTANT CHAR_S  : INTEGER := 83;   -- 0x53
    CONSTANT CHAR_CR : INTEGER := 13;   -- 0x0D

BEGIN

    UUT: debugMsgFSM
        PORT MAP(
            GClock      => GClock,
            GReset      => GReset,
            TL_State    => TL_State,
            TDRE        => TDRE,
            UART_Select => UART_Select,
            ADDR        => ADDR,
            RW          => RW,
            DataOut     => DataOut,
            stateDebug  => stateDebug
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
        VARIABLE start_time : TIME;
        VARIABLE char_count : INTEGER;
        VARIABLE timeout_occurred : BOOLEAN;
        VARIABLE captured_char : INTEGER;
        
        TYPE int_array IS ARRAY (0 TO 5) OF INTEGER;
        VARIABLE captured_msg : int_array;
        VARIABLE expected_msg : int_array;
        VARIABLE msg_match : BOOLEAN;
        
        FUNCTION state_name(s : STD_LOGIC_VECTOR(2 downto 0)) RETURN STRING IS
        BEGIN
            CASE s IS
                WHEN "000" => RETURN "IDLE";
                WHEN "001" => RETURN "WAIT_TDRE";
                WHEN "010" => RETURN "WRITE_TDR";
                WHEN "011" => RETURN "NEXT_CHAR";
                WHEN "100" => RETURN "DONE";
                WHEN OTHERS => RETURN "???";
            END CASE;
        END FUNCTION;
        
        FUNCTION char_name(c : INTEGER) RETURN STRING IS
        BEGIN
            CASE c IS
                WHEN 77  => RETURN "'M'";
                WHEN 103 => RETURN "'g'";
                WHEN 121 => RETURN "'y'";
                WHEN 114 => RETURN "'r'";
                WHEN 32  => RETURN "' '";
                WHEN 83  => RETURN "'S'";
                WHEN 13  => RETURN "<CR>";
                WHEN OTHERS => RETURN INTEGER'IMAGE(c);
            END CASE;
        END FUNCTION;
        
        PROCEDURE wait_edge IS
        BEGIN
            WAIT UNTIL rising_edge(GClock);
            WAIT FOR 1 ns;
        END PROCEDURE;
        
        PROCEDURE wait_for_idle IS
        BEGIN
            start_time := NOW;
            WHILE stateDebug /= sIDLE LOOP
                TDRE <= '1';
                wait_edge;
                IF (NOW - start_time) > TIMEOUT THEN
                    REPORT "TIMEOUT waiting for IDLE" SEVERITY ERROR;
                    EXIT;
                END IF;
            END LOOP;
        END PROCEDURE;

        PROCEDURE send_message_and_verify(
            new_state : STD_LOGIC_VECTOR(1 downto 0);
            exp_msg : int_array;
            test_name : STRING
        ) IS
        BEGIN
            REPORT "--- " & test_name & " ---";
            
            -- Make sure we're in IDLE first
            wait_for_idle;
            WAIT FOR CLK_PERIOD * 5;
            
            start_time := NOW;
            char_count := 0;
            timeout_occurred := FALSE;
            msg_match := TRUE;
            
            -- Trigger state change
            TL_State <= new_state;
            TDRE <= '1';
            
            -- Wait for FSM to leave IDLE
            WHILE stateDebug = sIDLE LOOP
                wait_edge;
                IF (NOW - start_time) > TIMEOUT THEN
                    REPORT "TIMEOUT waiting for FSM to leave IDLE" SEVERITY ERROR;
                    timeout_occurred := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            
            IF NOT timeout_occurred THEN
                REPORT "FSM started, now in " & state_name(stateDebug);
                
                -- Capture 6 characters
                WHILE stateDebug /= sIDLE AND char_count < 6 LOOP
                    -- When in WRITE_TDR state, a character is being written
                    IF stateDebug = sWRITE_TDR THEN
                        captured_char := to_integer(unsigned(DataOut));
                        captured_msg(char_count) := captured_char;
                        REPORT "  Char " & INTEGER'IMAGE(char_count) & ": " & 
                               char_name(captured_char);
                        char_count := char_count + 1;
                    END IF;
                    
                    TDRE <= '1';
                    wait_edge;
                    
                    IF (NOW - start_time) > TIMEOUT THEN
                        REPORT "TIMEOUT during message" SEVERITY ERROR;
                        timeout_occurred := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
            
            -- Verify results
            IF timeout_occurred THEN
                REPORT test_name & ": FAIL - Timeout" SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            ELSIF char_count /= 6 THEN
                REPORT test_name & ": FAIL - Expected 6 chars, got " & 
                       INTEGER'IMAGE(char_count) SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            ELSE
                -- Verify message content
                FOR i IN 0 TO 5 LOOP
                    IF captured_msg(i) /= exp_msg(i) THEN
                        REPORT "  Char " & INTEGER'IMAGE(i) & " mismatch: expected " &
                               char_name(exp_msg(i)) & ", got " & 
                               char_name(captured_msg(i)) SEVERITY ERROR;
                        msg_match := FALSE;
                    END IF;
                END LOOP;
                
                IF msg_match THEN
                    REPORT test_name & ": PASS - Message correct";
                    tests_passed <= tests_passed + 1;
                ELSE
                    REPORT test_name & ": FAIL - Message mismatch" SEVERITY ERROR;
                    tests_failed <= tests_failed + 1;
                END IF;
            END IF;
            
            -- Wait for FSM to return to IDLE
            wait_for_idle;
            WAIT FOR CLK_PERIOD * 10;
        END PROCEDURE;

        -- Expected messages
        -- State 00: "Mg Sr<CR>" = M, g, space, S, r, CR
        -- State 01: "My Sr<CR>" = M, y, space, S, r, CR
        -- State 10: "Mr Sg<CR>" = M, r, space, S, g, CR
        -- State 11: "Mr Sy<CR>" = M, r, space, S, y, CR
        CONSTANT MSG_00 : int_array := (CHAR_M, CHAR_g, CHAR_SP, CHAR_S, CHAR_r, CHAR_CR);
        CONSTANT MSG_01 : int_array := (CHAR_M, CHAR_y, CHAR_SP, CHAR_S, CHAR_r, CHAR_CR);
        CONSTANT MSG_10 : int_array := (CHAR_M, CHAR_r, CHAR_SP, CHAR_S, CHAR_g, CHAR_CR);
        CONSTANT MSG_11 : int_array := (CHAR_M, CHAR_r, CHAR_SP, CHAR_S, CHAR_y, CHAR_CR);

    BEGIN
        REPORT "========================================";
        REPORT "Starting debugMsgFSM Integration Test";
        REPORT "========================================";

        -- IMPORTANT: Initialize TL_State to "00" BEFORE reset
        -- This prevents stateChangeDetector from triggering immediately
        TL_State <= "00";
        TDRE <= '1';
        GReset <= '0';
        WAIT FOR CLK_PERIOD * 5;
        
        -- Release reset while TL_State is still "00"
        GReset <= '1';
        WAIT FOR CLK_PERIOD * 10;
        
        -- Now verify we're in IDLE
        IF stateDebug = sIDLE THEN
            REPORT "Initial state: IDLE - OK";
            tests_passed <= tests_passed + 1;
        ELSE
            REPORT "Initial state: " & state_name(stateDebug) & " - waiting for IDLE";
            -- Wait for any in-progress message to complete
            wait_for_idle;
            WAIT FOR CLK_PERIOD * 5;
            
            IF stateDebug = sIDLE THEN
                REPORT "Now in IDLE - OK";
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT "Still not in IDLE - FAIL" SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            END IF;
        END IF;

        -- Test 1: State 00 -> "Mg Sr<CR>"
        -- Need to change FROM current state TO trigger detection
        TL_State <= "11";  -- Set to different state first
        WAIT FOR CLK_PERIOD * 5;
        wait_for_idle;
        WAIT FOR CLK_PERIOD * 5;
        
        send_message_and_verify("00", MSG_00, "Test 1: State 00 (Mg Sr)");

        -- Test 2: State 01 -> "My Sr<CR>"
        send_message_and_verify("01", MSG_01, "Test 2: State 01 (My Sr)");

        -- Test 3: State 10 -> "Mr Sg<CR>"
        send_message_and_verify("10", MSG_10, "Test 3: State 10 (Mr Sg)");

        -- Test 4: State 11 -> "Mr Sy<CR>"
        send_message_and_verify("11", MSG_11, "Test 4: State 11 (Mr Sy)");

        -- Test 5: Back to 00 to verify cycle works
        send_message_and_verify("00", MSG_00, "Test 5: State 00 again");

        -- Final Summary
        WAIT FOR CLK_PERIOD * 10;
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