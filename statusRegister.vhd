LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY statusRegister IS
    PORT(
        GClock               : IN  STD_LOGIC;
        GReset               : IN  STD_LOGIC;
        setTDRE, setRDRF     : IN  STD_LOGIC;
        setOE, setFE         : IN  STD_LOGIC;
        clrTDRE, clrRDRF     : IN  STD_LOGIC;
        clrOE, clrFE         : IN  STD_LOGIC;
        TDRE, RDRF           : OUT STD_LOGIC;
        OE, FE               : OUT STD_LOGIC;
        SCSR                 : OUT STD_LOGIC_VECTOR(7 downto 0)
    );
END statusRegister;

ARCHITECTURE structural OF statusRegister IS

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC
        );
    END COMPONENT;

    -- TDRE uses INVERTED internal storage so it's 1 after reset
    -- tdre_n_int = 0 means TDRE = 1, tdre_n_int = 1 means TDRE = 0
    SIGNAL tdre_n_int, tdre_n_next : STD_LOGIC;
    SIGNAL tdre_int : STD_LOGIC;
    
    SIGNAL rdrf_int, oe_int, fe_int : STD_LOGIC;
    SIGNAL rdrf_next, oe_next, fe_next : STD_LOGIC;
    SIGNAL rdrf_bar, oe_bar, fe_bar : STD_LOGIC;
    SIGNAL clr_rdrf_n, clr_oe_n, clr_fe_n : STD_LOGIC;
    SIGNAL rdrf_hold, oe_hold, fe_hold : STD_LOGIC;

BEGIN

    ---------------------------------------------------------------------------
    -- TDRE: Uses inverted storage so reset gives TDRE=1
    -- Store tdre_n = NOT(TDRE)
    -- After reset: tdre_n = 0, therefore TDRE = 1 (empty, ready for data)
    ---------------------------------------------------------------------------
    
    -- Logic: tdre_n_next = (NOT setTDRE) AND (tdre_n_int OR clrTDRE)
    -- setTDRE forces tdre_n to 0 (TDRE=1)
    -- clrTDRE forces tdre_n to 1 (TDRE=0)
    -- Otherwise hold current value
    tdre_n_next <= (NOT setTDRE) AND (tdre_n_int OR clrTDRE);
    
    tdre_n_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => tdre_n_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => tdre_n_int,
            o_qBar     => tdre_int    -- This gives us TDRE directly!
        );

    ---------------------------------------------------------------------------
    -- RDRF, OE, FE: Normal storage (0 after reset is correct)
    ---------------------------------------------------------------------------

    clr_rdrf_n <= NOT clrRDRF;
    clr_oe_n   <= NOT clrOE;
    clr_fe_n   <= NOT clrFE;

    rdrf_hold <= rdrf_int AND clr_rdrf_n;
    oe_hold   <= oe_int AND clr_oe_n;
    fe_hold   <= fe_int AND clr_fe_n;
    
    rdrf_next <= setRDRF OR rdrf_hold;
    oe_next   <= setOE OR oe_hold;
    fe_next   <= setFE OR fe_hold;

    rdrf_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => rdrf_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => rdrf_int,
            o_qBar     => rdrf_bar
        );

    oe_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => oe_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => oe_int,
            o_qBar     => oe_bar
        );

    fe_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => fe_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => fe_int,
            o_qBar     => fe_bar
        );

    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    TDRE <= tdre_int;
    RDRF <= rdrf_int;
    OE   <= oe_int;
    FE   <= fe_int;

    SCSR(7) <= tdre_int;
    SCSR(6) <= rdrf_int;
    SCSR(5) <= oe_int;
    SCSR(4) <= fe_int;
    SCSR(3 downto 0) <= "0000";  

END structural;
