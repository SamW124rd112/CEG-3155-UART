LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY nBitMux8to1 IS
  GENERIC (n: INTEGER := 4);
  PORT (  s0, s1, s2                              : IN STD_LOGIC;
          x0, x1, x2, x3, x4, x5, x6, x7          : IN STD_LOGIC_VECTOR(n-1 downto 0);
          y                                       : OUT STD_LOGIC_VECTOR(n-1 downto 0));
  END nBitMux8to1; 

ARCHITECTURE structural OF nBitMux8to1 IS 
  COMPONENT oneBitMux8to1 
    PORT (  s0, s1, s2                      : IN STD_LOGIC;
            x0, x1, x2, x3, x4, x5, x6, x7  : IN STD_LOGIC;
            y                               : OUT STD_LOGIC ) ;
  END COMPONENT; 


BEGIN

  muxloop: FOR i IN 0 to n-1 GENERATE
    mux_n: oneBitMux8to1 PORT MAP (s0, s1, s2, x0(i), x1(i), x2(i), x3(i), x4(i), x5(i), x6(i), x7(i), y(i));
  END GENERATE;

END structural;
