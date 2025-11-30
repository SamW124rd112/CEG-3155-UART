LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY trafficLightController IS
    PORT(
        MSC, SSC              : IN  STD_LOGIC_VECTOR(3 downto 0);
        SSCS                  : IN  STD_LOGIC;
        G_Clock               : IN  STD_LOGIC;
        G_Reset               : IN  STD_LOGIC;
        MSTL, SSTL            : OUT STD_LOGIC_VECTOR(2 downto 0);
		  BCD1, BCD2              : OUT STD_LOGIC_VECTOR(3 downto 0);  -- Added BCD outputs
      TL_State                : OUT STD_LOGIC_VECTOR(1 downto 0));

END trafficLightController;

ARCHITECTURE structural OF trafficLightController IS
  -- Constants for yellow light timing (fixed values)
  CONSTANT MST_MAX : STD_LOGIC_VECTOR(3 downto 0) := "0101"; -- 5 seconds
  CONSTANT SST_MAX : STD_LOGIC_VECTOR(3 downto 0) := "0011"; -- 3 seconds

  SIGNAL int_SSCS, int_SSCS_n, int_Compare : STD_LOGIC;
  SIGNAL int_s0, int_s1 : STD_LOGIC;
  SIGNAL int_sA, int_sB, int_sC, int_sD : STD_LOGIC;
  SIGNAL int_MST, int_SST, int_MSC, int_SSC : STD_LOGIC_VECTOR(3 downto 0);
  SIGNAL muxCounter, muxMax : STD_LOGIC_VECTOR(3 downto 0);
  
  -- Combined reset signals
  SIGNAL reset_MSC, reset_MST, reset_SSC, reset_SST : STD_LOGIC;
  
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
      i_resetBar, i_load    : IN  STD_LOGIC;
      i_clock               : IN  STD_LOGIC;
      o_Value               : OUT STD_LOGIC_VECTOR(n-1 downto 0));
  END COMPONENT;

  COMPONENT debouncer
    PORT(
      i_raw                 : IN  STD_LOGIC;
      i_clock               : IN  STD_LOGIC;
      o_clean               : OUT STD_LOGIC);
  END COMPONENT;

  COMPONENT clk_div
    PORT(
      clock_25Mhz           : IN  STD_LOGIC;
      clock_1MHz            : OUT STD_LOGIC;
      clock_100KHz          : OUT STD_LOGIC;
      clock_10KHz           : OUT STD_LOGIC;
      clock_1KHz            : OUT STD_LOGIC;
      clock_100Hz           : OUT STD_LOGIC;
      clock_10Hz            : OUT STD_LOGIC;
      clock_1Hz             : OUT STD_LOGIC);
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
      CounterReachedMax        : IN  STD_LOGIC;
      SSCS                    : IN  STD_LOGIC;
      G_Clock                 : IN  STD_LOGIC;
      G_Reset                 : IN  STD_LOGIC;
      MSTL, SSTL              : OUT STD_LOGIC_VECTOR(2 downto 0);
      sA, sB, sC, sD          : OUT STD_LOGIC;
      s0, s1                  : OUT STD_LOGIC);
  END COMPONENT;
  
  COMPONENT bin4ToBCD
    PORT(
      i_binary    : IN  STD_LOGIC_VECTOR(3 downto 0);
      o_tens      : OUT STD_LOGIC_VECTOR(3 downto 0);
      o_ones      : OUT STD_LOGIC_VECTOR(3 downto 0));
  END COMPONENT;

