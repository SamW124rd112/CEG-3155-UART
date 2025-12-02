LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_statusRegister IS
END tb_statusRegister;

ARCHITECTURE behavior OF tb_statusRegister IS

    COMPONENT statusRegister
        PORT(
            GClock               : IN  STD_LOGIC;
            GReset               : IN  STD_LOGIC;
            setTDRE, setRDRF     : IN  STD_LOGIC;
            setOE, setFE         : IN  STD_LOGIC;
            clrTDRE, clrRDRF     : IN  STD_LOGIC;
            clrOE, clrFE         : IN  STD_LOGIC;
            TDRE, RDRF           : OUT STD_LOGIC;
            OE, FE               : OUT STD_LOGIC;
            SCSR                 : OUT STD_LOGIC_VECTOR(7 downto 0)
        );
    END COMPONENT;

    -- Inputs
    SIGNAL GClock   : STD_LOGIC := '0';
    SIGNAL GReset   : STD_LOGIC := '0';
    SIGNAL setTDRE  : STD_LOGIC := '0';
    SIGNAL setRDRF  : STD_LOGIC := '0';
    SIGNAL setOE    : STD_LOGIC := '0';
    SIGNAL setFE    : STD_LOGIC := '0';
    SIGNAL clrTDRE  : STD_LOGIC := '0';
    SIGNAL clrRDRF  : STD_LOGIC := '0';
    SIGNAL clrOE    : STD_LOGIC := '0';
    SIGNAL clrFE    : STD_LOGIC := '0';

    -- Outputs
    SIGNAL TDRE     : STD_LOGIC;
    SIGNAL RDRF     : STD_LOGIC;
    SIGNAL OE       : STD_LOGIC;
    SIGNAL FE       : STD_LOGIC;
    SIGNAL SCSR     : STD_LOGIC_VECTOR(7 downto 0);

    -- Clock period
    CONSTANT clk_period : TIME := 20 ns;

    -- Test counters
    SIGNAL tests_passed : INTEGER := 0;
    SIGNAL tests_failed : INTEGER := 0;

