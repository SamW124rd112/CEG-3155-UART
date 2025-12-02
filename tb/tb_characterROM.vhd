LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_characterROM IS
END tb_characterROM;

ARCHITECTURE behavior OF tb_characterROM IS

    COMPONENT characterROM
        PORT(
            TL_State  : IN  STD_LOGIC_VECTOR(1 downto 0);
            charIndex : IN  STD_LOGIC_VECTOR(2 downto 0);
            charOut   : OUT STD_LOGIC_VECTOR(7 downto 0)
        );
    END COMPONENT;

    SIGNAL TL_State  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    SIGNAL charIndex : STD_LOGIC_VECTOR(2 downto 0) := "000";
    SIGNAL charOut   : STD_LOGIC_VECTOR(7 downto 0);

    -- ASCII constants for verification
    CONSTANT CHAR_M  : STD_LOGIC_VECTOR(7 downto 0) := "01001101";  -- 'M'
    CONSTANT CHAR_g  : STD_LOGIC_VECTOR(7 downto 0) := "01100111";  -- 'g'
    CONSTANT CHAR_y  : STD_LOGIC_VECTOR(7 downto 0) := "01111001";  -- 'y'
    CONSTANT CHAR_r  : STD_LOGIC_VECTOR(7 downto 0) := "01110010";  -- 'r'
    CONSTANT CHAR_SP : STD_LOGIC_VECTOR(7 downto 0) := "00100000";  -- ' '
    CONSTANT CHAR_S  : STD_LOGIC_VECTOR(7 downto 0) := "01010011";  -- 'S'
    CONSTANT CHAR_CR : STD_LOGIC_VECTOR(7 downto 0) := "00001101";  -- CR

    SIGNAL tests_passed : INTEGER := 0;
    SIGNAL tests_failed : INTEGER := 0;

BEGIN

    UUT: characterROM
        PORT MAP(
            TL_State  => TL_State,
            charIndex => charIndex,
            charOut   => charOut
        );

    stim_proc: PROCESS

        FUNCTION char_to_string(c : STD_LOGIC_VECTOR(7 downto 0)) RETURN STRING IS
        BEGIN
            IF c = CHAR_M THEN RETURN "'M'";
            ELSIF c = CHAR_g THEN RETURN "'g'";
            ELSIF c = CHAR_y THEN RETURN "'y'";
            ELSIF c = CHAR_r THEN RETURN "'r'";
            ELSIF c = CHAR_SP THEN RETURN "' '";
            ELSIF c = CHAR_S THEN RETURN "'S'";
            ELSIF c = CHAR_CR THEN RETURN "'CR'";
            ELSE RETURN "0x" & INTEGER'IMAGE(to_integer(unsigned(c)));
            END IF;
        END FUNCTION;

        PROCEDURE check_char(
            expected : STD_LOGIC_VECTOR(7 downto 0);
            test_name : STRING
        ) IS
        BEGIN
            WAIT FOR 10 ns;  -- Propagation delay
            IF charOut = expected THEN
                REPORT test_name & ": PASS - Got " & char_to_string(charOut);
                tests_passed <= tests_passed + 1;
            ELSE
                REPORT test_name & ": FAIL - Expected " & char_to_string(expected) & 
                       ", Got " & char_to_string(charOut) SEVERITY ERROR;
                tests_failed <= tests_failed + 1;
            END IF;
            WAIT FOR 1 ns;
        END PROCEDURE;

        PROCEDURE test_message(
            state : STD_LOGIC_VECTOR(1 downto 0);
            msg_name : STRING;
            c0, c1, c2, c3, c4, c5 : STD_LOGIC_VECTOR(7 downto 0)
        ) IS
        BEGIN
            REPORT "--- Testing message: " & msg_name & " ---";
            TL_State <= state;
            
            charIndex <= "000";
            check_char(c0, msg_name & " char 0");
            
            charIndex <= "001";
            check_char(c1, msg_name & " char 1");
            
            charIndex <= "010";
            check_char(c2, msg_name & " char 2");
            
            charIndex <= "011";
            check_char(c3, msg_name & " char 3");
            
            charIndex <= "100";
            check_char(c4, msg_name & " char 4");
            
            charIndex <= "101";
            check_char(c5, msg_name & " char 5");
        END PROCEDURE;

    BEGIN
        REPORT "========================================";
        REPORT "Starting characterROM Testbench";
        REPORT "========================================";
        REPORT "Expected messages:";
        REPORT "  State 00: Mg Sr<CR>";
        REPORT "  State 01: My Sr<CR>";
        REPORT "  State 10: Mr Sg<CR>";
        REPORT "  State 11: Mr Sy<CR>";
        REPORT "========================================";

        WAIT FOR 10 ns;

        -- Test State 00: "Mg Sr\r"
        test_message("00", "Mg Sr", CHAR_M, CHAR_g, CHAR_SP, CHAR_S, CHAR_r, CHAR_CR);

        WAIT FOR 20 ns;

        -- Test State 01: "My Sr\r"
        test_message("01", "My Sr", CHAR_M, CHAR_y, CHAR_SP, CHAR_S, CHAR_r, CHAR_CR);

        WAIT FOR 20 ns;

        -- Test State 10: "Mr Sg\r"
        test_message("10", "Mr Sg", CHAR_M, CHAR_r, CHAR_SP, CHAR_S, CHAR_g, CHAR_CR);

        WAIT FOR 20 ns;

        -- Test State 11: "Mr Sy\r"
        test_message("11", "Mr Sy", CHAR_M, CHAR_r, CHAR_SP, CHAR_S, CHAR_y, CHAR_CR);

        WAIT FOR 20 ns;

        -- Final Summary
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