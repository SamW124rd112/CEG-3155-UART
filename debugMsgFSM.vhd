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

    COMPONENT counter3Bit
        PORT(
            GClock     : IN  STD_LOGIC;
            GReset     : IN  STD_LOGIC;
            i_reset    : IN  STD_LOGIC;
            i_enable   : IN  STD_LOGIC;
            o_count    : OUT STD_LOGIC_VECTOR(2 downto 0);
            o_maxReach : OUT STD_LOGIC);
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

BEGIN

    ---------------------------------------------------------------------------
    -- State Change Detector
    ---------------------------------------------------------------------------
    detector: stateChangeDetector
        PORT MAP(
            GClock       => GClock,
            GReset       => GReset,
            currentState => TL_State,
            stateChanged => stateChanged_int
        );

    ---------------------------------------------------------------------------
    -- FSM Control
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- Character Counter (0-5)
    ---------------------------------------------------------------------------
    charCounter: counter3Bit
        PORT MAP(
            GClock     => GClock,
            GReset     => GReset,
            i_reset    => counterReset_int,
            i_enable   => counterEn_int,
            o_count    => charIndex_int,
            o_maxReach => msgDone_int
        );

    ---------------------------------------------------------------------------
    -- Character ROM
    ---------------------------------------------------------------------------
    charRom: characterROM
        PORT MAP(
            TL_State  => TL_State,
            charIndex => charIndex_int,
            charOut   => DataOut
        );

    ---------------------------------------------------------------------------
    -- Address Output
    ---------------------------------------------------------------------------
    ADDR(0) <= addrBit0_int;
    ADDR(1) <= '0';

END structural;