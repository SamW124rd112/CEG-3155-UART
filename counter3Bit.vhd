LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY counter3Bit IS
    PORT(
        GClock     : IN  STD_LOGIC;
        GReset     : IN  STD_LOGIC;
        i_reset    : IN  STD_LOGIC;
        i_enable   : IN  STD_LOGIC;
        o_count    : OUT STD_LOGIC_VECTOR(2 downto 0);
        o_maxReach : OUT STD_LOGIC 
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
    SIGNAL ff_enable        : STD_LOGIC;
    SIGNAL is_five : STD_LOGIC;
    SIGNAL do_reset : STD_LOGIC;

BEGIN

    is_five <= q2 AND (NOT q1) AND q0;
    
    do_reset <= i_reset OR (is_five AND i_enable);

    next0 <= NOT q0;

    next1 <= q1 XOR q0;


    next2 <= q2 XOR (q1 AND q0);

    mux_d0: oneBitMux2to1
        PORT MAP(
            s  => do_reset,
            x0 => next0,
            x1 => '0',
            y  => d0
        );

    mux_d1: oneBitMux2to1
        PORT MAP(
            s  => do_reset,
            x0 => next1,
            x1 => '0',
            y  => d1
        );

    mux_d2: oneBitMux2to1
        PORT MAP(
            s  => do_reset,
            x0 => next2,
            x1 => '0',
            y  => d2
        );

    ff_enable <= i_enable OR i_reset;

    ff_q0: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d0,
            i_enable   => ff_enable,
            i_clock    => GClock,
            o_q        => q0,
            o_qBar     => n_q0
        );

    ff_q1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d1,
            i_enable   => ff_enable,
            i_clock    => GClock,
            o_q        => q1,
            o_qBar     => n_q1
        );

    ff_q2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d2,
            i_enable   => ff_enable,
            i_clock    => GClock,
            o_q        => q2,
            o_qBar     => n_q2
        );
    o_count(0) <= q0;
    o_count(1) <= q1;
    o_count(2) <= q2;

    o_maxReach <= is_five;

END structural;