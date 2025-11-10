LIBRARY ieee;:
USE ieee.std_logic_1164.ALL;

ENTITY nBitMux2to1 IS  
    PORT(
        GENERIC(n: INTEGER := 4);
        i_sel       : IN  STD_LOGIC;
        i_d0, i_d1  : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        o_q         : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END nBitMux2to1;

ARCHITECTURE structural OF mux2to1_4bit IS
    COMPONENT mux2to1 IS
        PORT(
            s, x0, x1 : IN  STD_LOGIC;
            y         : OUT STD_LOGIC;
        );
    END COMPONENT;
BEGIN
    gen_mux: FOR i IN 0 TO n-1 GENERATE
        mux_i: mux2to1 PORT MAP(
            s => i_sel,
            x0 => i_d0(i),
            x1 => i_d1(i),
            y => o_q(i)
        );
    END GENERATE;
END structural;
