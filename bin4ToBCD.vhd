LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bin4ToBCD IS
    PORT(
        i_binary    : IN  STD_LOGIC_VECTOR(3 downto 0);
        o_tens      : OUT STD_LOGIC_VECTOR(3 downto 0);
        o_ones      : OUT STD_LOGIC_VECTOR(3 downto 0));
END bin4ToBCD;

ARCHITECTURE structural OF bin4ToBCD IS
    SIGNAL ten_val : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL is_gt, is_eq, is_gte_10 : STD_LOGIC;
    SIGNAL diff : STD_LOGIC_VECTOR(3 downto 0);
    
    COMPONENT nBitComparator
        GENERIC(n: INTEGER := 4);
        PORT(
            i_Ai, i_Bi          : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            o_GT, o_LT, o_EQ    : OUT STD_LOGIC);
    END COMPONENT;
    
    COMPONENT nBitAddSubUnit
        GENERIC (n : INTEGER := 4);
        PORT(
            i_A, i_Bi       : IN    STD_LOGIC_VECTOR(n-1 downto 0);
            i_OpFlag        : IN    STD_LOGIC;
            o_CarryOut      : OUT   STD_LOGIC;
            o_Sum           : OUT   STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;
    
BEGIN
    ten_val <= "1010"; -- 10 in binary
    
    -- Compare: is input >= 10?
    comp: nBitComparator
        GENERIC MAP(n => 4)
        PORT MAP(
            i_Ai => i_binary,
            i_Bi => ten_val,
            o_GT => is_gt,
            o_LT => open,
            o_EQ => is_eq
        );
    
    is_gte_10 <= is_gt or is_eq;
    
    -- Subtract 10 from input
    sub: nBitAddSubUnit
        GENERIC MAP(n => 4)
        PORT MAP(
            i_A => i_binary,
            i_Bi => ten_val,
            i_OpFlag => '1',  -- Subtract mode
            o_CarryOut => open,
            o_Sum => diff
        );
    
    -- Tens digit: 1 if >= 10, else 0
    o_tens <= "0001" when is_gte_10 = '1' else "0000";
    
    -- Ones digit: (value - 10) if >= 10, else original value
    o_ones <= diff when is_gte_10 = '1' else i_binary;
    
END structural;