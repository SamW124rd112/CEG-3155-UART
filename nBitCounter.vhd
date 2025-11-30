LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitCounter IS
    GENERIC(n : INTEGER := 4);
    PORT(
        i_resetBar    : IN  STD_LOGIC;
        i_resetCount  : IN  STD_LOGIC;  -- Synchronous reset to zero
        i_load        : IN  STD_LOGIC;
        i_clock       : IN  STD_LOGIC;
        o_Value       : OUT STD_LOGIC_VECTOR(n-1 downto 0));
END nBitCounter;

ARCHITECTURE structural OF nBitCounter IS
    SIGNAL int_q       : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL int_qBar    : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL int_d       : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL int_next    : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL int_carry   : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL resetCount_n : STD_LOGIC;

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT oneBitMux2to1
        PORT(
            s, x0, x1 : IN  STD_LOGIC;
            y         : OUT STD_LOGIC);
    END COMPONENT;

BEGIN

    resetCount_n <= NOT i_resetCount;

    -- Bit 0: always toggles when counting
    int_next(0) <= NOT int_q(0);
    int_carry(0) <= int_q(0);

    -- Generate carry chain and toggle logic for bits 1 to n-1
    GEN_NEXT: FOR i IN 1 TO n-1 GENERATE
        int_carry(i) <= int_carry(i-1) AND int_q(i);
        int_next(i) <= int_q(i) XOR int_carry(i-1);
    END GENERATE;

    -- Mux to select between 0 (reset) and next value (count)
    -- When i_resetCount='1', select '0'; otherwise select int_next
    GEN_MUX: FOR i IN 0 TO n-1 GENERATE
        mux_reset: oneBitMux2to1
            PORT MAP(
                s  => i_resetCount,
                x0 => int_next(i),   -- Normal counting
                x1 => '0',           -- Reset to 0
                y  => int_d(i)
            );
    END GENERATE;

    -- Flip-flops for each bit
    GEN_FF: FOR i IN 0 TO n-1 GENERATE
        ff_bit: enARdFF_2
            PORT MAP(
                i_resetBar => i_resetBar,
                i_d        => int_d(i),
                i_enable   => i_load,
                i_clock    => i_clock,
                o_q        => int_q(i),
                o_qBar     => int_qBar(i)
            );
    END GENERATE;

    o_Value <= int_q;

END structural;