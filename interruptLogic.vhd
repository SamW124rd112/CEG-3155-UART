LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY interruptLogic IS
    PORT(
        TIE, RIE     : IN  STD_LOGIC;
        TDRE, RDRF    : IN  STD_LOGIC;
        OE      : IN  STD_LOGIC;
        IRQ     : OUT STD_LOGIC
    );
END interruptLogic;

ARCHITECTURE structural OF interruptLogic IS

    SIGNAL rdrf_or_oe : STD_LOGIC;
    SIGNAL rx_int : STD_LOGIC;
    SIGNAL tx_int : STD_LOGIC;

BEGIN

    -- IRQ = (RIE AND (RDRF OR OE)) OR (TIE AND TDRE)
    rdrf_or_oe <= RDRF OR OE;
    rx_int     <= RIE AND rdrf_or_oe;
    tx_int     <= TIE AND TDRE;
    IRQ        <= rx_int OR tx_int;

END structural;
