LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY receiverFSMControl IS
    PORT(
        RDRF, RXD, fourB8, eightB8, bitC8       : IN  STD_LOGIC;
        G_Clock                                 : IN  STD_LOGIC;
        G_Reset                                 : IN  STD_LOGIC;
        resetCount, resetBitCount               : OUT STD_LOGIC;
        shiftEN, loadEN                         : OUT STD_LOGIC;
        setRDRF, setOE, setFE                   : OUT STD_LOGIC;
        stateOut                                : OUT STD_LOGIC_VECTOR(2 downto 0));
END receiverFSMControl;

ARCHITECTURE structural OF receiverFSMControl IS 
  SIGNAL w, y2, y1, y0          : STD_LOGIC;
  SIGNAL n_w, n_y2, n_y1, n_y0  : STD_LOGIC;
  SIGNAL sA, sB, sC, sD, sE     : STD_LOGIC; 
  SIGNAL i_d0, i_d1, i_d2       : STD_LOGIC;

  COMPONENT enARdFF_2
    PORT(
      i_resetBar  : IN  STD_LOGIC;
      i_d         : IN  STD_LOGIC;
      i_enable    : IN  STD_LOGIC;
      i_clock     : IN  STD_LOGIC;
      o_q, o_qBar : OUT STD_LOGIC);
  END COMPONENT;

BEGIN

  dFF_y2: enARdFF_2
    PORT MAP(
      i_resetBar  => G_Reset,
      i_d         => i_d2,
      i_enable    => '1',
      i_clock     => G_Clock,
      o_q         => y2,
      o_qBar      => n_y2
    );

  dFF_y1: enARdFF_2
    PORT MAP(
      i_resetBar  => G_Reset,
      i_d         => i_d1,
      i_enable    => '1',
      i_clock     => G_Clock,
      o_q         => y1,
      o_qBar      => n_y1
    );

  dFF_y0: enARdFF_2
    PORT MAP(
      i_resetBar  => G_Reset,
      i_d         => i_d0,
      i_enable    => '1',
      i_clock     => G_Clock,
      o_q         => y0,
      o_qBar      => n_y0
    );

  sA <= n_y2 and n_y1 and n_y0; 
  sB <= n_y2 and n_y1 and y0; 
  sC <= n_y2 and y1 and n_y0; 
  sD <= n_y2 and y1 and y0; 
  sE <= y2 and n_y1 and n_y0; 

  w <= ((sA and not(RXD)) 
       or (sB and fourB8)  
       or (sC and eightB8 and bitC8)  
       or (sD and eightB8) 
       or (sE)); 

  n_w <= not(w);

  i_d2 <= (w and y1 and y0) or (n_w and y2);
  i_d1 <= (w and y0 and n_y1) or (y1 and n_y0) or (n_w and y1);
  i_d0 <= n_y2 and ((w and n_y0) or (n_w and y0));

  resetCount <= sA or (sB and fourB8) or (sC and eightB8);

  resetBitCount <= sA;

  shiftEN <= sC and eightB8;

  loadEN <= sE;

  setRDRF <= sE and not(RDRF);
  setOE   <= sE and RDRF;
  setFE   <= sD and eightB8 and not(RXD);

  stateOut(2) <= y2;
  stateOut(1) <= y1;
  stateOut(0) <= y0;

END structural;
