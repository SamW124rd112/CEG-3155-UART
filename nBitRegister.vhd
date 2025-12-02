LIBRARY ieee;
use ieee.std_logic_1164.ALL;

ENTITY nBitRegister IS
  GENERIC(n : INTEGER := 8);
	PORT(
		i_resetBar	: IN	STD_LOGIC;
		i_load	   : IN	STD_LOGIC;
		i_clock		: IN	STD_LOGIC;
		i_Value		: IN	STD_LOGIC_VECTOR(n-1 downto 0);
		o_Value	   : OUT	STD_LOGIC_VECTOR(n-1 downto 0));
END nBitRegister;

ARCHITECTURE rtl of nBitRegister IS

  SIGNAL int_Value    : STD_LOGIC_VECTOR(n-1 downto 0);
	SIGNAL int_notValue : STD_LOGIC_VECTOR(n-1 downto 0);

	COMPONENT enARdFF_2
			PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d		: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;

BEGIN
  GEN_REG: FOR i IN 0 TO n-1 GENERATE
		REG_FF : enARdFF_2
			PORT MAP (
				i_resetBar => i_resetBar,
				i_d => i_Value(i),
				i_enable => i_load,
				i_clock => i_clock,
				o_q => int_Value(i),
				o_qBar => int_notValue(i));
	END GENERATE GEN_REG;

  o_Value <= int_Value;
  
END rtl;
