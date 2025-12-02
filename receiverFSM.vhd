LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY receiverFSM IS
    GENERIC(
      dataLen     : INTEGER := 8;
      counterLen  : INTEGER := 4
    );
    PORT(
        BClkD8        : IN  STD_LOGIC;
        GReset        : IN  STD_LOGIC;
        RXD           : IN  STD_LOGIC;
        RDRF          : IN  STD_LOGIC;
        rdrData       : OUT STD_LOGIC_VECTOR(dataLen-1 downto 0);
        setRDRF       : OUT STD_LOGIC;
        setOE         : OUT STD_LOGIC;
        setFE         : OUT STD_LOGIC;
        stateDebug    : OUT STD_LOGIC_VECTOR(2 downto 0)
    );
END receiverFSM;

ARCHITECTURE structural of receiverFSM IS 

  COMPONENT receiverFSMControl
      PORT(
          RDRF, RXD, fourB8, eightB8, bitC8       : IN  STD_LOGIC;
          G_Clock                                 : IN  STD_LOGIC;
          G_Reset                                 : IN  STD_LOGIC;
          resetCount, resetBitCount               : OUT STD_LOGIC;
          shiftEN, loadEN                         : OUT STD_LOGIC;
          setRDRF, setOE, setFE                   : OUT STD_LOGIC;
          stateOut                                : OUT STD_LOGIC_VECTOR(2 downto 0));
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
 
  COMPONENT nBitRegister 
    GENERIC(n : INTEGER := 8);
    PORT(
      i_resetBar  : IN  STD_LOGIC;
      i_load      : IN  STD_LOGIC;
      i_clock     : IN  STD_LOGIC;
      i_Value     : IN  STD_LOGIC_VECTOR(n-1 downto 0);
      o_Value     : OUT STD_LOGIC_VECTOR(n-1 downto 0));
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

  SIGNAL resetCount, resetBitCount, shiftEN, loadEN : STD_LOGIC;
  SIGNAL fourB8, eightB8, bitC8                     : STD_LOGIC;
  SIGNAL rsrData                                    : STD_LOGIC_VECTOR(dataLen-1 downto 0);
  SIGNAL sampleCount, bitCount                      : STD_LOGIC_VECTOR(counterLen-1 downto 0);
  SIGNAL four, seven                                : STD_LOGIC_VECTOR(counterLen-1 downto 0);
  
  -- NEW: Separate enable signals for counters
  SIGNAL sampleCountEnable  : STD_LOGIC;
  SIGNAL bitCountEnable     : STD_LOGIC;

BEGIN
  
  four  <= "0011";
  seven <= "0111";

  sampleCountEnable <= '1';

  bitCountEnable <= shiftEN or resetBitCount;

  fsm: receiverFSMControl
    PORT MAP(
      RDRF          => RDRF, 
      RXD           => RXD, 
      fourB8        => fourB8, 
      eightB8       => eightB8, 
      bitC8         => bitC8, 
      G_Clock       => BClkD8,
      G_Reset       => GReset,                                 
      resetCount    => resetCount, 
      resetBitCount => resetBitCount,            
      shiftEN       => shiftEN, 
      loadEN        => loadEN,                 
      setRDRF       => setRDRF, 
      setOE         => setOE, 
      setFE         => setFE,                   
      stateOut      => stateDebug 
    );

  sampleCounter: nBitCounter
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_resetBar    => GReset,       
      i_resetCount  => resetCount,      
      i_load        => sampleCountEnable,
      i_clock       => BClkD8,
      o_Value       => sampleCount
    );

  comp4: nBitComparator 
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_Ai => sampleCount, 
      i_Bi => four,         
      o_GT => open, 
      o_LT => open, 
      o_EQ => fourB8  
    );
   
  comp8: nBitComparator 
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_Ai => sampleCount, 
      i_Bi => seven,         
      o_GT => open, 
      o_LT => open, 
      o_EQ => eightB8  
    );

  bitCounter: nBitCounter
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_resetBar    => GReset,       
      i_resetCount  => resetBitCount,      
      i_load        => bitCountEnable,
      i_clock       => BClkD8,
      o_Value       => bitCount
    );

  compBit8: nBitComparator 
    GENERIC MAP(n => counterLen)
    PORT MAP(
      i_Ai => bitCount,
      i_Bi => seven,         
      o_GT => open, 
      o_LT => open, 
      o_EQ => bitC8  
    );

  rsr: nBitRightShiftRegister 
    GENERIC MAP(n => dataLen)
    PORT MAP(
        i_resetBar  => GReset,        
        i_load      => '0',        
        i_enable    => shiftEN, 
        i_clock     => BClkD8,
        i_loadValue => "00000000",         
        i_shiftIn   => RXD,
        o_Value     => rsrData, 
        o_shiftOut  => open
    );

  rdr: nBitRegister
    GENERIC MAP(n => dataLen)
    PORT MAP(
        i_resetBar => GReset,	
        i_load     => loadEN,
        i_clock    => BClkD8,
        i_Value    => rsrData,
        o_Value    => rdrData
    );

END structural;
