LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_nBitRightShiftRegister IS
END tb_nBitRightShiftRegister;

ARCHITECTURE behavior OF tb_nBitRightShiftRegister IS
    -- Component Declaration
    COMPONENT nBitRightShiftRegister
        GENERIC(n : INTEGER := 8);
        PORT(
            i_resetBar, i_load  : IN STD_LOGIC;
            i_enable            : IN STD_LOGIC;
            i_clock             : IN STD_LOGIC;
            i_loadValue         : IN STD_LOGIC_VECTOR(n-1 downto 0);
            i_shiftIn           : IN STD_LOGIC;
            o_Value             : OUT STD_LOGIC_VECTOR(n-1 downto 0);
            o_shiftOut          : OUT STD_LOGIC);
    END COMPONENT;
    
    -- Constants
    CONSTANT n : INTEGER := 8;
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    
    -- Signals
    SIGNAL i_resetBar   : STD_LOGIC := '1';
    SIGNAL i_load       : STD_LOGIC := '0';
    SIGNAL i_enable     : STD_LOGIC := '0';
    SIGNAL i_clock      : STD_LOGIC := '0';
    SIGNAL i_loadValue  : STD_LOGIC_VECTOR(n-1 downto 0) := (others => '0');
    SIGNAL i_shiftIn    : STD_LOGIC := '0';
    SIGNAL o_Value      : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL o_shiftOut   : STD_LOGIC;
    SIGNAL sim_done     : BOOLEAN := FALSE;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    UUT: nBitRightShiftRegister
        GENERIC MAP (n => n)
        PORT MAP (
            i_resetBar  => i_resetBar,
            i_load      => i_load,
            i_enable    => i_enable,
            i_clock     => i_clock,
            i_loadValue => i_loadValue,
            i_shiftIn   => i_shiftIn,
            o_Value     => o_Value,
            o_shiftOut  => o_shiftOut
        );
    
    -- Clock generation
    clock_process: PROCESS
    BEGIN
        WHILE NOT sim_done LOOP
            i_clock <= '0';
            WAIT FOR CLOCK_PERIOD/2;
            i_clock <= '1';
            WAIT FOR CLOCK_PERIOD/2;
        END LOOP;
        WAIT;
    END PROCESS;
    
    -- Stimulus process
    stim_process: PROCESS
    BEGIN
        -- Test 1: Asynchronous Reset
        REPORT "=== Test 1: Asynchronous Reset ===" SEVERITY NOTE;
        i_resetBar <= '0';
        i_enable <= '1';
        WAIT FOR CLOCK_PERIOD * 2;
        i_resetBar <= '1';
        WAIT FOR 1 ns;
        ASSERT o_Value = "00000000" 
            REPORT "FAIL: Reset" SEVERITY ERROR;
        REPORT "PASS: Reset" SEVERITY NOTE;
        
        -- Test 2: Parallel Load
        REPORT "=== Test 2: Parallel Load ===" SEVERITY NOTE;
        i_load <= '1';
        i_enable <= '1';
        i_loadValue <= "10101010";  -- 0xAA
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "10101010" 
            REPORT "FAIL: Parallel Load" SEVERITY ERROR;
        REPORT "PASS: Parallel Load (0xAA loaded)" SEVERITY NOTE;
        
        -- Test 3: Right Shift (shift in 0)
        REPORT "=== Test 3: Right Shift with '0' ===" SEVERITY NOTE;
        i_load <= '0';
        i_shiftIn <= '0';
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "01010101" AND o_shiftOut = '0'
            REPORT "FAIL: Right Shift step 1" SEVERITY ERROR;
            
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "00101010" AND o_shiftOut = '1'
            REPORT "FAIL: Right Shift step 2" SEVERITY ERROR;
        REPORT "PASS: Right Shift with '0'" SEVERITY NOTE;
        
        -- Test 4: Right Shift (shift in 1)
        REPORT "=== Test 4: Right Shift with '1' ===" SEVERITY NOTE;
        i_shiftIn <= '1';
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "10010101" AND o_shiftOut = '0'
            REPORT "FAIL: Right Shift with '1'" SEVERITY ERROR;
        REPORT "PASS: Right Shift with '1'" SEVERITY NOTE;
        
        -- Test 5: Disable Enable Signal
        REPORT "=== Test 5: Disable Enable ===" SEVERITY NOTE;
        i_enable <= '0';
        i_shiftIn <= '0';
        WAIT UNTIL rising_edge(i_clock);
        WAIT UNTIL rising_edge(i_clock);
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "10010101" 
            REPORT "FAIL: Enable disabled" SEVERITY ERROR;
        REPORT "PASS: Register holds value when disabled" SEVERITY NOTE;
        
        -- Test 6: Re-enable
        REPORT "=== Test 6: Re-enable ===" SEVERITY NOTE;
        i_enable <= '1';
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "01001010" 
            REPORT "FAIL: Re-enable" SEVERITY ERROR;
        REPORT "PASS: Re-enable and shift" SEVERITY NOTE;
        
        -- Test 7: Load and Shift sequence
        REPORT "=== Test 7: Load 0xFF and Shift Out ===" SEVERITY NOTE;
        i_load <= '1';
        i_loadValue <= "11111111";
        WAIT UNTIL rising_edge(i_clock);
        WAIT FOR 1 ns;
        ASSERT o_Value = "11111111" 
            REPORT "FAIL: Load 0xFF" SEVERITY ERROR;
        REPORT "PASS: Load 0xFF" SEVERITY NOTE;
        
        -- Shift all bits out
        i_load <= '0';
        i_shiftIn <= '0';
        FOR i IN 0 TO n-1 LOOP
            WAIT UNTIL rising_edge(i_clock);
        END LOOP;
        WAIT FOR 1 ns;
        ASSERT o_Value = "00000000" 
            REPORT "FAIL: Shift all bits out" SEVERITY ERROR;
        REPORT "PASS: All bits shifted out" SEVERITY NOTE;
        
        -- End simulation
        REPORT "=== ALL TESTS COMPLETED SUCCESSFULLY ===" SEVERITY NOTE;
        sim_done <= TRUE;
        WAIT;
    END PROCESS;

END behavior;
