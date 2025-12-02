LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitAddSubUnit IS
	GENERIC (n : INTEGER := 4);
	PORT(
		i_A, i_Bi	: IN	STD_LOGIC_VECTOR(n-1 downto 0);
		i_OpFlag	: IN	STD_LOGIC;
		o_CarryOut	: OUT	STD_LOGIC;
		o_Sum		: OUT	STD_LOGIC_VECTOR(n-1 downto 0));
END nBitAddSubUnit;

ARCHITECTURE rtl OF nBitAddSubUnit IS
    SIGNAL n_Sum, n_CarryOut : STD_LOGIC_VECTOR(n-1 downto 0);

    COMPONENT oneBitAddSubUnit IS
        PORT(
            i_Ai, i_Bi    : IN  STD_LOGIC;
            i_OpFlag      : IN  STD_LOGIC;
            i_CarryIn     : IN  STD_LOGIC;
            o_Sum, o_CarryOut : OUT  STD_LOGIC);
    END COMPONENT;
BEGIN

    add_0: oneBitAddSubUnit
        PORT MAP(
            i_CarryIn => i_OpFlag,
            i_OpFlag => i_OpFlag,
            i_Ai => i_A(0),
            i_Bi => i_Bi(0),
            o_Sum => n_Sum(0),
            o_CarryOut => n_CarryOut(0)
    );

    loop_add: FOR i IN 1 TO n-1 GENERATE
        add_n: oneBitAddSubUnit
        PORT MAP(
            i_CarryIn => n_CarryOut(i-1),
            i_OpFlag => i_OpFlag,
            i_Ai => i_A(i),
            i_Bi => i_Bi(i),
            o_Sum => n_Sum(i),
            o_CarryOut => n_CarryOut(i)
        );
    END GENERATE;

    o_Sum <= n_Sum;
    o_CarryOut <= n_CarryOut(n-1);

END rtl;

