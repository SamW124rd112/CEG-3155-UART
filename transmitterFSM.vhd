LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY transmitterFSM IS
    GENERIC(
      dataLen     : INTEGER := 8;
      counterLen  : INTEGER := 4
    );
    PORT(
        BaudClk             : IN STD_LOGIC;
        GClock              : IN STD_LOGIC;
        GReset              : IN STD_LOGIC;
        tdrData             : IN STD_LOGIC_VECTOR(dataLen-1 downto 0);
        TDRE                : IN STD_LOGIC;
        loadFlag            : OUT STD_LOGIC;
        doneFlag            : OUT STD_LOGIC;
        shiftFlag           : OUT STD_LOGIC;
        o_TX                : OUT STD_LOGIC;
        stateDebug          : OUT STD_LOGIC_VECTOR(2 downto 0));
END transmitterFSM;

ARCHITECTURE structural OF transmitterFSM IS 
 
  COMPONENT transmitterFSMControl IS
    PORT(
        TDRE, TSRF, TXD, C8 : IN  STD_LOGIC;
        G_Clock             : IN  STD_LOGIC;
        G_Reset             : IN  STD_LOGIC;
        resetCount          : OUT STD_LOGIC;
        shiftEN             : OUT STD_LOGIC;
        doneEN              : OUT STD_LOGIC;
        loadEN              : OUT STD_LOGIC;
        TXOut               : OUT STD_LOGIC;
        stateOut            : OUT STD_LOGIC_VECTOR(2 downto 0));
  END COMPONENT;

  COMPONENT enARdFF_2
    PORT(
      i_resetBar  : IN  STD_LOGIC;
      i_d         : IN  STD_LOGIC;
      i_enable    : IN  STD_LOGIC;
      i_clock     : IN  STD_LOGIC;
      o_q, o_qBar : OUT STD_LOGIC);
  END COMPONENT;
  
  COMPONENT nBitComparator IS
    GENERIC(n: INTEGER := 4);
    PORT(
      i_Ai, i_Bi          : IN  STD_LOGIC_VECTOR(n-1 downto 0);
      o_GT, o_LT, o_EQ    : OUT STD_LOGIC);
  END COMPONENT;

  COMPONENT nBitCounter IS
    GENERIC(n : INTEGER := 4);
    PORT(
      i_resetBar          : IN  STD_LOGIC;
      i_resetCount        : IN  STD_LOGIC;
      i_load              : IN  STD_LOGIC;
      i_clock             : IN  STD_LOGIC;
      o_Value             : OUT STD_LOGIC_VECTOR(n-1 downto 0));
  END COMPONENT;
  
  COMPONENT oneBitMux2to1 
    PORT(s, x0, x1  : IN  STD_LOGIC;
         y          : OUT STD_LOGIC);
  END COMPONENT; 

  COMPONENT nBitRightShiftRegister
    GENERIC(n : INTEGER := 8); 
    PORT(
      i_resetBar          : IN STD_LOGIC;
      i_load              : IN STD_LOGIC; 
      i_enable            : IN STD_LOGIC; 
      i_clock             : IN STD_LOGIC;
      i_loadValue         : IN STD_LOGIC_VECTOR(n-1 downto 0);  
      i_shiftIn           : IN STD_LOGIC;  
      o_Value             : OUT STD_LOGIC_VECTOR(n-1 downto 0);
      o_shiftOut          : OUT STD_LOGIC);
  END COMPONENT;

  SIGNAL resetCount               : STD_LOGIC;
  SIGNAL shiftEN, loadEN, doneEN  : STD_LOGIC;
  SIGNAL TXOut, C8Flag, TSRF, TXD : STD_LOGIC;
  SIGNAL tsrData                  : STD_LOGIC_VECTOR(dataLen-1 downto 0);
  SIGNAL eight                    : STD_LOGIC_VECTOR(counterLen-1 downto 0);
  SIGNAL dataCount                : STD_LOGIC_VECTOR(counterLen-1 downto 0);
  SIGNAL tsrEnable                : STD_LOGIC;
  SIGNAL shiftEN_delayed          : STD_LOGIC;
  SIGNAL counterEN                : STD_LOGIC;
  
  -- New signals for structural start bit fix
  SIGNAL internalState  : STD_LOGIC_VECTOR(2 downto 0);
  SIGNAL startBit       : STD_LOGIC;
  SIGNAL isStartState   : STD_LOGIC;
  SIGNAL txBitMuxed     : STD_LOGIC;

BEGIN
  eight     <= "0111"; 
  TSRF      <= loadEN;

  delayShift: enARdFF_2
    PORT MAP(
      i_resetBar => GReset,
      i_d        => shiftEN,
      i_enable   => '1',
      i_clock    => BaudClk,
      o_q        => shiftEN_delayed,
      o_qBar     => open
    );

  tsrEnable <= loadEN or shiftEN;

  fsm: transmitterFSMControl
    PORT MAP(
        TDRE        => TDRE,
        TSRF        => TSRF, 
        TXD         => TXD, 
        C8          => C8Flag,
        G_Clock     => BaudClk,
        G_Reset     => GReset,
        resetCount  => resetCount,
        shiftEN     => shiftEN,
        doneEN      => doneEN,
        loadEN      => loadEN,
        TXOut       => TXOut,
        stateOut    => internalState
    );

  -- Decode START state (state C = "010")
  -- isStartState = NOT(y2) AND y1 AND NOT(y0)
  isStartState <= (NOT internalState(2)) AND internalState(1) AND (NOT internalState(0));

  -- Constant signal for start bit
  startBit <= '0';

  -- NEW MUX: Select between start bit and data bit
  startBitMux: oneBitMux2to1
    PORT MAP(
      s   => isStartState,
      x0  => TXD,
      x1  => startBit,
      y   => txBitMuxed
    );

  -- MODIFIED: Original mux now uses muxed signal
  txMux: oneBitMux2to1
    PORT MAP(
      s   => TXOut, 
      x0  => txBitMuxed,
      x1  => '1',
      y   => o_TX
    );

  tsr: nBitRightShiftRegister
    GENERIC MAP(n => dataLen)
    PORT MAP(
      i_resetBar  => GReset, 
      i_load      => loadEN, 
      i_enable    => tsrEnable,
      i_clock     => BaudClk,
      i_loadValue => tdrData,
      i_shiftIn   => '0',
      o_Value     => tsrData,
      o_shiftOut  => TXD
    );

  dataCounter: nBitCounter
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_resetBar    => GReset,
      i_resetCount  => resetCount,
      i_load        => counterEN,
      i_clock       => BaudClk,
      o_Value       => dataCount
    );

  dataComparator: nBitComparator
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_Ai => dataCount, 
      i_Bi => eight,
      o_GT => open,
      o_LT => open,
      o_EQ => C8Flag
    );

  loadFlag  <= loadEN;
  shiftFlag <= shiftEN;
  doneFlag  <= doneEN;
  stateDebug <= internalState;

END structural;
