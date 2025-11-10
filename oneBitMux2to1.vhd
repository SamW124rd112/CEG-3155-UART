LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY oneBitMux2to1 IS
PORT (  s, x0, x1   : IN    STD_LOGIC ;
        y           : OUT   STD_LOGIC ) ;
END oneBitMux2to1; 

ARCHITECTURE structural OF oneBitMux2to1 IS 
    SIGNAL not_s, selX0, selX1 : STD_LOGIC ;

BEGIN
    -- Y = (NOT S AND X0) OR (S AND X1)
    not_s <= NOT s ;
    selX0 <= not_s AND x0 ;
    selX1 <= s AND x1 ;
    y <= selX0 OR selX1 ;
END structural ;
