LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY statusRegister IS
    PORT(
        GClock      : IN  STD_LOGIC;
        GReset      : IN  STD_LOGIC;
        
        -- Set signals
        setTDRE     : IN  STD_LOGIC;
        setRDRF     : IN  STD_LOGIC;
        setOE       : IN  STD_LOGIC;
        setFE       : IN  STD_LOGIC;
        
        -- Clear signals
        clrTDRE     : IN  STD_LOGIC;
        clrRDRF     : IN  STD_LOGIC;
        clrOE       : IN  STD_LOGIC;
        clrFE       : IN  STD_LOGIC;
        
        -- Status outputs
        TDRE        : OUT STD_LOGIC;
        RDRF        : OUT STD_LOGIC;
        OE          : OUT STD_LOGIC;
        FE          : OUT STD_LOGIC;
        
        -- Register output
        SCSR        : OUT STD_LOGIC_VECTOR(7 downto 0)
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

    SIGNAL tdre_int, rdrf_int, oe_int, fe_int : STD_LOGIC;
    SIGNAL tdre_next, rdrf_next, oe_next, fe_next : STD_LOGIC;
    SIGNAL tdre_bar, rdrf_bar, oe_bar, fe_bar : STD_LOGIC;
    SIGNAL clr_tdre_n, clr_rdrf_n, clr_oe_n, clr_fe_n : STD_LOGIC;
    SIGNAL tdre_hold, rdrf_hold, oe_hold, fe_hold : STD_LOGIC;

BEGIN

    -- Inverted clear signals
    clr_tdre_n <= NOT clrTDRE;
    clr_rdrf_n <= NOT clrRDRF;
    clr_oe_n   <= NOT clrOE;
    clr_fe_n   <= NOT clrFE;

    -- SR flip-flop logic: next = set OR (current AND NOT clear)
    tdre_hold <= tdre_int AND clr_tdre_n;
    rdrf_hold <= rdrf_int AND clr_rdrf_n;
    oe_hold   <= oe_int AND clr_oe_n;
    fe_hold   <= fe_int AND clr_fe_n;
    
    tdre_next <= setTDRE OR tdre_hold;
    rdrf_next <= setRDRF OR rdrf_hold;
    oe_next   <= setOE OR oe_hold;
    fe_next   <= setFE OR fe_hold;

    -- TDRE flip-flop
    tdre_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => tdre_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => tdre_int,
            o_qBar     => tdre_bar
        );

    -- RDRF flip-flop
    rdrf_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => rdrf_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => rdrf_int,
            o_qBar     => rdrf_bar
        );

    -- OE flip-flop
    oe_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => oe_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => oe_int,
            o_qBar     => oe_bar
        );

    -- FE flip-flop
    fe_ff: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => fe_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => fe_int,
            o_qBar     => fe_bar
        );

    -- Individual outputs
    TDRE <= tdre_int;
    RDRF <= rdrf_int;
    OE   <= oe_int;
    FE   <= fe_int;

    -- Combined register output
    -- SCSR[7:4] = "0000", SCSR[3] = TDRE, [2] = RDRF, [1] = OE, [0] = FE
    SCSR(7) <= '0';
    SCSR(6) <= '0';
    SCSR(5) <= '0';
    SCSR(4) <= '0';
    SCSR(3) <= tdre_int;
    SCSR(2) <= rdrf_int;
    SCSR(1) <= oe_int;
    SCSR(0) <= fe_int;

END structural;
