LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitCounter IS
  GENERIC(n : INTEGER := 4);
  PORT(
    i_resetBar   : IN  STD_LOGIC;  -- Asynchronous reset (active low)
    i_resetCount : IN  STD_LOGIC;  -- Synchronous reset to 0 (active high)
    i_load       : IN  STD_LOGIC;  -- Enable counting
    i_clock      : IN  STD_LOGIC;
    o_Value      : OUT STD_LOGIC_VECTOR(n-1 downto 0));
END nBitCounter;

ARCHITECTURE rtl OF nBitCounter IS
  SIGNAL int_q        : STD_LOGIC_VECTOR(n-1 downto 0);
  SIGNAL int_qBar     : STD_LOGIC_VECTOR(n-1 downto 0);
  SIGNAL int_d        : STD_LOGIC_VECTOR(n-1 downto 0);
  SIGNAL int_countVal : STD_LOGIC_VECTOR(n-1 downto 0);
  SIGNAL int_carry    : STD_LOGIC_VECTOR(n-1 downto 0);  
  SIGNAL int_zero     : STD_LOGIC := '0';

  COMPONENT enARdFF_2
    PORT(
      i_resetBar  : IN  STD_LOGIC;
      i_d         : IN  STD_LOGIC;
      i_enable    : IN  STD_LOGIC;
      i_clock     : IN  STD_LOGIC;
      o_q, o_qBar : OUT STD_LOGIC);
  END COMPONENT;

  COMPONENT oneBitMux2to1 IS
    PORT (s, x0, x1 : IN  STD_LOGIC;
          y         : OUT STD_LOGIC);
  END COMPONENT; 

BEGIN
  
  -- Counter increment logic (CORRECTED)
  int_countVal(0) <= NOT int_q(0);
  int_carry(0)    <= int_q(0);

  GEN_INCREMENT: FOR i IN 1 TO n-1 GENERATE
    int_countVal(i) <= int_q(i) XOR int_carry(i-1);
    int_carry(i)    <= int_q(i) AND int_carry(i-1);
  END GENERATE;

  -- Mux to select between counter increment and reset to 0
  GEN_MUX: FOR i IN 0 TO n-1 GENERATE
    MUX: oneBitMux2to1
      PORT MAP(
        s  => i_resetCount,
        x0 => int_countVal(i),  -- Normal count mode (sel = 0)
        x1 => int_zero,         -- Reset to 0 (sel = 1)
        y  => int_d(i)
      );
  END GENERATE;

  -- Counter flip-flops
  counterFF: FOR i IN 0 TO n-1 GENERATE
    bFF: enARdFF_2    
    PORT MAP(
       i_resetBar => i_resetBar,
       i_d        => int_d(i),
       i_enable   => i_load, 
       i_clock    => i_clock,
       o_q        => int_q(i),
       o_qBar     => int_qBar(i)
     );
  END GENERATE;

  o_Value <= int_q;

END rtl;
