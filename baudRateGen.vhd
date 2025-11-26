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
      i_resetBar    : IN  STD_LOGIC;  -- MODIFIED: Added reset
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

  SIGNAL count_41                       : STD_LOGIC_VECTOR(5 downto 0);
  SIGNAL compare_value                  : STD_LOGIC_VECTOR(5 downto 0);
  SIGNAL tc_41                          : STD_LOGIC;
  SIGNAL div82_q, div82_qBar            : STD_LOGIC;
  SIGNAL div_chain_q, div_chain_qBar    : STD_LOGIC_VECTOR(7 downto 0);
  SIGNAL BClk_int                       : STD_LOGIC;
  SIGNAL div8_q, div8_qBar              : STD_LOGIC_VECTOR(2 downto 0);
  SIGNAL t_high                         : STD_LOGIC;
  SIGNAL o_GT, o_LT                     : STD_LOGIC;

BEGIN

    t_high          <= '1';
    compare_value   <= "101000";  -- 40 in binary

    -- Counter: counts from 0 to 40 (41 states)
    counter41: nBitCounter
      GENERIC MAP(n => 6)
      PORT MAP(
          i_resetBar    => G_Reset,
          i_resetCount  => tc_41,
          i_load        => '1',
          i_clock       => in_Clock,
          o_Value       => count_41
      );

    -- Comparator: detects when count reaches 40
    comp41: nBitComparator
      GENERIC MAP(n => 6)
      PORT MAP(
          i_Ai  => count_41,
          i_Bi  => compare_value,
          o_GT  => o_GT,
          o_LT  => o_LT,
          o_EQ  => tc_41
      );

    -- TFF for divide by 82 (41 * 2)
    TFF_DIV82: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => tc_41,
            o_q        => div82_q,
            o_qBar     => div82_qBar
        );

    -- TFF0: ÷2 (clocked by div82 output)
    TFF0: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div82_q,
            o_q        => div_chain_q(0),
            o_qBar     => div_chain_qBar(0)
        );
    
    -- TFF1: ÷4
    TFF1: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(0),
            o_q        => div_chain_q(1),
            o_qBar     => div_chain_qBar(1)
        );
    
    -- TFF2: ÷8
    TFF2: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(1),
            o_q        => div_chain_q(2),
            o_qBar     => div_chain_qBar(2)
        );
    
    -- TFF3: ÷16
    TFF3: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(2),
            o_q        => div_chain_q(3),
            o_qBar     => div_chain_qBar(3)
        );
    
    -- TFF4: ÷32
    TFF4: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(3),
            o_q        => div_chain_q(4),
            o_qBar     => div_chain_qBar(4)
        );
    
    -- TFF5: ÷64
    TFF5: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(4),
            o_q        => div_chain_q(5),
            o_qBar     => div_chain_qBar(5)
        );
    
    -- TFF6: ÷128
    TFF6: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(5),
            o_q        => div_chain_q(6),
            o_qBar     => div_chain_qBar(6)
        );
    
    -- TFF7: ÷256
    TFF7: tFF_2
        PORT MAP(
            i_resetBar => G_Reset,  -- ADDED: Connect reset
            i_t        => t_high,
            i_clock    => div_chain_q(6),
            o_q        => div_chain_q(7),
            o_qBar     => div_chain_qBar(7)
        );

    -- Mux to select baud rate
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
        x0 => tc_41,              -- 3 stages before div_chain_q(0)
        x1 => tc_41,              -- 2 stages before div_chain_q(1) (using tc_41 as best option)
        x2 => div82_q,            -- 2 stages before div_chain_q(2) (closest available)
        x3 => div_chain_q(0),     -- 3 stages before div_chain_q(3) ✓
        x4 => div_chain_q(1),     -- 3 stages before div_chain_q(4) ✓
        x5 => div_chain_q(2),     -- 3 stages before div_chain_q(5) ✓
        x6 => div_chain_q(3),     -- 3 stages before div_chain_q(6) ✓
        x7 => div_chain_q(4),     -- 3 stages before div_chain_q(7) ✓
        y  => BClkD8
    );

END structural;
