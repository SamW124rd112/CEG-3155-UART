LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY debugMsgFSMControl IS
    PORT(
        GClock       : IN  STD_LOGIC;
        GReset       : IN  STD_LOGIC;
        stateChanged : IN  STD_LOGIC;
        TDRE         : IN  STD_LOGIC;
        msgDone      : IN  STD_LOGIC;
        counterReset : OUT STD_LOGIC;
        counterEn    : OUT STD_LOGIC;
        uartSelect   : OUT STD_LOGIC;
        uartRW       : OUT STD_LOGIC;
        addrBit0     : OUT STD_LOGIC;
        stateOut     : OUT STD_LOGIC_VECTOR(2 downto 0)
    );
END debugMsgFSMControl;

ARCHITECTURE structural OF debugMsgFSMControl IS

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC);
    END COMPONENT;

    SIGNAL y2, y1, y0       : STD_LOGIC;
    SIGNAL n_y2, n_y1, n_y0 : STD_LOGIC;
    SIGNAL d2, d1, d0       : STD_LOGIC;

    SIGNAL sIDLE      : STD_LOGIC; 
    SIGNAL sWAIT_TDRE : STD_LOGIC; 
    SIGNAL sWRITE_TDR : STD_LOGIC; 
    SIGNAL sWAIT_TX   : STD_LOGIC; 
    SIGNAL sNEXT_CHAR : STD_LOGIC; 
    SIGNAL sDONE      : STD_LOGIC;  

    SIGNAL msgDone_n  : STD_LOGIC;
    SIGNAL TDRE_n     : STD_LOGIC;

BEGIN

    ff_y2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d2,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => y2,
            o_qBar     => n_y2
        );

    ff_y1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d1,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => y1,
            o_qBar     => n_y1
        );

    ff_y0: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => d0,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => y0,
            o_qBar     => n_y0
        );


    sIDLE      <= n_y2 AND n_y1 AND n_y0;
    sWAIT_TDRE <= n_y2 AND n_y1 AND y0;
    sWRITE_TDR <= n_y2 AND y1 AND n_y0; 
    sWAIT_TX   <= n_y2 AND y1 AND y0;
    sNEXT_CHAR <= y2 AND n_y1 AND n_y0;
    sDONE      <= y2 AND n_y1 AND y0;

    msgDone_n <= NOT msgDone;
    TDRE_n    <= NOT TDRE;


    d2 <= (sWAIT_TX AND TDRE_n) OR   
          (sNEXT_CHAR AND msgDone);  

    d1 <= (sWAIT_TDRE AND TDRE) OR
          sWRITE_TDR OR 
          (sWAIT_TX AND TDRE);

    d0 <= (sIDLE AND stateChanged) OR  
          (sWAIT_TDRE AND TDRE_n) OR     
          sWRITE_TDR OR                 
          (sWAIT_TX AND TDRE) OR        
          sNEXT_CHAR;            

    counterReset <= sIDLE OR sDONE;

    counterEn <= sNEXT_CHAR;

    uartSelect <= sWAIT_TDRE OR sWRITE_TDR OR sWAIT_TX;

    uartRW <= sWAIT_TDRE OR sWAIT_TX;

    addrBit0 <= sWAIT_TDRE OR sWAIT_TX;

    stateOut(2) <= y2;
    stateOut(1) <= y1;
    stateOut(0) <= y0;

END structural;