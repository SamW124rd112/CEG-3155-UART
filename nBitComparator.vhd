LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitComparator IS
	PORT(
    GENERIC(n: INTEGER := 4);
		i_Ai, i_Bi			      : IN	STD_LOGIC_VECTOR(n-1 downto 0);
		o_GT, o_LT, o_EQ			: OUT	STD_LOGIC);
END nBitComparator;

ARCHITECTURE rtl OF nBitComparator IS
  SIGNAL n_LT, n_GT: STD_LOGIC_VECTOR(n-1 downto 0)


  COMPONENT oneBitComparator IS
    PORT(
      i_GTPrevious, i_LTPrevious	: IN	STD_LOGIC;
      i_Ai, i_Bi			: IN	STD_LOGIC;
      o_GT, o_LT			: OUT	STD_LOGIC);
  END COMPONENT oneBitComparator;
BEGIN

  MSBComparator: oneBitComparator
    PORT MAP(
      i_GTPrevious => '0',
      i_LTPrevious => '0',
      i_Ai => i_Ai(n-1),
      i_Bi => i_Ai(n-1),
      o_GT => n_GT(n-1),
      o_LT => n_LT(n-1)
    );

  loop_comp: FOR i IN 1 to n-2 GENERATE
    n_comp: oneBitComparator
      PORT MAP(
        i_GTPrevious => n_GT(i+1),
        i_LTPrevious => n_LT(i+1),
        i_Ai => i_Ai(i),
        i_Bi => i_Ai(i),
        o_GT => n_GT(i),
        o_LT => n_LT(i)
      );
  END GENERATE;

  o_GT <= n_GT(0)
  o_LT <= n_LT(0)
  o_EQ <= n_GT(0) nor n_LT(0);

END rtl;

