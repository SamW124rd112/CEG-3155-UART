LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitRightShiftRegister IS
	GENERIC(n : INTEGER := 8); 
	PORT(
		i_resetBar, i_load  : IN STD_LOGIC;
		i_enable            : IN STD_LOGIC; 
		i_clock             : IN STD_LOGIC;
		i_loadValue         : IN STD_LOGIC_VECTOR(n-1 downto 0);  
		i_shiftIn           : IN STD_LOGIC;  
		o_Value             : OUT STD_LOGIC_VECTOR(n-1 downto 0);
		o_shiftOut          : OUT STD_LOGIC);
END nBitRightShiftRegister;

ARCHITECTURE rtl OF nBitRightShiftRegister IS
	SIGNAL int_Value, int_notValue : STD_LOGIC_VECTOR(n-1 downto 0);
	SIGNAL int_muxOut : STD_LOGIC_VECTOR(n-1 downto 0);  
	
	COMPONENT enARdff_2
		PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d			: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;

  COMPONENT oneBitMux2to1 
    PORT (  
      s, x0, x1   : IN    STD_LOGIC ;
      y           : OUT   STD_LOGIC ) ;
  END COMPONENT; 


BEGIN

	MUX_MSB: oneBitMux2to1
		PORT MAP (
			x0 => i_shiftIn,           -- Shift mode: take serial input
			x1 => i_loadValue(n-1),    -- Load mode: take parallel input
			s => i_load,
			y => int_muxOut(n-1));
	
	FF_MSB: enARdFF_2
		PORT MAP (
			i_resetBar => i_resetBar,
			i_d => int_muxOut(n-1),
			i_enable => i_enable,
			i_clock => i_clock,
			o_q => int_Value(n-1),
			o_qBar => int_notValue(n-1));

	-- Remaining bits (n-2 down to 0): Mux selects between parallel load and cascade from higher bit
	GEN_SHIFT: FOR i IN n-2 DOWNTO 0 GENERATE
		MUX_BIT: oneBitMux2to1
			PORT MAP (
				x0 => int_Value(i+1),      -- Shift mode: cascade from higher bit
				x1 => i_loadValue(i),      -- Load mode: take parallel input
				s => i_load,
				y => int_muxOut(i));
		
		FF_BIT: enARdFF_2
			PORT MAP (
				i_resetBar => i_resetBar,
				i_d => int_muxOut(i),
				i_enable => i_enable,
				i_clock => i_clock,
				o_q => int_Value(i),
				o_qBar => int_notValue(i));
	END GENERATE GEN_SHIFT;
				 
	-- Output assignments
	o_Value <= int_Value;
	o_shiftOut <= int_Value(0);

END rtl;
