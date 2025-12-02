LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_debugTrafficLightSystem IS
END tb_debugTrafficLightSystem;

ARCHITECTURE behavior OF tb_debugTrafficLightSystem IS

    -- We'll test just the debugMsgFSM + UART combination
    -- Skip the full traffic light controller for now
    
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

    SIGNAL GClock      : STD_LOGIC := '0';
    SIGNAL GReset      : STD_LOGIC := '0';
    SIGNAL TL_State    : STD_LOGIC_VECTOR(1 downto 0) := "00";
    SIGNAL TDRE        : STD_LOGIC := '1';
    SIGNAL UART_Select : STD_LOGIC;
    SIGNAL ADDR        : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL RW          : STD_LOGIC;
    SIGNAL DataOut     : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL stateDebug  : STD_LOGIC_VECTOR(2 downto 0);

    SIGNAL stop_clock : BOOLEAN := FALSE;
    SIGNAL char_count : INTEGER := 0;

    -- For message capture
    TYPE message_buffer IS ARRAY (0 TO 20) OF STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL captured_chars : message_buffer;

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

    -- Capture characters when write cycle detected
    capture_proc: PROCESS(GClock)
    BEGIN
        IF rising_edge(GClock) THEN
            IF GReset = '0' THEN
                char_count <= 0;
            ELSIF UART_Select = '1' AND RW = '0' AND ADDR = "00" THEN
                -- Write to TDR detected
                IF char_count < 20 THEN
                    captured_chars(char_count) <= DataOut;
                    char_count <= char_count + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    stim_proc: PROCESS
    BEGIN
        REPORT "========================================";
        REPORT "Debug Traffic Light System Test";
        REPORT "(Testing debugMsgFSM only)";
        REPORT "========================================";

        -- Reset
        GReset <= '0';
        TL_State <= "11";  -- Initial state
        TDRE <= '1';
        WAIT FOR CLK_PERIOD * 10;
        
        GReset <= '1';
        WAIT FOR CLK_PERIOD * 10;

        -- Test: Change to state 00 and wait for message
        REPORT "--- Changing to state 00 ---";
        TL_State <= "00";
        
        -- Wait for message to complete (about 50 clock cycles max)
        FOR i IN 1 TO 100 LOOP
            WAIT FOR CLK_PERIOD;
            EXIT WHEN char_count >= 6;
        END LOOP;
        
        REPORT "Captured " & INTEGER'IMAGE(char_count) & " characters";
        
        -- Print captured characters
        FOR i IN 0 TO char_count-1 LOOP
            IF captured_chars(i) = "00001101" THEN
                REPORT "  Char " & INTEGER'IMAGE(i) & ": <CR>";
            ELSE
                REPORT "  Char " & INTEGER'IMAGE(i) & ": 0x" & 
                       INTEGER'IMAGE(to_integer(unsigned(captured_chars(i))));
            END IF;
        END LOOP;
        
        -- Verify message
        IF char_count = 6 THEN
            REPORT "PASS: Received 6 characters";
        ELSE
            REPORT "FAIL: Expected 6 characters" SEVERITY ERROR;
        END IF;

        WAIT FOR CLK_PERIOD * 20;

        REPORT "========================================";
        REPORT "Test Complete";
        REPORT "========================================";

        stop_clock <= TRUE;
        WAIT;
    END PROCESS;

END behavior;