BEGIN

  int_SSCS_n <= NOT int_SSCS;

  -- Combine global reset with state-based reset
  -- Active low: '0' means reset, '1' means operate
  reset_MSC <= G_Reset AND int_sA;  -- Reset when G_Reset=0 OR not in state A
  reset_MST <= G_Reset AND int_sB;  -- Reset when G_Reset=0 OR not in state B
  reset_SSC <= G_Reset AND int_sC;  -- Reset when G_Reset=0 OR not in state C
  reset_SST <= G_Reset AND int_sD;  -- Reset when G_Reset=0 OR not in state D

  -- Clock Divider

  -- Main Street Green Counter (active only in state A)
  counterMSC: nBitCounter
    GENERIC MAP(n => 4)
    PORT MAP(
      i_resetBar  => reset_MSC,      -- Combined reset
      i_load      => int_sA,         -- Count only when in state A
      i_clock     => G_Clock,
      o_Value     => int_MSC
    );

  -- Main Street Yellow Timer (active only in state B)
  timerMST: nBitCounter
    GENERIC MAP(n => 4)
    PORT MAP(
      i_resetBar  => reset_MST,      -- Combined reset
      i_load      => int_sB,         -- Count only when in state B
      i_clock     => G_Clock,
      o_Value     => int_MST
    );

  -- Side Street Green Counter (active only in state C)
  counterSSC: nBitCounter
    GENERIC MAP(n => 4)
    PORT MAP(
      i_resetBar  => reset_SSC,      -- Combined reset
      i_load      => int_sC,         -- Count only when in state C
      i_clock     => G_Clock,
      o_Value     => int_SSC
    );

  -- Side Street Yellow Timer (active only in state D)
  timerSST: nBitCounter
    GENERIC MAP(n => 4)
    PORT MAP(
      i_resetBar  => reset_SST,      -- Combined reset
      i_load      => int_sD,         -- Count only when in state D
      i_clock     => G_Clock,
      o_Value     => int_SST
    );

  -- 4-to-1 MUX for selecting current counter value
  counterMux: nBitMux4to1
    GENERIC MAP(n => 4)
    PORT MAP(
      s0 => int_s0,
      s1 => int_s1,
      x0 => int_MSC,  -- State A (00)
      x1 => int_MST,  -- State B (01)
      x2 => int_SSC,  -- State C (10)
      x3 => int_SST,  -- State D (11)
      y  => muxCounter
    );

  -- 4-to-1 MUX for selecting maximum/target value
  maxMux: nBitMux4to1
    GENERIC MAP(n => 4)
    PORT MAP(
      s0 => int_s0,
      s1 => int_s1,
      x0 => MSC,      -- State A (00) - programmable MS green
      x1 => MST_MAX,  -- State B (01) - fixed MS yellow (5 sec)
      x2 => SSC,      -- State C (10) - programmable SS green
      x3 => SST_MAX,  -- State D (11) - fixed SS yellow (3 sec)
      y  => muxMax
    );

  -- Comparator checks if current counter reached max value
  comparator: nBitComparator
    GENERIC MAP(n => 4)
    PORT MAP(
      i_Ai => muxCounter,
      i_Bi => muxMax,
      o_GT => open,
      o_LT => open,
      o_EQ => int_Compare
    );

  -- FSM Controller
  controller: fsmController
    PORT MAP(
      CounterReachedMax => int_Compare,
      SSCS             => int_SSCS_n,
      G_Clock          => G_Clock,
      G_Reset          => G_Reset,
      MSTL             => MSTL,
      SSTL             => SSTL,
      sA               => int_sA,
      sB               => int_sB,
      sC               => int_sC,
      sD               => int_sD,
      s0               => int_s0,
      s1               => int_s1
    );

  -- Debounce car sensor
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
      i_d0   => int_MSC,    -- Main street counter
      i_d1   => int_SSC,    -- Side street counter
      o_q    => bcd_input
    );

  -- Convert binary counter to BCD (tens and ones digits)
  bcdConverter: bin4ToBCD
    PORT MAP(
      i_binary => bcd_input,
      o_tens   => BCD1,     -- Left digit (tens place)
      o_ones   => BCD2      -- Right digit (ones place)
    );

  TL_State(0) <= int_s0;
  TL_State(1) <= int_s1;

END structural;