LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitRightShiftRegister IS
	GENERIC(n : INTEGER := 8);  -- Bit width, default 8
	PORT(
		i_resetBar, i_load : IN STD_LOGIC;
		i_clock    : IN STD_LOGIC;
		i_Value    : IN STD_LOGIC;
		o_Value    : OUT STD_LOGIC_VECTOR(n-1 downto 0));
END nBitRightShiftRegister;

ARCHITECTURE rtl OF nBitRightShiftRegister IS
	SIGNAL int_Value, int_notValue : STD_LOGIC_VECTOR(n-1 downto 0);
	
	COMPONENT enARdff_2
		PORT(
		i_resetBar	: IN	STD_LOGIC;
		i_d		: IN	STD_LOGIC;
		i_enable	: IN	STD_LOGIC;
		i_clock		: IN	STD_LOGIC;
		o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;

BEGIN

	-- MSB flip-flop (bit n-1): takes external input
	MSB: enARdFF_2
		PORT MAP (
			i_resetBar => i_resetBar,
			i_d => i_Value,
			i_enable => i_load, 
			i_clock => i_clock,
			o_q => int_Value(n-1),
			o_qBar => int_notValue(n-1));
	
	-- Remaining flip-flops: cascade from higher bit
	GEN_SHIFT: FOR i IN n-2 DOWNTO 0 GENERATE
		SHIFT_FF: enARdFF_2
			PORT MAP (
				i_resetBar => i_resetBar,
				i_d => int_Value(i+1),
				i_enable => i_load, 
				i_clock => i_clock,
				o_q => int_Value(i),
				o_qBar => int_notValue(i));
	END GENERATE GEN_SHIFT;
				 
	-- Output Driver
	o_Value <= int_Value;

END rtl;
