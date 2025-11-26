LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY receiverFSMControl IS
    PORT(
        RDRF, RXD, fourB8, eightB8, bitC8       : IN  STD_LOGIC;
        G_Clock                                 : IN  STD_LOGIC;
        G_Reset                                 : IN  STD_LOGIC;
        resetCount, resetBitCount               : OUT STD_LOGIC;
        shiftEN, loadEN                         : OUT STD_LOGIC;
        setRDRF, setOE, setFE                   : OUT STD_LOGIC;
        stateOut                                : OUT STD_LOGIC_VECTOR(2 downto 0));
END receiverFSMControl;

ARCHITECTURE structural OF receiverFSMControl IS 
    SIGNAL w, y2, y1, y0          : STD_LOGIC;
    SIGNAL n_w, n_y2, n_y1, n_y0  : STD_LOGIC;
    SIGNAL sA, sB, sC, sD, sE     : STD_LOGIC; 
    SIGNAL i_d0, i_d1, i_d2       : STD_LOGIC;
    SIGNAL resetCountSignal       : STD_LOGIC;

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC);
    END COMPONENT;

BEGIN

    -- State flip-flops
    dFF_y2: enARdFF_2
        PORT MAP(
            i_resetBar  => G_Reset,
            i_d         => i_d2,
            i_enable    => '1',
            i_clock     => G_Clock,
            o_q         => y2,
            o_qBar      => n_y2
        );

    dFF_y1: enARdFF_2
        PORT MAP(
            i_resetBar  => G_Reset,
            i_d         => i_d1,
            i_enable    => '1',
            i_clock     => G_Clock,
            o_q         => y1,
            o_qBar      => n_y1
        );

    dFF_y0: enARdFF_2
        PORT MAP(
            i_resetBar  => G_Reset,
            i_d         => i_d0,
            i_enable    => '1',
            i_clock     => G_Clock,
            o_q         => y0,
            o_qBar      => n_y0
        );

    -- State decode
    sA <= n_y2 AND n_y1 AND n_y0;  -- 000
    sB <= n_y2 AND n_y1 AND y0;    -- 001
    sC <= n_y2 AND y1 AND n_y0;    -- 010
    sD <= n_y2 AND y1 AND y0;      -- 011
    sE <= y2 AND n_y1 AND n_y0;    -- 100

    -- Transition condition
    w <= ((sA AND NOT(RXD))
         OR (sB AND fourB8)
         OR (sC AND eightB8 AND bitC8)
         OR (sD AND eightB8)
         OR (sE));

    n_w <= NOT(w);

    -- Next state logic
    i_d2 <= (w AND y1 AND y0) OR (n_w AND y2);
    i_d1 <= (w AND y0 AND n_y1) OR (y1 AND n_y0) OR (n_w AND y1);
    i_d0 <= n_y2 AND ((w AND n_y0) OR (n_w AND y0));

    -- FIXED: Single assignment to resetCountSignal (removed duplicate)
    resetCountSignal <= sA OR (sB AND fourB8) OR (sC AND eightB8);

    -- Registered reset count output
    dFF_resetCount: enARdFF_2
        PORT MAP(
            i_resetBar  => G_Reset,
            i_d         => resetCountSignal,
            i_enable    => '1',
            i_clock     => G_Clock,
            o_q         => resetCount,
            o_qBar      => OPEN
        );

    -- Output Flags
    shiftEN       <= sC AND eightB8;
    loadEN        <= sE;
    resetBitCount <= sA OR sB;

    -- Status Flags
    setRDRF <= sE AND NOT(RDRF);
    setOE   <= sE AND RDRF;
    setFE   <= sD AND eightB8 AND NOT(RXD);

    -- State output for debug
    stateOut(2) <= y2;
    stateOut(1) <= y1;
    stateOut(0) <= y0;

END structural;
