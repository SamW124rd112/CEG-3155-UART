LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY debugMsgFSMControl IS
    PORT(
        GClock       : IN  STD_LOGIC;
        GReset       : IN  STD_LOGIC;
        stateChanged : IN  STD_LOGIC;
        TDRE         : IN  STD_LOGIC;
        msgDone      : IN  STD_LOGIC;
        -- Outputs
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

    -- State flip-flops (3 bits for 5 states)
    SIGNAL y2, y1, y0       : STD_LOGIC;
    SIGNAL n_y2, n_y1, n_y0 : STD_LOGIC;
    SIGNAL d2, d1, d0       : STD_LOGIC;

    -- State decode signals (active high)
    SIGNAL sIDLE      : STD_LOGIC;  -- 000
    SIGNAL sWAIT_TDRE : STD_LOGIC;  -- 001
    SIGNAL sWRITE_TDR : STD_LOGIC;  -- 010
    SIGNAL sNEXT_CHAR : STD_LOGIC;  -- 011
    SIGNAL sDONE      : STD_LOGIC;  -- 100

    -- Intermediate signals
    SIGNAL msgDone_n : STD_LOGIC;

BEGIN

    ---------------------------------------------------------------------------
    -- State Flip-Flops
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- State Decode (one-hot from binary)
    -- NEW ENCODING:
    --   IDLE      = 000
    --   WAIT_TDRE = 001
    --   WRITE_TDR = 010
    --   NEXT_CHAR = 011
    --   DONE      = 100
    ---------------------------------------------------------------------------
    sIDLE      <= n_y2 AND n_y1 AND n_y0;  -- 000
    sWAIT_TDRE <= n_y2 AND n_y1 AND y0;    -- 001
    sWRITE_TDR <= n_y2 AND y1 AND n_y0;    -- 010
    sNEXT_CHAR <= n_y2 AND y1 AND y0;      -- 011
    sDONE      <= y2 AND n_y1 AND n_y0;    -- 100

    msgDone_n <= NOT msgDone;

    ---------------------------------------------------------------------------
    -- Next State Logic
    -- 
    -- State Transitions:
    --   IDLE(000)      -> WAIT_TDRE(001) when stateChanged
    --   WAIT_TDRE(001) -> WRITE_TDR(010) when TDRE=1
    --   WRITE_TDR(010) -> NEXT_CHAR(011) always
    --   NEXT_CHAR(011) -> DONE(100)      when msgDone=1
    --   NEXT_CHAR(011) -> WAIT_TDRE(001) when msgDone=0
    --   DONE(100)      -> IDLE(000)      always
    ---------------------------------------------------------------------------
    
    -- d2: Goes high only for DONE state (100)
    --     NEXT_CHAR(011) + msgDone -> DONE(100)
    d2 <= sNEXT_CHAR AND msgDone;

    -- d1: High for WRITE_TDR(010) and NEXT_CHAR(011)
    --     WAIT_TDRE(001) + TDRE -> WRITE_TDR(010)
    --     WRITE_TDR(010) -> NEXT_CHAR(011)
    d1 <= (sWAIT_TDRE AND TDRE) OR sWRITE_TDR;

    -- d0: High for WAIT_TDRE(001) and NEXT_CHAR(011)
    --     IDLE(000) + stateChanged -> WAIT_TDRE(001)
    --     WAIT_TDRE(001) + NOT TDRE -> WAIT_TDRE(001) (stay)
    --     WRITE_TDR(010) -> NEXT_CHAR(011)
    --     NEXT_CHAR(011) + NOT msgDone -> WAIT_TDRE(001)
    d0 <= (sIDLE AND stateChanged) OR 
          (sWAIT_TDRE AND (NOT TDRE)) OR 
          sWRITE_TDR OR 
          (sNEXT_CHAR AND msgDone_n);

    ---------------------------------------------------------------------------
    -- Output Logic
    ---------------------------------------------------------------------------
    
    -- Counter reset in IDLE or DONE
    counterReset <= sIDLE OR sDONE;

    -- Counter enable in NEXT_CHAR (increment after writing each char)
    counterEn <= sNEXT_CHAR;

    -- UART select when accessing UART (WAIT_TDRE or WRITE_TDR)
    uartSelect <= sWAIT_TDRE OR sWRITE_TDR;

    -- R/W: 1=Read (for SCSR in WAIT_TDRE), 0=Write (for TDR in WRITE_TDR)
    uartRW <= sWAIT_TDRE;

    -- Address bit 0: 1 for SCSR (addr=01), 0 for TDR (addr=00)
    addrBit0 <= sWAIT_TDRE;

    -- State output for debugging
    stateOut(2) <= y2;
    stateOut(1) <= y1;
    stateOut(0) <= y0;

END structural;