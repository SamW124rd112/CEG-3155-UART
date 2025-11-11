LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY oneBitMux4to1 IS
  PORT (  s0, s1, x0, x1, x2, x3  : IN STD_LOGIC ;
          y                       : OUT STD_LOGIC ) ;
END oneBitMux4to1; 

ARCHITECTURE structural OF oneBitMux4to1 IS 
    SIGNAL mux1Out, mux2Out, muxOut : STD_LOGIC ;

    COMPONENT oneBitMux2to1
    PORT (  s, x0, x1   : IN STD_LOGIC ;
            y           : OUT STD_LOGIC ) ;
    END COMPONENT; 

BEGIN

  mux1: oneBitMux2to1 PORT MAP (s0, x0, x1, mux1Out);
  mux2: oneBitMux2to1 PORT MAP (s0, x2, x3, mux2Out);

  muxF: oneBitMux2to1 PORT MAP (s1, mux1Out, mux2Out, muxOut);

  y<=muxOut;  

END structural;
