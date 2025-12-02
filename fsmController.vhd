LIBRARY ieee;
use ieee.std_logic_1164.ALL;

ENTITY fsmController IS
    PORT(
        CounterReachedMax               : IN  STD_LOGIC; 
        SSCS                           : IN  STD_LOGIC;
        G_Clock                        : IN  STD_LOGIC;
        G_Reset                        : IN  STD_LOGIC;
        MSTL, SSTL                     : OUT STD_LOGIC_VECTOR(2 downto 0);
        sA, sB, sC, sD                 : OUT STD_LOGIC;
        s0, s1                         : OUT STD_LOGIC);
END fsmController;

ARCHITECTURE structural OF fsmController IS
  SIGNAL w, y1, y0          : STD_LOGIC;
  SIGNAL n_w, n_y1, n_y0    : STD_LOGIC;
  SIGNAL int_sA, int_sB, int_sC, int_sD : STD_LOGIC;
  SIGNAL i_d0, i_d1         : STD_LOGIC;

  COMPONENT enARdFF_2
    PORT(
      i_resetBar        : IN    STD_LOGIC;
      i_d               : IN    STD_LOGIC;
      i_enable          : IN    STD_LOGIC;
      i_clock           : IN    STD_LOGIC;
      o_q, o_qBar       : OUT   STD_LOGIC);
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

  int_sA <= n_y1 and n_y0;
  int_sB <= n_y1 and y0; 
  int_sC <= y1 and n_y0; 
  int_sD <= y1 and y0; 

  w <= ((SSCS and CounterReachedMax and int_sA)
        or (CounterReachedMax and int_sB)
        or (CounterReachedMax and int_sC)
        or (CounterReachedMax and int_sD));

  n_w <= not(w);

  i_d1 <= (y1 and n_y0) or (y1 and n_w) or (n_y1 and y0 and w);
  i_d0 <= (y0 and n_w)  or (n_y0 and w);

  MSTL(2) <= n_y1 and n_y0;
  MSTL(1) <= n_y1 and y0;
  MSTL(0) <= y1; 

  SSTL(2) <= y1 and n_y0; 
  SSTL(1) <= y1 and y0; 
  SSTL(0) <= n_y1;

  s0 <= y0;
  s1 <= y1;

  sA <= int_sA;
  sB <= int_sB;
  sC <= int_sC;
  sD <= int_sD;

END structural;