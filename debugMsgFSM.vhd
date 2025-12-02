LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY debugMsgFSM IS
    PORT(
        GClock      : IN  STD_LOGIC;
        GReset      : IN  STD_LOGIC;
        TL_State    : IN  STD_LOGIC_VECTOR(1 downto 0);
        TDRE        : IN  STD_LOGIC;
        UART_Select : OUT STD_LOGIC;
        ADDR        : OUT STD_LOGIC_VECTOR(1 downto 0);
        RW          : OUT STD_LOGIC;
        DataOut     : OUT STD_LOGIC_VECTOR(7 downto 0);
        stateDebug  : OUT STD_LOGIC_VECTOR(2 downto 0)
    );
END debugMsgFSM;

ARCHITECTURE structural OF debugMsgFSM IS

    COMPONENT stateChangeDetector
        PORT(
            GClock       : IN  STD_LOGIC;
            GReset       : IN  STD_LOGIC;
            currentState : IN  STD_LOGIC_VECTOR(1 downto 0);
            stateChanged : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT debugMsgFSMControl
        PORT(
            GClock       : IN  STD_LOGIC;
            GReset       : IN  STD_LOGIC;
            stateChanged : IN  STD_LOGIC;
            TDRE         : IN  STD_LOGIC;
            msgDone      : IN  STD_LOGIC;
            counterReset : OUT STD_LOGIC;
            counterEn    : OUT STD_LOGIC;
            uartSelect   : OUT STD_LOGIC;
            uartRW       : OUT STD_LOGIC;
            addrBit0     : OUT STD_LOGIC;
            stateOut     : OUT STD_LOGIC_VECTOR(2 downto 0));
    END COMPONENT;

    COMPONENT nBitCounter
        GENERIC(n : INTEGER := 4);
        PORT(
            i_resetBar   : IN  STD_LOGIC;
            i_resetCount : IN  STD_LOGIC;
            i_load       : IN  STD_LOGIC;
            i_clock      : IN  STD_LOGIC;
            o_Value      : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    COMPONENT nBitComparator
        GENERIC(n : INTEGER := 4);
        PORT(
            i_Ai, i_Bi       : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            o_GT, o_LT, o_EQ : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT characterROM
        PORT(
            TL_State  : IN  STD_LOGIC_VECTOR(1 downto 0);
            charIndex : IN  STD_LOGIC_VECTOR(2 downto 0);
            charOut   : OUT STD_LOGIC_VECTOR(7 downto 0));
    END COMPONENT;

    SIGNAL stateChanged_int : STD_LOGIC;
    SIGNAL counterReset_int : STD_LOGIC;
    SIGNAL counterEn_int    : STD_LOGIC;
    SIGNAL charIndex_int    : STD_LOGIC_VECTOR(2 downto 0);
    SIGNAL msgDone_int      : STD_LOGIC;
    SIGNAL addrBit0_int     : STD_LOGIC;
    
    SIGNAL counterEnable    : STD_LOGIC;

    SIGNAL seven            : STD_LOGIC_VECTOR(2 downto 0);
    SIGNAL countIs7         : STD_LOGIC;

BEGIN

    seven <= "111";

    detector: stateChangeDetector
        PORT MAP(
            GClock       => GClock,
            GReset       => GReset,
            currentState => TL_State,
            stateChanged => stateChanged_int
        );

    control: debugMsgFSMControl
        PORT MAP(
            GClock       => GClock,
            GReset       => GReset,
            stateChanged => stateChanged_int,
            TDRE         => TDRE,
            msgDone      => msgDone_int,
            counterReset => counterReset_int,
            counterEn    => counterEn_int,
            uartSelect   => UART_Select,
            uartRW       => RW,
            addrBit0     => addrBit0_int,
            stateOut     => stateDebug
        );

    counterEnable <= counterEn_int OR counterReset_int;

    charCounter: nBitCounter
        GENERIC MAP(n => 3)
        PORT MAP(
            i_resetBar   => GReset,
            i_resetCount => counterReset_int,
            i_load       => counterEnable,
            i_clock      => GClock,
            o_Value      => charIndex_int
        );

    countComparator: nBitComparator
        GENERIC MAP(n => 3)
        PORT MAP(
            i_Ai => charIndex_int,
            i_Bi => seven,
            o_GT => open,
            o_LT => open,
            o_EQ => countIs7
        );

    msgDone_int <= countIs7;

    charRom: characterROM
        PORT MAP(
            TL_State  => TL_State,
            charIndex => charIndex_int,
            charOut   => DataOut
        );

    ADDR(0) <= addrBit0_int;
    ADDR(1) <= '0';

END structural;