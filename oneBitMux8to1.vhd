LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY oneBitMux8to1 IS
  PORT (  s0, s1, s2                      : IN STD_LOGIC;
          x0, x1, x2, x3, x4, x5, x6, x7  : IN STD_LOGIC;
          y                               : OUT STD_LOGIC ) ;
END oneBitMux8to1; 

ARCHITECTURE structural OF oneBitMux8to1 IS 
    SIGNAL muxAOut, muxBOut, muxCOut, muxDOut, mux1Out, mux2Out, muxOut : STD_LOGIC ;

    COMPONENT oneBitMux2to1
    PORT (  s, x0, x1   : IN STD_LOGIC;
            y           : OUT STD_LOGIC);
    END COMPONENT; 

BEGIN

  muxA: oneBitMux2to1 PORT MAP (s0, x0, x1, muxAOut);
  muxB: oneBitMux2to1 PORT MAP (s0, x2, x3, muxBOut);
  muxC: oneBitMux2to1 PORT MAP (s0, x4, x5, muxCOut);
  muxD: oneBitMux2to1 PORT MAP (s0, x6, x7, muxDOut);

  mux1: oneBitMux2to1 PORT MAP (s1, muxAOut, muxBOut, mux1Out);
  mux2: oneBitMux2to1 PORT MAP (s1, muxCOut, muxDOut, mux2Out);

  muxF: oneBitMux2to1 PORT MAP (s2, mux1Out, mux2Out, muxOut);

  y<=muxOut;  

END structural;
