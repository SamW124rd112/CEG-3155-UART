LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY uartFSMControl IS
    PORT(
        G_Clock               : IN  STD_LOGIC;
        G_Reset               : IN  STD_LOGIC;
        TDRE, RDRF            : IN  STD_LOGIC;
        TDR_WR, RDR_RD        : IN  STD_LOGIC; 
        TX_Active, RX_Active  : IN  STD_LOGIC;
        TX_Load               : IN  STD_LOGIC;
        clrTDRE, clrRDRF      : IN  STD_LOGIC;
        clrOE, clrFE          : OUT STD_LOGIC;
        setTDRE               : OUT STD_LOGIC;
        stateDebug            : OUT STD_LOGIC_VECTOR(1 downto 0));
END uartFSMControl;

ARCHITECTURE structural OF uartFSMControl IS 
  SIGNAL y1, y0           : STD_LOGIC;
  SIGNAL n_y1, n_y0       : STD_LOGIC;
  SIGNAL sA, sB, sC       : STD_LOGIC; 
  SIGNAL i_d0, i_d1       : STD_LOGIC;

  COMPONENT enARdFF_2
    PORT(
      i_resetBar  : IN  STD_LOGIC;
      i_d         : IN  STD_LOGIC;
      i_enable    : IN  STD_LOGIC;
      i_clock     : IN  STD_LOGIC;
      o_q, o_qBar : OUT STD_LOGIC);
  END COMPONENT;

BEGIN

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

  sA <= n_y1 and n_y0; 
  sB <= n_y1 and y0;
  sC <= y1 and n_y0; 



  i_d1 <= (sA and RX_Active) OR 
          (sB and RX_Active) OR 
          (sC and RX_Active);

  i_d0 <= (sA and TDR_WR and (NOT RX_Active)) OR 
          (sB and TX_Active and (NOT RX_Active)) OR 
          (sC and TDR_WR);

  setTDRE <= TX_Load;

  stateDebug(1) <= y1;
  stateDebug(0) <= y0;

END structural;
