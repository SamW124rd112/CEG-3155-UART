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

    -- Signals for main counter (divide by 40)
    SIGNAL count_40                     : STD_LOGIC_VECTOR(5 downto 0);
    SIGNAL compare_value_40             : STD_LOGIC_VECTOR(5 downto 0);
    SIGNAL tc_40                        : STD_LOGIC;
    
    -- Signals for fast counter (divide by 5)
    SIGNAL count_5                      : STD_LOGIC_VECTOR(2 downto 0);
    SIGNAL compare_value_5              : STD_LOGIC_VECTOR(2 downto 0);
    SIGNAL tc_5                         : STD_LOGIC;
    
    -- Main divider chain (for baudClk)
    SIGNAL div80_q, div80_qBar          : STD_LOGIC;
    SIGNAL div_chain_q, div_chain_qBar  : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Fast divider chain (for BClkD8)
    SIGNAL div10_q, div10_qBar          : STD_LOGIC;
    SIGNAL fast_chain_q, fast_chain_qBar: STD_LOGIC_VECTOR(7 downto 0);
    
    SIGNAL BClk_int                     : STD_LOGIC;
    SIGNAL t_high                       : STD_LOGIC;
    SIGNAL o_GT_40, o_LT_40             : STD_LOGIC;
    SIGNAL o_GT_5, o_LT_5               : STD_LOGIC;

BEGIN

    t_high          <= '1';
    compare_value_40 <= "101000";  -- 40 in binary (count 0-40 = 41 states)
    compare_value_5  <= "100";     -- 4 in binary (count 0-4 = 5 states)

    ---------------------------------------------------------------------------
    -- MAIN COUNTER: Divides by 40 (for baudClk generation)
    ---------------------------------------------------------------------------
    counter40: nBitCounter
        GENERIC MAP(n => 6)
        PORT MAP(
            i_resetBar    => G_Reset,
            i_resetCount  => tc_40,
            i_load        => '1',
            i_clock       => in_Clock,
            o_Value       => count_40
        );

    comp40: nBitComparator
        GENERIC MAP(n => 6)
        PORT MAP(
            i_Ai  => count_40,
            i_Bi  => compare_value_40,
            o_GT  => o_GT_40,
            o_LT  => o_LT_40,
            o_EQ  => tc_40
        );

    -- TFF for divide by 80 (40 * 2)
    TFF_DIV80: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => tc_40,
            o_q        => div80_q,
            o_qBar     => div80_qBar
        );

    -- Main TFF chain for baudClk
    TFF0: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div80_q,
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

    ---------------------------------------------------------------------------
    -- FAST COUNTER: Divides by 5 (for BClkD8 generation)
    -- Since 40 = 8 * 5, this gives exact 8:1 ratio
    ---------------------------------------------------------------------------
    counter5: nBitCounter
        GENERIC MAP(n => 3)
        PORT MAP(
            i_resetBar    => G_Reset,
            i_resetCount  => tc_5,
            i_load        => '1',
            i_clock       => in_Clock,
            o_Value       => count_5
        );

    comp5: nBitComparator
        GENERIC MAP(n => 3)
        PORT MAP(
            i_Ai  => count_5,
            i_Bi  => compare_value_5,
            o_GT  => o_GT_5,
            o_LT  => o_LT_5,
            o_EQ  => tc_5
        );

    -- TFF for divide by 10 (5 * 2)
    TFF_DIV10: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => tc_5,
            o_q        => div10_q,
            o_qBar     => div10_qBar
        );

    -- Fast TFF chain for BClkD8
    TFF_FAST0: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,
            i_t        => t_high,
            i_clock    => div10_q,
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

    ---------------------------------------------------------------------------
    -- BAUD CLOCK MUX: Selects from main divider chain
    ---------------------------------------------------------------------------
    MUX_BAUD: oneBitMux8to1
        PORT MAP(
            s0 => SEL(0), 
            s1 => SEL(1), 
            s2 => SEL(2),                  
            x0 => div_chain_q(0),   -- 3200 ns  (fastest)
            x1 => div_chain_q(1),   -- 6400 ns
            x2 => div_chain_q(2),   -- 12800 ns
            x3 => div_chain_q(3),   -- 25600 ns
            x4 => div_chain_q(4),   -- 51200 ns
            x5 => div_chain_q(5),   -- 102400 ns
            x6 => div_chain_q(6),   -- 204800 ns
            x7 => div_chain_q(7),   -- 409600 ns (slowest)
            y  => BClk_int
        );

    baudClk <= BClk_int;

    ---------------------------------------------------------------------------
    -- BCLKD8 MUX: Selects from fast divider chain (exactly 8x faster)
    ---------------------------------------------------------------------------
    MUX_BCLKD8: oneBitMux8to1
        PORT MAP(
            s0 => SEL(0), 
            s1 => SEL(1), 
            s2 => SEL(2),                  
            x0 => fast_chain_q(0),  -- 400 ns   = 3200/8  ✓
            x1 => fast_chain_q(1),  -- 800 ns   = 6400/8  ✓
            x2 => fast_chain_q(2),  -- 1600 ns  = 12800/8 ✓
            x3 => fast_chain_q(3),  -- 3200 ns  = 25600/8 ✓
            x4 => fast_chain_q(4),  -- 6400 ns  = 51200/8 ✓
            x5 => fast_chain_q(5),  -- 12800 ns = 102400/8 ✓
            x6 => fast_chain_q(6),  -- 25600 ns = 204800/8 ✓
            x7 => fast_chain_q(7),  -- 51200 ns = 409600/8 ✓
            y  => BClkD8
        );

END structural;