BEGIN

    -- Instantiate UUT
    UUT: statusRegister
        PORT MAP(
            GClock   => GClock,
            GReset   => GReset,
            setTDRE  => setTDRE,
            setRDRF  => setRDRF,
            setOE    => setOE,
            setFE    => setFE,
            clrTDRE  => clrTDRE,
            clrRDRF  => clrRDRF,
            clrOE    => clrOE,
            clrFE    => clrFE,
            TDRE     => TDRE,
            RDRF     => RDRF,
            OE       => OE,
            FE       => FE,
            SCSR     => SCSR
        );

    -- Clock generation
    clk_process: PROCESS
    BEGIN
        GClock <= '0';
        WAIT FOR clk_period/2;
        GClock <= '1';
        WAIT FOR clk_period/2;
    END PROCESS;

    -- Stimulus process
    stim_proc: PROCESS

        -- Check all flags and SCSR register
        PROCEDURE check_flags(
            exp_TDRE, exp_RDRF, exp_OE, exp_FE : STD_LOGIC;
            test_name : STRING
        ) IS
            VARIABLE exp_SCSR : STD_LOGIC_VECTOR(7 downto 0);
            VARIABLE all_pass : BOOLEAN;
        BEGIN
            exp_SCSR := exp_TDRE & exp_RDRF & exp_OE & exp_FE & "0000";
            all_pass := (TDRE = exp_TDRE) AND (RDRF = exp_RDRF) AND 
                        (OE = exp_OE) AND (FE = exp_FE) AND (SCSR = exp_SCSR);
            
            IF all_pass THEN
                REPORT test_name & ": PASS - SCSR=" & 
                       STD_LOGIC'IMAGE(SCSR(7)) & STD_LOGIC'IMAGE(SCSR(6)) &
                       STD_LOGIC'IMAGE(SCSR(5)) & STD_LOGIC'IMAGE(SCSR(4)) &
                       STD_LOGIC'IMAGE(SCSR(3)) & STD_LOGIC'IMAGE(SCSR(2)) &
                       STD_LOGIC'IMAGE(SCSR(1)) & STD_LOGIC'IMAGE(SCSR(0));
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT test_name & ": FAIL" SEVERITY ERROR;
                REPORT "  Expected: TDRE=" & STD_LOGIC'IMAGE(exp_TDRE) &
                       " RDRF=" & STD_LOGIC'IMAGE(exp_RDRF) &
                       " OE=" & STD_LOGIC'IMAGE(exp_OE) &
                       " FE=" & STD_LOGIC'IMAGE(exp_FE) SEVERITY ERROR;
                REPORT "  Got:      TDRE=" & STD_LOGIC'IMAGE(TDRE) &
                       " RDRF=" & STD_LOGIC'IMAGE(RDRF) &
                       " OE=" & STD_LOGIC'IMAGE(OE) &
                       " FE=" & STD_LOGIC'IMAGE(FE) SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            END IF;
        END PROCEDURE;

        -- Wait for clock edge with settling time
        PROCEDURE wait_clock IS
        BEGIN
            WAIT UNTIL rising_edge(GClock);
            WAIT FOR 2 ns;  -- Allow signals to settle
        END PROCEDURE;

        -- Clear all control inputs
        PROCEDURE clear_inputs IS
        BEGIN
            setTDRE <= '0'; setRDRF <= '0'; setOE <= '0'; setFE <= '0';
            clrTDRE <= '0'; clrRDRF <= '0'; clrOE <= '0'; clrFE <= '0';
        END PROCEDURE;

    BEGIN
        REPORT "========================================";
        REPORT "Starting statusRegister Testbench";
        REPORT "========================================";
        REPORT "SCSR Register Format:";
        REPORT "  Bit 7: TDRE (Transmit Data Register Empty)";
        REPORT "  Bit 6: RDRF (Receive Data Register Full)";
        REPORT "  Bit 5: OE   (Overrun Error)";
        REPORT "  Bit 4: FE   (Framing Error)";
        REPORT "  Bits 3-0: Reserved (always 0000)";
        REPORT "========================================";

        -- Initialize all inputs
        clear_inputs;

        -- ==========================================
        -- Test 1: Asynchronous Reset
        -- ==========================================
        REPORT "--- Test 1: Asynchronous Reset ---";
        GReset <= '0';  -- Assert reset (active low)
        WAIT FOR clk_period * 2;
        GReset <= '1';  -- Release reset
        wait_clock;
        -- After reset: TDRE=1 (empty), others=0
        check_flags('1', '0', '0', '0', "Reset state");

        -- ==========================================
        -- Test 2: Set RDRF flag
        -- ==========================================
        REPORT "--- Test 2: Set RDRF ---";
        setRDRF <= '1';
        wait_clock;
        setRDRF <= '0';
        wait_clock;
        check_flags('1', '1', '0', '0', "Set RDRF");

        -- ==========================================
        -- Test 3: Set OE flag
        -- ==========================================
        REPORT "--- Test 3: Set OE ---";
        setOE <= '1';
        wait_clock;
        setOE <= '0';
        wait_clock;
        check_flags('1', '1', '1', '0', "Set OE");

        -- ==========================================
        -- Test 4: Set FE flag
        -- ==========================================
        REPORT "--- Test 4: Set FE ---";
        setFE <= '1';
        wait_clock;
        setFE <= '0';
        wait_clock;
        check_flags('1', '1', '1', '1', "Set FE");

        -- ==========================================
        -- Test 5: Clear TDRE flag
        -- ==========================================
        REPORT "--- Test 5: Clear TDRE ---";
        clrTDRE <= '1';
        wait_clock;
        clrTDRE <= '0';
        wait_clock;
        check_flags('0', '1', '1', '1', "Clear TDRE");

        -- ==========================================
        -- Test 6: Set TDRE flag
        -- ==========================================
        REPORT "--- Test 6: Set TDRE ---";
        setTDRE <= '1';
        wait_clock;
        setTDRE <= '0';
        wait_clock;
        check_flags('1', '1', '1', '1', "Set TDRE");

        -- ==========================================
        -- Test 7: Clear RDRF flag
        -- ==========================================
        REPORT "--- Test 7: Clear RDRF ---";
        clrRDRF <= '1';
        wait_clock;
        clrRDRF <= '0';
        wait_clock;
        check_flags('1', '0', '1', '1', "Clear RDRF");

        -- ==========================================
        -- Test 8: Clear OE flag
        -- ==========================================
        REPORT "--- Test 8: Clear OE ---";
        clrOE <= '1';
        wait_clock;
        clrOE <= '0';
        wait_clock;
        check_flags('1', '0', '0', '1', "Clear OE");

        -- ==========================================
        -- Test 9: Clear FE flag
        -- ==========================================
        REPORT "--- Test 9: Clear FE ---";
        clrFE <= '1';
        wait_clock;
        clrFE <= '0';
        wait_clock;
        check_flags('1', '0', '0', '0', "Clear FE");

        -- ==========================================
        -- Test 10: Set multiple flags simultaneously
        -- ==========================================
        REPORT "--- Test 10: Set multiple flags ---";
        setRDRF <= '1';
        setOE <= '1';
        setFE <= '1';
        wait_clock;
        clear_inputs;
        wait_clock;
        check_flags('1', '1', '1', '1', "Set RDRF+OE+FE");

        -- ==========================================
        -- Test 11: Clear multiple flags simultaneously
        -- ==========================================
        REPORT "--- Test 11: Clear multiple flags ---";
        clrRDRF <= '1';
        clrOE <= '1';
        clrFE <= '1';
        wait_clock;
        clear_inputs;
        wait_clock;
        check_flags('1', '0', '0', '0', "Clear RDRF+OE+FE");

        -- ==========================================
        -- Test 12: Flag hold behavior (persistence)
        -- ==========================================
        REPORT "--- Test 12: Flag hold behavior ---";
        setRDRF <= '1';
        wait_clock;
        setRDRF <= '0';
        wait_clock;
        -- Wait several cycles - flag should persist
        wait_clock;
        wait_clock;
        wait_clock;
        check_flags('1', '1', '0', '0', "RDRF persists");

        -- ==========================================
        -- Test 13: Set and Clear simultaneously (set wins for RDRF/OE/FE)
        -- ==========================================
        REPORT "--- Test 13: Set+Clear priority ---";
        -- Clear RDRF first
        clrRDRF <= '1';
        wait_clock;
        clrRDRF <= '0';
        wait_clock;
        check_flags('1', '0', '0', '0', "RDRF cleared");
        
        -- Now apply set and clear simultaneously
        setRDRF <= '1';
        clrRDRF <= '1';
        wait_clock;
        clear_inputs;
        wait_clock;
        -- Set should win: rdrf_next = setRDRF OR (rdrf AND NOT clr)
        check_flags('1', '1', '0', '0', "Set wins (RDRF)");

        -- ==========================================
        -- Test 14: TDRE set/clear priority (clear wins)
        -- ==========================================
        REPORT "--- Test 14: TDRE set+clear priority ---";
        setTDRE <= '1';
        clrTDRE <= '1';
        wait_clock;
        clear_inputs;
        wait_clock;
        -- Clear should win: tdre_n_next = clrTDRE OR (NOT setTDRE AND tdre_n)
        check_flags('0', '1', '0', '0', "Clear wins (TDRE)");

        -- Restore TDRE
        setTDRE <= '1';
        wait_clock;
        setTDRE <= '0';
        wait_clock;

        -- ==========================================
        -- Test 15: All flags set, then reset
        -- ==========================================
        REPORT "--- Test 15: Reset clears all flags ---";
        clrTDRE <= '1';
        setRDRF <= '1';
        setOE <= '1';
        setFE <= '1';
        wait_clock;
        clear_inputs;
        wait_clock;
        check_flags('0', '1', '1', '1', "All flags active");
        
        -- Apply reset
        GReset <= '0';
        WAIT FOR clk_period;
        GReset <= '1';
        wait_clock;
        check_flags('1', '0', '0', '0', "Reset clears all");

        -- ==========================================
        -- Test 16: Verify SCSR lower bits always 0
        -- ==========================================
        REPORT "--- Test 16: SCSR lower bits always 0 ---";
        setRDRF <= '1';
        setFE <= '1';
        wait_clock;
        clear_inputs;
        wait_clock;
        IF SCSR(3 downto 0) = "0000" THEN
            REPORT "SCSR[3:0] = 0000: PASS";
            tests_passed <= tests_passed + 1;
        ELSE
            REPORT "SCSR[3:0] should be 0000: FAIL" SEVERITY ERROR;
            tests_failed <= tests_failed + 1;
        END IF;

        -- ==========================================
        -- Test 17: Rapid toggle test
        -- ==========================================
        REPORT "--- Test 17: Rapid toggle test ---";
        GReset <= '0';
        WAIT FOR clk_period;
        GReset <= '1';
        wait_clock;
        
        FOR i IN 1 TO 5 LOOP
            setRDRF <= '1';
            wait_clock;
            setRDRF <= '0';
            clrRDRF <= '1';
            wait_clock;
            clrRDRF <= '0';
        END LOOP;
        check_flags('1', '0', '0', '0', "After rapid toggle");

        WAIT FOR clk_period * 2;

        -- ==========================================
        -- Final Summary
        -- ==========================================
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

        ASSERT FALSE REPORT "Simulation Complete" SEVERITY FAILURE;
        WAIT;
    END PROCESS;

END behavior;