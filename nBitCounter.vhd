LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitCounter IS
  GENERIC(n : INTEGER := 4)
	PORT(
		i_resetBar, i_load	: IN	STD_LOGIC;
		i_clock			        : IN	STD_LOGIC;
		o_Value			        : OUT	STD_LOGIC_VECTOR(n-1 downto 0));
END nBitCounter;

ARCHITECTURE rtl OF nBitCounter IS
  SIGNAL int_q    : STD_LOGIC_VECTOR(n-1 downto 0);
	SIGNAL int_qBar : STD_LOGIC_VECTOR(n-1 downto 0);
  SIGNAL int_d    : STD_LOGIC_VECTOR(n-1 downto 0);

	COMPONENT enARdFF_2
		PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d		: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;

BEGIN
  
  int_d(0) <= not int_q(0);
  GEN_XOR: FOR i IN 1 TO n-1 GENERATE
    int_d(i) <= int_q(i) XOR int_q(i-1);
  END GENERATE;


  counterFF: FOR i in 0 TO n-1 GENERATE
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

