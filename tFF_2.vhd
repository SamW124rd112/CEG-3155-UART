--------------------------------------------------------------------------------
-- Title         : Type T Flip-Flop - 2nd realization
-- Project       : VHDL Synthesis Overview
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tFF_2 IS
	PORT(
		i_resetBar	: IN	STD_LOGIC;  -- ADDED: Active low reset
		i_t			: IN	STD_LOGIC;
		i_clock		: IN	STD_LOGIC;
		o_q, o_qBar	: OUT	STD_LOGIC);
END tFF_2;

ARCHITECTURE rtl OF tFF_2 IS
	SIGNAL int_q         : STD_LOGIC := '0';    
	SIGNAL int_qBar      : STD_LOGIC := '1';    
	SIGNAL int_muxOutput : STD_LOGIC;
	SIGNAL enable_high   : STD_LOGIC := '1';

	COMPONENT enARdFF_2
		PORT(
			i_resetBar  : IN  STD_LOGIC;
			i_d         : IN  STD_LOGIC;
			i_enable    : IN  STD_LOGIC;
			i_clock     : IN  STD_LOGIC;
			o_q, o_qBar : OUT STD_LOGIC);
	END COMPONENT;

BEGIN

dFlipFlop: enARdFF_2
	PORT MAP (
			  i_resetBar => i_resetBar,  -- Connect reset
			  i_d        => int_muxOutput, 
			  i_enable   => enable_high,  -- Always enabled
			  i_clock    => i_clock,
			  o_q        => int_q,
	          o_qBar     => int_qBar);

int_muxOutput	<=	int_q when i_t = '0' else
					int_qBar;

	-- Output Driver
	o_q	<= int_q;
	o_qBar	<= int_qBar;

END rtl;
