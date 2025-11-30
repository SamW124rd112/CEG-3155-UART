LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY counter3Bit IS
    PORT(
        GClock     : IN  STD_LOGIC;
        GReset     : IN  STD_LOGIC;
        i_reset    : IN  STD_LOGIC;  -- Synchronous reset
        i_enable   : IN  STD_LOGIC;  -- Count enable
        o_count    : OUT STD_LOGIC_VECTOR(2 downto 0);
        o_maxReach : OUT STD_LOGIC   -- High when count = 5
    );
END counter3Bit;

ARCHITECTURE structural OF counter3Bit IS

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

    SIGNAL q2, q1, q0       : STD_LOGIC;
    SIGNAL n_q2, n_q1, n_q0 : STD_LOGIC;
    SIGNAL d2, d1, d0       : STD_LOGIC;
    SIGNAL next2, next1, next0 : STD_LOGIC;
    SIGNAL mux_out2, mux_out1, mux_out0 : STD_LOGIC;
    SIGNAL enable_or_reset  : STD_LOGIC;

    -- For detecting count = 5 (binary 101)
    SIGNAL is_five : STD_LOGIC;

    -- For wrap-around: when count=5, next is 0
    SIGNAL wrap : STD_LOGIC;
    SIGNAL wrap_n : STD_LOGIC;

BEGIN

    -- Detect when count = 5 (101)
    is_five <= q2 AND n_q1 AND q0;
    wrap <= is_five AND i_enable;
    wrap_n <= NOT wrap;

    ---------------------------------------------------------------------------
    -- Next count logic (increment)
    -- 000 -> 001 -> 010 -> 011 -> 100 -> 101 -> 000 (wrap)
    ---------------------------------------------------------------------------
    
    -- Bit 0: toggles every count
    next0 <= n_q0;

    -- Bit 1: toggles when bit 0 is 1
    next1 <= q1 XOR q0;

    -- Bit 2: toggles when bits 1 and 0 are both 1
    next2 <= q2 XOR (q1 AND q0);

    ---------------------------------------------------------------------------
    -- Mux for reset: select 0 when reset or wrap, else next value
    ---------------------------------------------------------------------------
    mux_reset0: oneBitMux2to1
        PORT MAP(
            s  => i_reset,
            x0 => next0,
            x1 => '0',
            y  => mux_out0
        );

    mux_reset1: oneBitMux2to1
        PORT MAP(
            s  => i_reset,
            x0 => next1,
            x1 => '0',
            y  => mux_out1
        );

    mux_reset2: oneBitMux2to1
        PORT MAP(
            s  => i_reset,
            x0 => next2,
            x1 => '0',
            y  => mux_out2
        );

    -- Mux for wrap-around
    mux_wrap0: oneBitMux2to1
        PORT MAP(
            s  => wrap,
            x0 => mux_out0,
            x1 => '0',
            y  => d0
        );

    mux_wrap1: oneBitMux2to1
        PORT MAP(
            s  => wrap,
            x0 => mux_out1,
            x1 => '0',
            y  => d1
        );

    mux_wrap2: oneBitMux2to1
        PORT MAP(
            s  => wrap,
            x0 => mux_out2,
            x1 => '0',
            y  => d2
        );

    -- Enable for flip-flops
    enable_or_reset <= i_enable OR i_reset;

    ---------------------------------------------------------------------------
    -- State Flip-Flops
    ---------------------------------------------------------------------------
    ff_q0: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d0,
            i_enable   => enable_or_reset,
            i_clock    => GClock,
            o_q        => q0,
            o_qBar     => n_q0
        );

    ff_q1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d1,
            i_enable   => enable_or_reset,
            i_clock    => GClock,
            o_q        => q1,
            o_qBar     => n_q1
        );

    ff_q2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d2,
            i_enable   => enable_or_reset,
            i_clock    => GClock,
            o_q        => q2,
            o_qBar     => n_q2
        );

    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    o_count(0) <= q0;
    o_count(1) <= q1;
    o_count(2) <= q2;

    o_maxReach <= is_five;

END structural;