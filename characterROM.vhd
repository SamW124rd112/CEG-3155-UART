LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY characterROM IS
    PORT(
        TL_State  : IN  STD_LOGIC_VECTOR(1 downto 0);  -- Traffic light state
        charIndex : IN  STD_LOGIC_VECTOR(2 downto 0);  -- Character position 0-6
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

    SIGNAL CHAR_M  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_g  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_y  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_r  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_SP : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_S  : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL CHAR_CR : STD_LOGIC_VECTOR(7 downto 0);

    SIGNAL char_pos2 : STD_LOGIC_VECTOR(7 downto 0);  -- 'g'/'y'/'r'/'r'
    SIGNAL char_pos5 : STD_LOGIC_VECTOR(7 downto 0);  -- 'r'/'r'/'g'/'y'

BEGIN

    CHAR_SP <= "00100000";  -- ' ' = 0x20
    CHAR_M  <= "01001101";  -- 'M' = 0x4D
    CHAR_g  <= "01100111";  -- 'g' = 0x67
    CHAR_y  <= "01111001";  -- 'y' = 0x79
    CHAR_r  <= "01110010";  -- 'r' = 0x72
    CHAR_S  <= "01010011";  -- 'S' = 0x53
    CHAR_CR <= "00001101";  -- CR  = 0x0D


    mux_pos2: nBitMux4to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => TL_State(0),
            s1 => TL_State(1),
            x0 => CHAR_g,   -- State 00: " Mg Sr"
            x1 => CHAR_y,   -- State 01: " My Sr"
            x2 => CHAR_r,   -- State 10: " Mr Sg"
            x3 => CHAR_r,   -- State 11: " Mr Sy"
            y  => char_pos2
        );

    mux_pos5: nBitMux4to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => TL_State(0),
            s1 => TL_State(1),
            x0 => CHAR_r,   -- State 00: " Mg Sr"
            x1 => CHAR_r,   -- State 01: " My Sr"
            x2 => CHAR_g,   -- State 10: " Mr Sg"
            x3 => CHAR_y,   -- State 11: " Mr Sy"
            y  => char_pos5
        );

    mux_final: nBitMux8to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => charIndex(0),
            s1 => charIndex(1),
            s2 => charIndex(2),
            x0 => CHAR_SP,     -- Position 0: ' ' (leading space)
            x1 => CHAR_M,      -- Position 1: 'M'
            x2 => char_pos2,   -- Position 2: 'g'/'y'/'r'/'r'
            x3 => CHAR_SP,     -- Position 3: ' ' (separator)
            x4 => CHAR_S,      -- Position 4: 'S'
            x5 => char_pos5,   -- Position 5: 'r'/'r'/'g'/'y'
            x6 => CHAR_CR,     -- Position 6: CR
            x7 => CHAR_CR,     -- Unused
            y  => charOut
        );

END structural;