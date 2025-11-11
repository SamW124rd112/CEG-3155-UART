LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_oneBitMux8to1 IS
END tb_oneBitMux8to1;

ARCHITECTURE behavior OF tb_oneBitMux8to1 IS
    -- Component Declaration
    COMPONENT oneBitMux8to1
    PORT(
        s0, s1, s2                      : IN STD_LOGIC;
        x0, x1, x2, x3, x4, x5, x6, x7  : IN STD_LOGIC;
        y                               : OUT STD_LOGIC
    );
    END COMPONENT;
    
    -- Test signals
    SIGNAL s0, s1, s2 : STD_LOGIC := '0';
    SIGNAL x0, x1, x2, x3, x4, x5, x6, x7 : STD_LOGIC := '0';
    SIGNAL y : STD_LOGIC;
    
BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: oneBitMux8to1 PORT MAP (
        s0 => s0, s1 => s1, s2 => s2,
        x0 => x0, x1 => x1, x2 => x2, x3 => x3,
        x4 => x4, x5 => x5, x6 => x6, x7 => x7,
        y => y
    );
    
    -- Stimulus process
    stim_proc: PROCESS
    BEGIN
        -- Set input pattern: alternating 0,1,0,1,0,1,0,1
        -- This makes it easy to verify: output should match select value's LSB
        x0 <= '0';
        x1 <= '1';
        x2 <= '0';
        x3 <= '1';
        x4 <= '0';
        x5 <= '1';
        x6 <= '0';
        x7 <= '1';
        
        WAIT FOR 20 ns;
        
        -- Test all 8 select combinations (000 to 111)
        
        -- Select x0 (000)
        s2 <= '0'; s1 <= '0'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x1 (001)
        s2 <= '0'; s1 <= '0'; s0 <= '1';
        WAIT FOR 50 ns;
        
        -- Select x2 (010)
        s2 <= '0'; s1 <= '1'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x3 (011)
        s2 <= '0'; s1 <= '1'; s0 <= '1';
        WAIT FOR 50 ns;
        
        -- Select x4 (100)
        s2 <= '1'; s1 <= '0'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x5 (101)
        s2 <= '1'; s1 <= '0'; s0 <= '1';
        WAIT FOR 50 ns;
        
        -- Select x6 (110)
        s2 <= '1'; s1 <= '1'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x7 (111)
        s2 <= '1'; s1 <= '1'; s0 <= '1';
        WAIT FOR 50 ns;
        
        REPORT "Simulation complete - check waveform" SEVERITY NOTE;
        
        WAIT;
    END PROCESS;
    
END behavior;
