LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_nBitMux8to1 IS
END tb_nBitMux8to1;

ARCHITECTURE behavior OF tb_nBitMux8to1 IS
    -- Component Declaration
    COMPONENT nBitMux8to1
    GENERIC (n: INTEGER := 4);
    PORT(
        s0, s1, s2                              : IN STD_LOGIC;
        x0, x1, x2, x3, x4, x5, x6, x7          : IN STD_LOGIC_VECTOR(n-1 downto 0);
        y                                       : OUT STD_LOGIC_VECTOR(n-1 downto 0)
    );
    END COMPONENT;
    
    -- Test parameters
    CONSTANT n : INTEGER := 4;
    
    -- Test signals
    SIGNAL s0, s1, s2 : STD_LOGIC := '0';
    SIGNAL x0, x1, x2, x3, x4, x5, x6, x7 : STD_LOGIC_VECTOR(n-1 downto 0) := (OTHERS => '0');
    SIGNAL y : STD_LOGIC_VECTOR(n-1 downto 0);
    
BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: nBitMux8to1 
    GENERIC MAP (n => n)
    PORT MAP (
        s0 => s0, s1 => s1, s2 => s2,
        x0 => x0, x1 => x1, x2 => x2, x3 => x3,
        x4 => x4, x5 => x5, x6 => x6, x7 => x7,
        y => y
    );
    
    -- Stimulus process
    stim_proc: PROCESS
    BEGIN
        -- Set distinct input patterns (easy to identify in waveform)
        -- Using binary patterns: 0000, 0001, 0010, 0011, 0100, 0101, 0110, 0111
        x0 <= "0000";
        x1 <= "0001";
        x2 <= "0010";
        x3 <= "0011";
        x4 <= "0100";
        x5 <= "0101";
        x6 <= "0110";
        x7 <= "0111";
        
        WAIT FOR 20 ns;
        
        -- Test all 8 select combinations
        
        -- Select x0 (000) - expect y = "0000"
        s2 <= '0'; s1 <= '0'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x1 (001) - expect y = "0001"
        s2 <= '0'; s1 <= '0'; s0 <= '1';
        WAIT FOR 50 ns;
        
        -- Select x2 (010) - expect y = "0010"
        s2 <= '0'; s1 <= '1'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x3 (011) - expect y = "0011"
        s2 <= '0'; s1 <= '1'; s0 <= '1';
        WAIT FOR 50 ns;
        
        -- Select x4 (100) - expect y = "0100"
        s2 <= '1'; s1 <= '0'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x5 (101) - expect y = "0101"
        s2 <= '1'; s1 <= '0'; s0 <= '1';
        WAIT FOR 50 ns;
        
        -- Select x6 (110) - expect y = "0110"
        s2 <= '1'; s1 <= '1'; s0 <= '0';
        WAIT FOR 50 ns;
        
        -- Select x7 (111) - expect y = "0111"
        s2 <= '1'; s1 <= '1'; s0 <= '1';
        WAIT FOR 50 ns;
        
        REPORT "Simulation complete - check waveform" SEVERITY NOTE;
        
        WAIT;
    END PROCESS;
    
END behavior;
