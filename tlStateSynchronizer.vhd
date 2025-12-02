LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tlStateSynchronizer IS
    PORT(
        GClock      : IN  STD_LOGIC;
        GReset      : IN  STD_LOGIC;
        asyncState  : IN  STD_LOGIC_VECTOR(1 downto 0);
        syncState   : OUT STD_LOGIC_VECTOR(1 downto 0)
    );
END tlStateSynchronizer;

ARCHITECTURE structural OF tlStateSynchronizer IS

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC);
    END COMPONENT;

    SIGNAL sync1_0, sync1_1 : STD_LOGIC;
    SIGNAL sync2_0, sync2_1 : STD_LOGIC;

BEGIN

    sync1_ff0: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => asyncState(0),
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => sync1_0,
            o_qBar     => open
        );

    sync2_ff0: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => sync1_0,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => sync2_0,
            o_qBar     => open
        );

    sync1_ff1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => asyncState(1),
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => sync1_1,
            o_qBar     => open
        );

    sync2_ff1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => sync1_1,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => sync2_1,
            o_qBar     => open
        );

    syncState(0) <= sync2_0;
    syncState(1) <= sync2_1;

END structural;