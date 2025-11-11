
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_nBitMux2to1 IS
END tb_nBitMux2to1;

ARCHITECTURE behavior OF tb_nBitMux2to1 IS
  -- Generic parameter for the width of input vectors
  CONSTANT n : INTEGER := 4;

  -- Input signals for the DUT
  SIGNAL i_sel : std_logic := '0';
  SIGNAL i_d0, i_d1 : std_logic_vector(n-1 DOWNTO 0) := (others => '0');

  -- Output signal from the DUT
  SIGNAL o_q : std_logic_vector(n-1 DOWNTO 0);

  -- Component declaration matching the entity
  COMPONENT nBitMux2to1
    GENERIC (n : INTEGER := 4);
    PORT (
      i_sel : IN std_logic;
      i_d0, i_d1 : IN std_logic_vector(n-1 DOWNTO 0);
      o_q : OUT std_logic_vector(n-1 DOWNTO 0)
    );
  END COMPONENT;

BEGIN

  -- Instantiate the DUT
  DUT: nBitMux2to1
    GENERIC MAP (n => n)
    PORT MAP (
      i_sel => i_sel,
      i_d0 => i_d0,
      i_d1 => i_d1,
      o_q => o_q
    );

  -- Stimulus process
  stim_proc: PROCESS
  BEGIN
    -- Test input 1: Select i_d0
    i_d0 <= "1010";
    i_d1 <= "0101";
    i_sel <= '0';
    WAIT FOR 20 ns;

    -- Test input 2: Select i_d1
    i_sel <= '1';
    WAIT FOR 20 ns;

    -- Test input 3: Change inputs, select i_d0
    i_d0 <= "1111";
    i_d1 <= "0000";
    i_sel <= '0';
    WAIT FOR 20 ns;

    -- Test input 4: select i_d1
    i_sel <= '1';
    WAIT FOR 20 ns;

    WAIT; -- wait forever to finish simulation
  END PROCESS;

END behavior;
