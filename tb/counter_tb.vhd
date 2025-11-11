
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY counter_tb IS
END counter_tb;

ARCHITECTURE behavior OF counter_tb IS

	COMPONENT counter
		PORT(
			i_resetBar : IN STD_LOGIC;
			i_load     : IN STD_LOGIC;
			i_clock    : IN STD_LOGIC;
			o_Value    : OUT STD_LOGIC_VECTOR(1 downto 0)
		);
	END COMPONENT;

	SIGNAL i_resetBar : STD_LOGIC := '0';
	SIGNAL i_load     : STD_LOGIC := '0';
	SIGNAL i_clock    : STD_LOGIC := '0';
	SIGNAL o_Value    : STD_LOGIC_VECTOR(1 downto 0);

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	UUT: counter
		PORT MAP(
			i_resetBar => i_resetBar,
			i_load     => i_load,
			i_clock    => i_clock,
			o_Value    => o_Value
		);

	-- Clock generation 10 ns period
	clock_process : PROCESS
	BEGIN
		i_clock <= '0';
		WAIT FOR 5 ns;
		i_clock <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	-- Stimulus process
	stim_proc : PROCESS
	BEGIN
		-- Hold reset low
		i_resetBar <= '0';
		i_load <= '0';
		WAIT FOR 20 ns;

		-- Remove reset, enable counting
		i_resetBar <= '1';
		i_load <= '1';
		WAIT FOR 100 ns;

		-- Disable counting
		i_load <= '0';
		WAIT FOR 20 ns;

		-- Re-enable counting
		i_load <= '1';
		WAIT FOR 40 ns;

		WAIT;
	END PROCESS;

END behavior;
