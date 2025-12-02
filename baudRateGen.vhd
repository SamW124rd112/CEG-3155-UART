LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY baudRateGen IS
    PORT(
        SEL               : IN  STD_LOGIC_VECTOR(2 downto 0);
        in_Clock          : IN  STD_LOGIC;
        G_Reset           : IN  STD_LOGIC;
        baudClk           : OUT STD_LOGIC;
        BClkD8            : OUT STD_LOGIC
    );
END baudRateGen;

ARCHITECTURE structural OF baudRateGen IS 

    COMPONENT nBitCounter
        GENERIC(n : INTEGER := 4);
        PORT(
            i_resetBar   : IN  STD_LOGIC;
            i_resetCount : IN  STD_LOGIC;
            i_load       : IN  STD_LOGIC;
            i_clock      : IN  STD_LOGIC;
            o_Value      : OUT STD_LOGIC_VECTOR(n-1 downto 0)
        );
    END COMPONENT;

    COMPONENT tFF_2 
        PORT(
            i_resetBar    : IN  STD_LOGIC;
            i_t           : IN  STD_LOGIC;
            i_clock       : IN  STD_LOGIC;
            o_q, o_qBar   : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT oneBitMux8to1 
        PORT(
            s0, s1, s2                      : IN STD_LOGIC;
            x0, x1, x2, x3, x4, x5, x6, x7  : IN STD_LOGIC;
            y                               : OUT STD_LOGIC
        );
    END COMPONENT; 

    COMPONENT nBitComparator
        GENERIC(n: INTEGER := 4);
        PORT(
            i_Ai, i_Bi       : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            o_GT, o_LT, o_EQ : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL count_80                     : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL compare_value_80             : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL tc_80                        : STD_LOGIC;

    SIGNAL count_10                     : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL compare_value_10             : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL tc_10                        : STD_LOGIC;
 
    SIGNAL div160_q, div160_qBar        : STD_LOGIC;
    SIGNAL div_chain_q, div_chain_qBar  : STD_LOGIC_VECTOR(7 downto 0);

    SIGNAL div20_q, div20_qBar          : STD_LOGIC;
    SIGNAL fast_chain_q, fast_chain_qBar: STD_LOGIC_VECTOR(7 downto 0);
    
    SIGNAL BClk_int                     : STD_LOGIC;
    SIGNAL t_high                       : STD_LOGIC;
    SIGNAL o_GT_80, o_LT_80             : STD_LOGIC;
    SIGNAL o_GT_10, o_LT_10             : STD_LOGIC;

BEGIN

    t_high           <= '1';
    compare_value_80 <= "1001111"; 
    compare_value_10 <= "1001";  

    counter80: nBitCounter
        GENERIC MAP(n => 7)
        PORT MAP(
            i_resetBar    => G_Reset,
            i_resetCount  => tc_80,
            i_load        => '1',
            i_clock       => in_Clock,
            o_Value       => count_80
        );

    comp80: nBitComparator
        GENERIC MAP(n => 7)
        PORT MAP(
            i_Ai  => count_80,
            i_Bi  => compare_value_80,
            o_GT  => o_GT_80,
            o_LT  => o_LT_80,
            o_EQ  => tc_80
        );

    TFF_DIV160: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => tc_80,
            o_q        => div160_q,
            o_qBar     => div160_qBar
        );

    TFF0: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div160_q,
            o_q        => div_chain_q(0),
            o_qBar     => div_chain_qBar(0)
        );
    
    TFF1: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(0),
            o_q        => div_chain_q(1),
            o_qBar     => div_chain_qBar(1)
        );
    
    TFF2: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(1),
            o_q        => div_chain_q(2),
            o_qBar     => div_chain_qBar(2)
        );
    
    TFF3: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(2),
            o_q        => div_chain_q(3),
            o_qBar     => div_chain_qBar(3)
        );
    
    TFF4: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(3),
            o_q        => div_chain_q(4),
            o_qBar     => div_chain_qBar(4)
        );
    
    TFF5: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(4),
            o_q        => div_chain_q(5),
            o_qBar     => div_chain_qBar(5)
        );
    
    TFF6: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(5),
            o_q        => div_chain_q(6),
            o_qBar     => div_chain_qBar(6)
        );
    
    TFF7: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div_chain_q(6),
            o_q        => div_chain_q(7),
            o_qBar     => div_chain_qBar(7)
        );


    counter10: nBitCounter
        GENERIC MAP(n => 4)
        PORT MAP(
            i_resetBar    => G_Reset,
            i_resetCount  => tc_10,
            i_load        => '1',
            i_clock       => in_Clock,
            o_Value       => count_10
        );

    comp10: nBitComparator
        GENERIC MAP(n => 4)
        PORT MAP(
            i_Ai  => count_10,
            i_Bi  => compare_value_10,
            o_GT  => o_GT_10,
            o_LT  => o_LT_10,
            o_EQ  => tc_10
        );

    TFF_DIV20: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => tc_10,
            o_q        => div20_q,
            o_qBar     => div20_qBar
        );

    TFF_FAST0: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div20_q,
            o_q        => fast_chain_q(0),
            o_qBar     => fast_chain_qBar(0)
        );
    
    TFF_FAST1: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(0),
            o_q        => fast_chain_q(1),
            o_qBar     => fast_chain_qBar(1)
        );
    
    TFF_FAST2: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(1),
            o_q        => fast_chain_q(2),
            o_qBar     => fast_chain_qBar(2)
        );
    
    TFF_FAST3: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(2),
            o_q        => fast_chain_q(3),
            o_qBar     => fast_chain_qBar(3)
        );
    
    TFF_FAST4: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(3),
            o_q        => fast_chain_q(4),
            o_qBar     => fast_chain_qBar(4)
        );
    
    TFF_FAST5: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(4),
            o_q        => fast_chain_q(5),
            o_qBar     => fast_chain_qBar(5)
        );
    
    TFF_FAST6: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(5),
            o_q        => fast_chain_q(6),
            o_qBar     => fast_chain_qBar(6)
        );
    
    TFF_FAST7: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => fast_chain_q(6),
            o_q        => fast_chain_q(7),
            o_qBar     => fast_chain_qBar(7)
        );


    MUX_BAUD: oneBitMux8to1
        PORT MAP(
            s0 => SEL(0), 
            s1 => SEL(1), 
            s2 => SEL(2),                  
            x0 => div_chain_q(0), 
            x1 => div_chain_q(1), 
            x2 => div_chain_q(2),  
            x3 => div_chain_q(3), 
            x4 => div_chain_q(4),  
            x5 => div_chain_q(5),  
            x6 => div_chain_q(6),  
            x7 => div_chain_q(7),  
            y  => BClk_int
        );

    baudClk <= BClk_int;


    MUX_BCLKD8: oneBitMux8to1
        PORT MAP(
            s0 => SEL(0), 
            s1 => SEL(1), 
            s2 => SEL(2),                  
            x0 => fast_chain_q(0),  
            x1 => fast_chain_q(1), 
            x2 => fast_chain_q(2), 
            x3 => fast_chain_q(3),  
            x4 => fast_chain_q(4),
            x5 => fast_chain_q(5), 
            x6 => fast_chain_q(6), 
            x7 => fast_chain_q(7),   
            y  => BClkD8
        );

END structural;