LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_receiverFSMControl IS
END tb_receiverFSMControl;

ARCHITECTURE behavior OF tb_receiverFSMControl IS

    -- Function to convert std_logic_vector to string
    FUNCTION slv_to_string(slv : STD_LOGIC_VECTOR) RETURN STRING IS
        VARIABLE result : STRING(1 TO slv'LENGTH);
        VARIABLE idx    : INTEGER := 1;
    BEGIN
        FOR i IN slv'RANGE LOOP
            CASE slv(i) IS
                WHEN '0'    => result(idx) := '0';
                WHEN '1'    => result(idx) := '1';
                WHEN 'X'    => result(idx) := 'X';
                WHEN 'U'    => result(idx) := 'U';
                WHEN 'Z'    => result(idx) := 'Z';
                WHEN 'H'    => result(idx) := 'H';
                WHEN 'L'    => result(idx) := 'L';
                WHEN '-'    => result(idx) := '-';
                WHEN OTHERS => result(idx) := '?';
            END CASE;
            idx := idx + 1;
        END LOOP;
        RETURN result;
    END FUNCTION;

    -- Function to convert std_logic to character
    FUNCTION sl_to_char(sl : STD_LOGIC) RETURN CHARACTER IS
    BEGIN
        CASE sl IS
            WHEN '0'    => RETURN '0';
            WHEN '1'    => RETURN '1';
            WHEN 'X'    => RETURN 'X';
            WHEN 'U'    => RETURN 'U';
            WHEN 'Z'    => RETURN 'Z';
            WHEN 'H'    => RETURN 'H';
            WHEN 'L'    => RETURN 'L';
            WHEN '-'    => RETURN '-';
            WHEN OTHERS => RETURN '?';
        END CASE;
    END FUNCTION;

    -- Component Declaration
    COMPONENT receiverFSMControl
        PORT(
            RDRF, RXD, fourB8, eightB8, bitC8   : IN  STD_LOGIC;
            G_Clock                             : IN  STD_LOGIC;
            G_Reset                             : IN  STD_LOGIC;
            resetCount, resetBitCount           : OUT STD_LOGIC;
            shiftEN, loadEN                     : OUT STD_LOGIC;
            setRDRF, setOE, setFE               : OUT STD_LOGIC;
            stateOut                            : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    -- Input Signals
    SIGNAL RDRF     : STD_LOGIC := '0';
    SIGNAL RXD      : STD_LOGIC := '1';
    SIGNAL fourB8   : STD_LOGIC := '0';
    SIGNAL eightB8  : STD_LOGIC := '0';
    SIGNAL bitC8    : STD_LOGIC := '0';
    SIGNAL G_Clock  : STD_LOGIC := '0';
    SIGNAL G_Reset  : STD_LOGIC := '0';

    -- Output Signals
    SIGNAL resetCount    : STD_LOGIC;
    SIGNAL resetBitCount : STD_LOGIC;
    SIGNAL shiftEN       : STD_LOGIC;
    SIGNAL loadEN        : STD_LOGIC;
    SIGNAL setRDRF       : STD_LOGIC;
    SIGNAL setOE         : STD_LOGIC;
    SIGNAL setFE         : STD_LOGIC;
    SIGNAL stateOut      : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Clock period
    CONSTANT CLK_PERIOD : TIME := 20 ns;

    -- State constants
    CONSTANT STATE_A : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
    CONSTANT STATE_B : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
    CONSTANT STATE_C : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
    CONSTANT STATE_D : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
    CONSTANT STATE_E : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";

BEGIN

    -- Instantiate Unit Under Test
    UUT: receiverFSMControl
        PORT MAP(
            RDRF          => RDRF,
            RXD           => RXD,
            fourB8        => fourB8,
            eightB8       => eightB8,
            bitC8         => bitC8,
            G_Clock       => G_Clock,
            G_Reset       => G_Reset,
            resetCount    => resetCount,
            resetBitCount => resetBitCount,
            shiftEN       => shiftEN,
            loadEN        => loadEN,
            setRDRF       => setRDRF,
            setOE         => setOE,
            setFE         => setFE,
            stateOut      => stateOut
        );

    -- Clock Generation
    clk_process: PROCESS
    BEGIN
        G_Clock <= '0';
        WAIT FOR CLK_PERIOD/2;
        G_Clock <= '1';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    -- Stimulus Process
    stim_proc: PROCESS

        -- Test counter variables
        VARIABLE v_passed : INTEGER := 0;
        VARIABLE v_failed : INTEGER := 0;

        -- Procedure to check state
        PROCEDURE check_state(
            expected  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            test_name : IN STRING
        ) IS
        BEGIN
            IF stateOut = expected THEN
                REPORT test_name & ": PASS - State = " & slv_to_string(stateOut)
                    SEVERITY NOTE;
                v_passed := v_passed + 1;
            ELSE
                REPORT test_name & ": FAIL - Expected " & slv_to_string(expected) & 
                       " Got " & slv_to_string(stateOut)
                    SEVERITY ERROR;
                v_failed := v_failed + 1;
            END IF;
        END PROCEDURE;

        -- Procedure to check single signal
        PROCEDURE check_signal(
            actual    : IN STD_LOGIC;
            expected  : IN STD_LOGIC;
            test_name : IN STRING
        ) IS
            VARIABLE actual_char   : CHARACTER;
            VARIABLE expected_char : CHARACTER;
        BEGIN
            actual_char   := sl_to_char(actual);
            expected_char := sl_to_char(expected);
            
            IF actual = expected THEN
                REPORT test_name & ": PASS"
                    SEVERITY NOTE;
                v_passed := v_passed + 1;
            ELSE
                REPORT test_name & ": FAIL - Expected '" & expected_char & 
                       "' Got '" & actual_char & "'"
                    SEVERITY ERROR;
                v_failed := v_failed + 1;
            END IF;
        END PROCEDURE;

        -- Procedure to print final results
        PROCEDURE print_results IS
        BEGIN
            REPORT "==========================================";
            REPORT "TEST RESULTS:";
            REPORT "  PASSED: " & INTEGER'IMAGE(v_passed);
            REPORT "  FAILED: " & INTEGER'IMAGE(v_failed);
            
            IF v_failed = 0 THEN
                REPORT "ALL TESTS PASSED!" SEVERITY NOTE;
            ELSE
                REPORT "SOME TESTS FAILED!" SEVERITY ERROR;
            END IF;
            REPORT "==========================================";
        END PROCEDURE;

    BEGIN
        REPORT "========== TESTBENCH START ==========";
        
        -- ========== TEST 1: Reset ==========
        REPORT "TEST 1: Reset";
        G_Reset <= '0';
        WAIT FOR CLK_PERIOD * 2;
        G_Reset <= '1';
        WAIT FOR CLK_PERIOD;
        WAIT FOR 1 ns;
        
        check_state(STATE_A, "Reset to State A");

        -- ========== TEST 2: State A -> B (Start bit) ==========
        REPORT "TEST 2: State A -> B (Start bit detected)";
        RXD <= '0';
        WAIT FOR CLK_PERIOD;
        WAIT FOR 1 ns;
        
        check_state(STATE_B, "Transition A->B");
        check_signal(resetBitCount, '1', "resetBitCount in B");

        -- ========== TEST 3: State B -> C (fourB8) ==========
        REPORT "TEST 3: State B -> C (fourB8 asserted)";
        fourB8 <= '1';
        WAIT FOR CLK_PERIOD;
        WAIT FOR 1 ns;
        fourB8 <= '0';
        
        check_state(STATE_C, "Transition B->C");

        -- ========== TEST 4: State C shiftEN ==========
        REPORT "TEST 4: State C - Shift Enable";
        eightB8 <= '1';
        bitC8 <= '0';
        WAIT FOR 1 ns;
        
        check_signal(shiftEN, '1', "shiftEN active in C");
        
        WAIT FOR CLK_PERIOD;
        eightB8 <= '0';
        WAIT FOR CLK_PERIOD;

        -- ========== TEST 5: State C -> D (last bit) ==========
        REPORT "TEST 5: State C -> D (last bit)";
        eightB8 <= '1';
        bitC8 <= '1';
        WAIT FOR CLK_PERIOD;
        WAIT FOR 1 ns;
        eightB8 <= '0';
        bitC8 <= '0';
        
        check_state(STATE_D, "Transition C->D");

        -- ========== TEST 6: State D -> E (valid stop bit) ==========
        REPORT "TEST 6: State D -> E (valid stop bit)";
        RXD <= '1';
        eightB8 <= '1';
        WAIT FOR CLK_PERIOD;
        WAIT FOR 1 ns;
        eightB8 <= '0';
        
        check_state(STATE_E, "Transition D->E");
        check_signal(loadEN, '1', "loadEN in E");
        check_signal(setRDRF, '1', "setRDRF in E (RDRF=0)");
        check_signal(setOE, '0', "setOE in E (RDRF=0)");

        -- ========== TEST 7: State E -> A ==========
        REPORT "TEST 7: State E -> A (return to idle)";
        WAIT FOR CLK_PERIOD;
        WAIT FOR 1 ns;
        
        check_state(STATE_A, "Transition E->A");

        -- ========== TEST 8: Framing Error ==========
        REPORT "TEST 8: Framing Error Test";
        
        -- Go through A->B->C->D
        RXD <= '0';
        WAIT FOR CLK_PERIOD;
        fourB8 <= '1';
        WAIT FOR CLK_PERIOD;
        fourB8 <= '0';
        eightB8 <= '1';
        bitC8 <= '1';
        WAIT FOR CLK_PERIOD;
        eightB8 <= '0';
        bitC8 <= '0';
        
        -- In state D with invalid stop bit
        RXD <= '0';
        eightB8 <= '1';
        WAIT FOR 1 ns;
        
        check_state(STATE_D, "In State D for FE test");
        check_signal(setFE, '1', "setFE on invalid stop bit");
        
        WAIT FOR CLK_PERIOD;
        eightB8 <= '0';
        RXD <= '1';
        WAIT FOR CLK_PERIOD * 2;

        -- ========== TEST 9: Overrun Error ==========
        REPORT "TEST 9: Overrun Error Test";
        
        -- Reset to known state
        G_Reset <= '0';
        WAIT FOR CLK_PERIOD;
        G_Reset <= '1';
        WAIT FOR CLK_PERIOD;
        
        RDRF <= '1';  -- Previous data not read
        
        -- Complete cycle to state E
        RXD <= '0';
        WAIT FOR CLK_PERIOD;
        fourB8 <= '1';
        WAIT FOR CLK_PERIOD;
        fourB8 <= '0';
        eightB8 <= '1';
        bitC8 <= '1';
        WAIT FOR CLK_PERIOD;
        eightB8 <= '0';
        bitC8 <= '0';
        RXD <= '1';
        eightB8 <= '1';
        WAIT FOR CLK_PERIOD;
        eightB8 <= '0';
        WAIT FOR 1 ns;
        
        check_state(STATE_E, "Reached State E for OE test");
        check_signal(setOE, '1', "setOE when RDRF=1");
        check_signal(setRDRF, '0', "setRDRF=0 when RDRF=1");

        -- ========== TEST 10: Stay in State A when idle ==========
        REPORT "TEST 10: Stay in State A when idle";
        G_Reset <= '0';
        WAIT FOR CLK_PERIOD;
        G_Reset <= '1';
        WAIT FOR CLK_PERIOD;
        
        RXD <= '1';
        RDRF <= '0';
        WAIT FOR CLK_PERIOD * 3;
        WAIT FOR 1 ns;
        
        check_state(STATE_A, "Stay in A when idle");

        -- ========== FINAL RESULTS ==========
        WAIT FOR CLK_PERIOD * 2;
        print_results;
        
        ASSERT FALSE REPORT "Simulation complete" SEVERITY FAILURE;
        WAIT;
    END PROCESS;

END behavior;
