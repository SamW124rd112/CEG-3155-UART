LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY characterROM IS
    PORT(
        TL_State  : IN  STD_LOGIC_VECTOR(1 downto 0);  -- Traffic light state
        charIndex : IN  STD_LOGIC_VECTOR(2 downto 0);  -- Character position 0-5
        charOut   : OUT STD_LOGIC_VECTOR(7 downto 0)   -- ASCII character
    );
END characterROM;

ARCHITECTURE structural OF characterROM IS

    COMPONENT nBitMux4to1
        GENERIC(n : INTEGER := 4);
        PORT(
            s0, s1     : IN  STD_LOGIC;
            x0, x1, x2, x3 : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            y          : OUT STD_LOGIC_VECTOR(n-1 downto 0)
        );
    END COMPONENT;

    COMPONENT nBitMux8to1
        GENERIC(n : INTEGER := 4);
        PORT(
            s0, s1, s2 : IN  STD_LOGIC;
            x0, x1, x2, x3, x4, x5, x6, x7 : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            y          : OUT STD_LOGIC_VECTOR(n-1 downto 0)
        );
    END COMPONENT;

    -- ASCII constants (directly as signals for structural use)
    SIGNAL CHAR_M  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_g  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_y  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_r  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_SP : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_S  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_CR : STD_LOGIC_VECTOR(7 downto 0);

    -- Characters for each position
    SIGNAL char_pos1 : STD_LOGIC_VECTOR(7 downto 0);  -- 'g'/'y'/'r'/'r'
    SIGNAL char_pos4 : STD_LOGIC_VECTOR(7 downto 0);  -- 'r'/'r'/'g'/'y'

BEGIN

    -- ASCII character assignments (active high, directly wired)
    CHAR_M  <= "01001101";  -- 'M' = 0x4D
    CHAR_g  <= "01100111";  -- 'g' = 0x67
    CHAR_y  <= "01111001";  -- 'y' = 0x79
    CHAR_r  <= "01110010";  -- 'r' = 0x72
    CHAR_SP <= "00100000";  -- ' ' = 0x20
    CHAR_S  <= "01010011";  -- 'S' = 0x53
    CHAR_CR <= "00001101";  -- CR  = 0x0D

    ---------------------------------------------------------------------------
    -- Position 1: Select character based on TL_State
    -- State 00 -> 'g', State 01 -> 'y', State 10 -> 'r', State 11 -> 'r'
    ---------------------------------------------------------------------------
    mux_pos1: nBitMux4to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => TL_State(0),
            s1 => TL_State(1),
            x0 => CHAR_g,   -- State 00: "Mg Sr"
            x1 => CHAR_y,   -- State 01: "My Sr"
            x2 => CHAR_r,   -- State 10: "Mr Sg"
            x3 => CHAR_r,   -- State 11: "Mr Sy"
            y  => char_pos1
        );

    ---------------------------------------------------------------------------
    -- Position 4: Select character based on TL_State
    -- State 00 -> 'r', State 01 -> 'r', State 10 -> 'g', State 11 -> 'y'
    ---------------------------------------------------------------------------
    mux_pos4: nBitMux4to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => TL_State(0),
            s1 => TL_State(1),
            x0 => CHAR_r,   -- State 00: "Mg Sr"
            x1 => CHAR_r,   -- State 01: "My Sr"
            x2 => CHAR_g,   -- State 10: "Mr Sg"
            x3 => CHAR_y,   -- State 11: "Mr Sy"
            y  => char_pos4
        );

    ---------------------------------------------------------------------------
    -- Final character selection based on charIndex (0-5)
    -- Position 0: 'M', Position 1: variable, Position 2: ' '
    -- Position 3: 'S', Position 4: variable, Position 5: CR
    ---------------------------------------------------------------------------
    mux_final: nBitMux8to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => charIndex(0),
            s1 => charIndex(1),
            s2 => charIndex(2),
            x0 => CHAR_M,      -- Position 0: 'M'
            x1 => char_pos1,   -- Position 1: 'g'/'y'/'r'/'r'
            x2 => CHAR_SP,     -- Position 2: ' '
            x3 => CHAR_S,      -- Position 3: 'S'
            x4 => char_pos4,   -- Position 4: 'r'/'r'/'g'/'y'
            x5 => CHAR_CR,     -- Position 5: CR
            x6 => CHAR_CR,     -- Unused (padded)
            x7 => CHAR_CR,     -- Unused (padded)
            y  => charOut
        );

END structural;