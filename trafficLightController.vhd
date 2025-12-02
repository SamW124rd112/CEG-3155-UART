LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY trafficLightController IS
    PORT(
        MSC, SSC              : IN  STD_LOGIC_VECTOR(3 downto 0);
        SSCS                  : IN  STD_LOGIC;
        G_Clock               : IN  STD_LOGIC;
        G_Reset               : IN  STD_LOGIC;
        MSTL, SSTL            : OUT STD_LOGIC_VECTOR(2 downto 0);
        BCD1, BCD2            : OUT STD_LOGIC_VECTOR(3 downto 0);
        TL_State              : OUT STD_LOGIC_VECTOR(1 downto 0));
END trafficLightController;

ARCHITECTURE structural OF trafficLightController IS

    CONSTANT MST_MAX : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    CONSTANT SST_MAX : STD_LOGIC_VECTOR(3 downto 0) := "0011";

    SIGNAL int_SSCS, int_SSCS_n, int_Compare : STD_LOGIC;
    SIGNAL int_s0, int_s1 : STD_LOGIC;
    SIGNAL int_sA, int_sB, int_sC, int_sD : STD_LOGIC;
    SIGNAL int_MST, int_SST, int_MSC, int_SSC : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL muxCounter, muxMax : STD_LOGIC_VECTOR(3 downto 0);

    SIGNAL resetCount_MSC, resetCount_MST, resetCount_SSC, resetCount_SST : STD_LOGIC;
  
    SIGNAL bcd_input : STD_LOGIC_VECTOR(3 downto 0);

    
    COMPONENT nBitComparator
        GENERIC(n: INTEGER := 4);
        PORT(
            i_Ai, i_Bi            : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            o_GT, o_LT, o_EQ      : OUT STD_LOGIC);
    END COMPONENT;


    COMPONENT nBitCounter
        GENERIC(n : INTEGER := 4);
        PORT(
            i_resetBar    : IN  STD_LOGIC; 
            i_resetCount  : IN  STD_LOGIC;
            i_load        : IN  STD_LOGIC;  
            i_clock       : IN  STD_LOGIC;
            o_Value       : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    COMPONENT debouncer
        PORT(
            i_raw                 : IN  STD_LOGIC;
            i_clock               : IN  STD_LOGIC;
            o_clean               : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT nBitMux4to1
        GENERIC(n : INTEGER := 4);
        PORT(
            s0, s1                : IN  STD_LOGIC;
            x0, x1, x2, x3        : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            y                     : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    END COMPONENT;
	
    COMPONENT nBitMux2to1
        GENERIC(n: INTEGER := 4);
        PORT(
            i_sel       : IN  STD_LOGIC;
            i_d0, i_d1  : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            o_q         : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    END COMPONENT;
  
    COMPONENT fsmController
        PORT(
            CounterReachedMax     : IN  STD_LOGIC;
            SSCS                  : IN  STD_LOGIC;
            G_Clock               : IN  STD_LOGIC;
            G_Reset               : IN  STD_LOGIC;
            MSTL, SSTL            : OUT STD_LOGIC_VECTOR(2 downto 0);
            sA, sB, sC, sD        : OUT STD_LOGIC;
            s0, s1                : OUT STD_LOGIC);
    END COMPONENT;
  
    COMPONENT bin4ToBCD
        PORT(
            i_binary    : IN  STD_LOGIC_VECTOR(3 downto 0);
            o_tens      : OUT STD_LOGIC_VECTOR(3 downto 0);
            o_ones      : OUT STD_LOGIC_VECTOR(3 downto 0));
    END COMPONENT;

BEGIN

    resetCount_MSC <= NOT int_sA;  
    resetCount_MST <= NOT int_sB; 
    resetCount_SSC <= NOT int_sC; 
    resetCount_SST <= NOT int_sD;
    int_SSCS_n     <= NOT int_SSCS;  


    counterMSC: nBitCounter
        GENERIC MAP(n => 4)
        PORT MAP(
            i_resetBar   => G_Reset,      
            i_resetCount => resetCount_MSC,
            i_load       => '1',    
            i_clock      => G_Clock,
            o_Value      => int_MSC
        );

    timerMST: nBitCounter
        GENERIC MAP(n => 4)
        PORT MAP(
            i_resetBar   => G_Reset,
            i_resetCount => resetCount_MST,
            i_load       => '1',
            i_clock      => G_Clock,
            o_Value      => int_MST
        );

    counterSSC: nBitCounter
        GENERIC MAP(n => 4)
        PORT MAP(
            i_resetBar   => G_Reset,
            i_resetCount => resetCount_SSC,
            i_load       => '1',
            i_clock      => G_Clock,
            o_Value      => int_SSC
        );

    timerSST: nBitCounter
        GENERIC MAP(n => 4)
        PORT MAP(
            i_resetBar   => G_Reset,
            i_resetCount => resetCount_SST,
            i_load       => '1',
            i_clock      => G_Clock,
            o_Value      => int_SST
        );

    counterMux: nBitMux4to1
        GENERIC MAP(n => 4)
        PORT MAP(
            s0 => int_s0,
            s1 => int_s1,
            x0 => int_MSC, 
            x1 => int_MST, 
            x2 => int_SSC, 
            x3 => int_SST,  
            y  => muxCounter
        );

    maxMux: nBitMux4to1
        GENERIC MAP(n => 4)
        PORT MAP(
            s0 => int_s0,
            s1 => int_s1,
            x0 => MSC,   
            x1 => MST_MAX,  
            x2 => SSC,   
            x3 => SST_MAX,
            y  => muxMax
        );

    comparator: nBitComparator
        GENERIC MAP(n => 4)
        PORT MAP(
            i_Ai => muxCounter,
            i_Bi => muxMax,
            o_GT => open,
            o_LT => open,
            o_EQ => int_Compare
        );

    controller: fsmController
        PORT MAP(
            CounterReachedMax => int_Compare,
            SSCS              => int_SSCS_n,
            G_Clock           => G_Clock,
            G_Reset           => G_Reset,
            MSTL              => MSTL,
            SSTL              => SSTL,
            sA                => int_sA,
            sB                => int_sB,
            sC                => int_sC,
            sD                => int_sD,
            s0                => int_s0,
            s1                => int_s1
        );

    sscsDebounce: debouncer
        PORT MAP(
            i_raw   => SSCS,
            i_clock => G_Clock,
            o_clean => int_SSCS
        );
	 
    bcdMux: nBitMux2to1
        GENERIC MAP(n => 4)
        PORT MAP(
            i_sel  => int_s1,
            i_d0   => int_MSC,
            i_d1   => int_SSC,
            o_q    => bcd_input
        );

    bcdConverter: bin4ToBCD
        PORT MAP(
            i_binary => bcd_input,
            o_tens   => BCD1,
            o_ones   => BCD2
        );

    TL_State(0) <= int_s0;
    TL_State(1) <= int_s1;

END structural;