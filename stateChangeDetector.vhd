LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY stateChangeDetector IS
    PORT(
        GClock       : IN  STD_LOGIC;
        GReset       : IN  STD_LOGIC;
        currentState : IN  STD_LOGIC_VECTOR(1 downto 0);
        stateChanged : OUT STD_LOGIC
    );
END stateChangeDetector;

ARCHITECTURE structural OF stateChangeDetector IS

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC);
    END COMPONENT;

    SIGNAL prevState : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL prevState_bar : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL diff0, diff1 : STD_LOGIC;

BEGIN

    -- Register previous state
    ff_prev0: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => currentState(0),
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => prevState(0),
            o_qBar     => prevState_bar(0)
        );

    ff_prev1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => currentState(1),
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => prevState(1),
            o_qBar     => prevState_bar(1)
        );

    -- XOR to detect change
    diff0 <= currentState(0) XOR prevState(0);
    diff1 <= currentState(1) XOR prevState(1);

    -- OR the differences
    stateChanged <= diff0 OR diff1;

END structural;