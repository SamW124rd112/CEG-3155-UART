LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY debugTrafficLightSystem IS
    PORT(
        GClock   : IN  STD_LOGIC;
        GReset   : IN  STD_LOGIC;
        SSCS     : IN  STD_LOGIC;
        MSC      : IN  STD_LOGIC_VECTOR(3 downto 0);
        SSC      : IN  STD_LOGIC_VECTOR(3 downto 0);
        RxD      : IN  STD_LOGIC;
        TxD      : OUT STD_LOGIC;
        MSTL     : OUT STD_LOGIC_VECTOR(2 downto 0);
        SSTL     : OUT STD_LOGIC_VECTOR(2 downto 0);
        BCD1     : OUT STD_LOGIC_VECTOR(3 downto 0);
        BCD2     : OUT STD_LOGIC_VECTOR(3 downto 0)
    );
END debugTrafficLightSystem;

ARCHITECTURE structural OF debugTrafficLightSystem IS

    COMPONENT trafficLightController
        PORT(
            MSC, SSC    : IN  STD_LOGIC_VECTOR(3 downto 0);
            SSCS        : IN  STD_LOGIC;
            G_Clock     : IN  STD_LOGIC;
            G_Reset     : IN  STD_LOGIC;
            MSTL, SSTL  : OUT STD_LOGIC_VECTOR(2 downto 0);
            BCD1, BCD2  : OUT STD_LOGIC_VECTOR(3 downto 0);
            TL_State    : OUT STD_LOGIC_VECTOR(1 downto 0));
    END COMPONENT;

    COMPONENT debugMsgFSM
        PORT(
            GClock      : IN  STD_LOGIC;
            GReset      : IN  STD_LOGIC;
            TL_State    : IN  STD_LOGIC_VECTOR(1 downto 0);
            TDRE        : IN  STD_LOGIC;
            UART_Select : OUT STD_LOGIC;
            ADDR        : OUT STD_LOGIC_VECTOR(1 downto 0);
            RW          : OUT STD_LOGIC;
            DataOut     : OUT STD_LOGIC_VECTOR(7 downto 0);
            stateDebug  : OUT STD_LOGIC_VECTOR(2 downto 0));
    END COMPONENT;

    COMPONENT uartFSM
        PORT(
            GClock        : IN    STD_LOGIC;
            GReset        : IN    STD_LOGIC;
            UART_Select   : IN    STD_LOGIC;
            ADDR          : IN    STD_LOGIC_VECTOR(1 downto 0);
            RWFlag        : IN    STD_LOGIC;
            RXD           : IN    STD_LOGIC;
            TXD           : OUT   STD_LOGIC;
            IRQ           : OUT   STD_LOGIC;
            Databus       : INOUT STD_LOGIC_VECTOR(7 downto 0);
            stateOut      : OUT   STD_LOGIC_VECTOR(1 downto 0);
            TX_StateDebug : OUT   STD_LOGIC_VECTOR(2 downto 0);
            RX_StateDebug : OUT   STD_LOGIC_VECTOR(2 downto 0));
    END COMPONENT;

    COMPONENT nBitTristate
        GENERIC(n: INTEGER := 8);
        PORT(
            enable : IN  STD_LOGIC;
            input  : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            output : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    -- Internal signals
    SIGNAL tlState_int    : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL uartSelect_int : STD_LOGIC;
    SIGNAL uartAddr_int   : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL uartRW_int     : STD_LOGIC;
    SIGNAL dataBus_int    : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL dataOut_int    : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL tdreStatus_int : STD_LOGIC;
    SIGNAL writeEnable    : STD_LOGIC;
    SIGNAL writeEnable_n  : STD_LOGIC;

BEGIN

    ---------------------------------------------------------------------------
    -- Traffic Light Controller
    ---------------------------------------------------------------------------
    tlc: trafficLightController
        PORT MAP(
            MSC      => MSC,
            SSC      => SSC,
            SSCS     => SSCS,
            G_Clock  => GClock,
            G_Reset  => GReset,
            MSTL     => MSTL,
            SSTL     => SSTL,
            BCD1     => BCD1,
            BCD2     => BCD2,
            TL_State => tlState_int
        );

    ---------------------------------------------------------------------------
    -- Debug Message FSM
    ---------------------------------------------------------------------------
    msgFsm: debugMsgFSM
        PORT MAP(
            GClock      => GClock,
            GReset      => GReset,
            TL_State    => tlState_int,
            TDRE        => tdreStatus_int,
            UART_Select => uartSelect_int,
            ADDR        => uartAddr_int,
            RW          => uartRW_int,
            DataOut     => dataOut_int,
            stateDebug  => open
        );

    ---------------------------------------------------------------------------
    -- Write enable logic
    ---------------------------------------------------------------------------
    writeEnable_n <= uartRW_int;  -- RW=1 means read, RW=0 means write
    writeEnable <= NOT writeEnable_n;

    ---------------------------------------------------------------------------
    -- Tristate buffer for data bus (write direction)
    ---------------------------------------------------------------------------
    writeBuf: nBitTristate
        GENERIC MAP(n => 8)
        PORT MAP(
            enable => writeEnable,
            input  => dataOut_int,
            output => dataBus_int
        );

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart: uartFSM
        PORT MAP(
            GClock        => GClock,
            GReset        => GReset,
            UART_Select   => uartSelect_int,
            ADDR          => uartAddr_int,
            RWFlag        => uartRW_int,
            RXD           => RxD,
            TXD           => TxD,
            IRQ           => open,
            Databus       => dataBus_int,
            stateOut      => open,
            TX_StateDebug => open,
            RX_StateDebug => open
        );

    -- Extract TDRE from data bus (bit 7 of SCSR)
    tdreStatus_int <= dataBus_int(7);

END structural;