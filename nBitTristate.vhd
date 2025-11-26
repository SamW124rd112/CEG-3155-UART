LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitTristate IS
    GENERIC(n: INTEGER := 8);
    PORT(
        enable  : IN  STD_LOGIC;
        input   : IN  STD_LOGIC_VECTOR(n-1 downto 0);
        output  : OUT STD_LOGIC_VECTOR(n-1 downto 0)
    );
END nBitTristate;

ARCHITECTURE structural OF nBitTristate IS

    COMPONENT tristate_1bit
        PORT(
            enable  : IN  STD_LOGIC;
            input   : IN  STD_LOGIC;
            output  : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    GEN_TRI: FOR i IN 0 TO n-1 GENERATE
        tri_bit: tristate_1bit
            PORT MAP(
                enable => enable,
                input  => input(i),
                output => output(i)
            );
    END GENERATE;

END structural;
