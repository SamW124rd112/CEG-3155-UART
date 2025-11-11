LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_nBitLeftShiftRegister IS
END tb_nBitLeftShiftRegister;

ARCHITECTURE behavior OF tb_nBitLeftShiftRegister IS
	
	-- Component Declaration
	COMPONENT nBitLeftShiftRegister
		GENERIC(n : INTEGER := 8);
		PORT(
			i_resetBar, i_load : IN STD_LOGIC;
			i_clock    : IN STD_LOGIC;
			i_Value    : IN STD_LOGIC;
			o_Value    : OUT STD_LOGIC_VECTOR(n-1 downto 0));
	END COMPONENT;
	
	-- Testbench signals
	SIGNAL tb_resetBar : STD_LOGIC := '0';
	SIGNAL tb_load     : STD_LOGIC := '0';
	SIGNAL tb_clock    : STD_LOGIC := '0';
	SIGNAL tb_Value    : STD_LOGIC := '0';
	SIGNAL tb_output   : STD_LOGIC_VECTOR(7 downto 0);
	
	-- Clock period
	CONSTANT clk_period : TIME := 10 ns;
	
BEGIN
	
	-- Instantiate Unit Under Test (UUT)
	UUT: nBitLeftShiftRegister
		GENERIC MAP (n => 8)
		PORT MAP (
			i_resetBar => tb_resetBar,
			i_load     => tb_load,
			i_clock    => tb_clock,
			i_Value    => tb_Value,
			o_Value    => tb_output);
	
	-- Clock process
	clk_process: PROCESS
	BEGIN
		tb_clock <= '0';
		WAIT FOR clk_period/2;
		tb_clock <= '1';
		WAIT FOR clk_period/2;
	END PROCESS;
	
	-- Stimulus process
	stim_process: PROCESS
	BEGIN
		-- Initial reset
		tb_resetBar <= '0';
		tb_load     <= '0';
		tb_Value    <= '0';
		WAIT FOR clk_period*2;
		
		-- Release reset
		tb_resetBar <= '1';
		WAIT FOR clk_period;
		
		-- Enable shifting and shift in pattern 10110001
		tb_load <= '1';
		
		tb_Value <= '1';  -- Shift in 1
		WAIT FOR clk_period;
		
		tb_Value <= '0';  -- Shift in 0
		WAIT FOR clk_period;
		
		tb_Value <= '0';  -- Shift in 0
		WAIT FOR clk_period;
		
		tb_Value <= '0';  -- Shift in 0
		WAIT FOR clk_period;
		
		tb_Value <= '1';  -- Shift in 1
		WAIT FOR clk_period;
		
		tb_Value <= '1';  -- Shift in 1
		WAIT FOR clk_period;
		
		tb_Value <= '0';  -- Shift in 0
		WAIT FOR clk_period;
		
		tb_Value <= '1';  -- Shift in 1
		WAIT FOR clk_period;
		-- After 8 shifts, should have: 10110001
		
		-- Continue shifting
		tb_Value <= '0';
		WAIT FOR clk_period*4;
		
		-- Disable shifting
		tb_load <= '0';
		tb_Value <= '1';
		WAIT FOR clk_period*3;
		-- Value should remain stable
		
		-- Test reset
		tb_resetBar <= '0';
		WAIT FOR clk_period*2;
		-- Should be all zeros
		
		REPORT "Testbench completed successfully!";
		WAIT;
	END PROCESS;
	
END behavior;
