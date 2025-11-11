LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitLeftShiftRegister IS
	GENERIC(n : INTEGER := 8);
	PORT(
		i_resetBar, i_load	: IN	STD_LOGIC;
		i_clock			: IN	STD_LOGIC;
		i_Value			: IN	STD_LOGIC;
		o_Value			: OUT	STD_LOGIC_VECTOR(n-1 downto 0));
END nBitLeftShiftRegister;

ARCHITECTURE rtl OF nBitLeftShiftRegister IS
	SIGNAL int_Value, int_notValue : STD_LOGIC_VECTOR(n-1 downto 0);  -- Fixed!
	
	COMPONENT enARdFF_2
		PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d		: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;

BEGIN

	LSB: enARdFF_2
		PORT MAP (
			i_resetBar => i_resetBar,
			i_d => i_Value,           -- External input
			i_enable => i_load,
			i_clock => i_clock,
			o_q => int_Value(0),      -- Outputs to bit 0
			o_qBar => int_notValue(0));

	-- Remaining bits: each takes value from previous (lower) bit
	GEN_SHIFT: FOR i IN 1 TO n-1 GENERATE
		SHIFT_FF : enARdFF_2
			PORT MAP (
				i_resetBar => i_resetBar,
				i_d => int_Value(i-1),    -- Input from lower bit
				i_enable => i_load,
				i_clock => i_clock,
				o_q => int_Value(i),      -- Output to current bit
				o_qBar => int_notValue(i));
	END GENERATE GEN_SHIFT;

	-- Output Driver
	o_Value <= int_Value;

END rtl;
