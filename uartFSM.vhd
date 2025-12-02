LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY uartFSM IS
    PORT(
        GClock          : IN  STD_LOGIC;
        GReset          : IN  STD_LOGIC;
        UART_Select     : IN  STD_LOGIC;
        ADDR            : IN  STD_LOGIC_VECTOR(1 downto 0);
        RWFlag          : IN  STD_LOGIC;
        RXD             : IN  STD_LOGIC;
        TXD             : OUT STD_LOGIC;
        IRQ             : OUT STD_LOGIC;    
        Databus         : INOUT STD_LOGIC_VECTOR(7 downto 0);   
        stateOut        : OUT STD_LOGIC_VECTOR(1 downto 0);
        TX_StateDebug   : OUT STD_LOGIC_VECTOR(2 downto 0);
        RX_StateDebug   : OUT STD_LOGIC_VECTOR(2 downto 0)
    );
END uartFSM;

ARCHITECTURE structural OF uartFSM IS 

    ---------------------------------------------------------------------------
    -- Component Declarations
    ---------------------------------------------------------------------------
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
  
    COMPONENT addressDecoder 
        PORT(
            UART_Select : IN  STD_LOGIC;
            ADDR        : IN  STD_LOGIC_VECTOR(1 downto 0);
            R_W         : IN  STD_LOGIC;
            RDR_RD      : OUT STD_LOGIC;
            TDR_WR      : OUT STD_LOGIC;
            SCSR_RD     : OUT STD_LOGIC;
            SCCR_RD     : OUT STD_LOGIC;
            SCCR_WR     : OUT STD_LOGIC;
            BUS_EN      : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT baudRateGen 
        PORT(
            SEL               : IN  STD_LOGIC_VECTOR(2 downto 0);
            in_Clock          : IN  STD_LOGIC;
            G_Reset           : IN  STD_LOGIC;
            baudClk           : OUT STD_LOGIC;
            BClkD8            : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT transmitterFSM 
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
    END COMPONENT;

    COMPONENT receiverFSM 
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
    END COMPONENT;

    COMPONENT statusRegister 
        PORT(
            GClock               : IN  STD_LOGIC;
            GReset               : IN  STD_LOGIC;
            setTDRE, setRDRF     : IN  STD_LOGIC;
            setOE, setFE         : IN  STD_LOGIC;
            clrTDRE, clrRDRF     : IN  STD_LOGIC;
            clrOE, clrFE         : IN  STD_LOGIC;
            TDRE, RDRF           : OUT STD_LOGIC;
            OE, FE               : OUT STD_LOGIC;
            SCSR                 : OUT STD_LOGIC_VECTOR(7 downto 0)
        );
    END COMPONENT;

    COMPONENT interruptLogic
        PORT(
            TIE, RIE      : IN  STD_LOGIC;
            TDRE, RDRF    : IN  STD_LOGIC;
            OE            : IN  STD_LOGIC;
            IRQ           : OUT STD_LOGIC
        );
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

    COMPONENT nBitTristate 
        GENERIC(n: INTEGER := 8);
        PORT(
            enable  : IN  STD_LOGIC;
            input   : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            output  : OUT STD_LOGIC_VECTOR(n-1 downto 0)
        );
    END COMPONENT;

    COMPONENT nBitMux4to1 
        GENERIC (n: INTEGER := 4);
        PORT(
            s0, s1                  : IN STD_LOGIC;
            x0, x1, x2, x3          : IN STD_LOGIC_VECTOR(n-1 downto 0);
            y                       : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT; 


    SIGNAL RDR_RD, TDR_WR, SCSR_RD, SCCR_WR, SCCR_RD, BUS_EN : STD_LOGIC;  
    SIGNAL baudClk, BClkD8                                    : STD_LOGIC;
    SIGNAL SEL                                                : STD_LOGIC_VECTOR(2 downto 0);

    SIGNAL TDRE, RDRF, OE, FE                                 : STD_LOGIC;
    SIGNAL setTDRE, setRDRF, setOE, setFE                     : STD_LOGIC;
    SIGNAL clrTDRE, clrRDRF, clrOE, clrFE                     : STD_LOGIC;
    SIGNAL SCSR_Data, SCCR_Data                               : STD_LOGIC_VECTOR(7 downto 0);
    
    SIGNAL TIE, RIE                                           : STD_LOGIC;
    SIGNAL TDR_Data, RDR_Data                                 : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL TX_loadFlag, TX_shiftFlag, TX_doneFlag             : STD_LOGIC;

    SIGNAL DataBus_In    : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL DataBus_Out   : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL ReadData_Mux  : STD_LOGIC_VECTOR(7 downto 0);

    SIGNAL rxd_meta      : STD_LOGIC;  
    SIGNAL rxd_sync      : STD_LOGIC;  


    SIGNAL tx_load_meta  : STD_LOGIC; 
    SIGNAL tx_load_sync  : STD_LOGIC; 
    SIGNAL tx_load_prev  : STD_LOGIC;  
    SIGNAL tx_load_pulse : STD_LOGIC;  

    SIGNAL setRDRF_raw   : STD_LOGIC; 
    SIGNAL setRDRF_meta  : STD_LOGIC;  
    SIGNAL setRDRF_sync  : STD_LOGIC;  
    SIGNAL setRDRF_prev  : STD_LOGIC;  

    SIGNAL setOE_raw     : STD_LOGIC; 
    SIGNAL setOE_meta    : STD_LOGIC;  
    SIGNAL setOE_sync    : STD_LOGIC; 
    SIGNAL setOE_prev    : STD_LOGIC;  

    SIGNAL setFE_raw     : STD_LOGIC;  
    SIGNAL setFE_meta    : STD_LOGIC;  
    SIGNAL setFE_sync    : STD_LOGIC; 
    SIGNAL setFE_prev    : STD_LOGIC; 

    SIGNAL tdre_to_tx_meta : STD_LOGIC;
    SIGNAL tdre_to_tx_sync : STD_LOGIC;
    SIGNAL rdrf_to_rx_meta : STD_LOGIC;
    SIGNAL rdrf_to_rx_sync : STD_LOGIC;

BEGIN


    addrDec: addressDecoder 
        PORT MAP(
            UART_Select => UART_Select, 
            ADDR        => ADDR,
            R_W         => RWFlag,
            RDR_RD      => RDR_RD,
            TDR_WR      => TDR_WR,
            SCSR_RD     => SCSR_RD,
            SCCR_RD     => SCCR_RD,
            SCCR_WR     => SCCR_WR,
            BUS_EN      => BUS_EN
        );
  
    SEL <= SCCR_Data(2 downto 0); 

    baudGen: baudRateGen
        PORT MAP(
            SEL       => "010",    
            in_Clock  => GClock,
            G_Reset   => GReset,
            baudClk   => baudClk,
            BClkD8    => BClkD8      
        );

    sscrReg: nBitRegister
        GENERIC MAP(n => 8)
        PORT MAP(
            i_resetBar  => GReset,	
            i_load      => SCCR_WR,
            i_clock     => GClock,
            i_Value     => DataBus_In,
            o_Value     => SCCR_Data
        );

    TIE <= SCCR_Data(7);
    RIE <= SCCR_Data(6);

    rxd_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => RXD,
            i_enable   => '1',
            i_clock    => BClkD8,
            o_q        => rxd_meta,
            o_qBar     => open
        );

    rxd_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => rxd_meta,
            i_enable   => '1',
            i_clock    => BClkD8,
            o_q        => rxd_sync,
            o_qBar     => open
        );

    tx_load_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => TX_loadFlag,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => tx_load_meta,
            o_qBar     => open
        );

    tx_load_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => tx_load_meta,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => tx_load_sync,
            o_qBar     => open
        );

    tx_load_edge_detect: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => tx_load_sync,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => tx_load_prev,
            o_qBar     => open
        );

    tx_load_pulse <= tx_load_sync AND (NOT tx_load_prev);

    setTDRE <= tx_load_pulse;

    tdre_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => TDRE,
            i_enable   => '1',
            i_clock    => baudClk,
            o_q        => tdre_to_tx_meta,
            o_qBar     => open
        );

    tdre_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => tdre_to_tx_meta,
            i_enable   => '1',
            i_clock    => baudClk,
            o_q        => tdre_to_tx_sync,
            o_qBar     => open
        );

    rdrf_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => RDRF,
            i_enable   => '1',
            i_clock    => BClkD8,
            o_q        => rdrf_to_rx_meta,
            o_qBar     => open
        );

    rdrf_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => rdrf_to_rx_meta,
            i_enable   => '1',
            i_clock    => BClkD8,
            o_q        => rdrf_to_rx_sync,
            o_qBar     => open
        );
    
    setRDRF_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setRDRF_raw,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setRDRF_meta,
            o_qBar     => open
        );

    setRDRF_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setRDRF_meta,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setRDRF_sync,
            o_qBar     => open
        );

    setRDRF_edge_detect: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setRDRF_sync,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setRDRF_prev,
            o_qBar     => open
        );

    setRDRF <= setRDRF_sync AND (NOT setRDRF_prev);

    setOE_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setOE_raw,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setOE_meta,
            o_qBar     => open
        );

    setOE_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setOE_meta,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setOE_sync,
            o_qBar     => open
        );

    setOE_edge_detect: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setOE_sync,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setOE_prev,
            o_qBar     => open
        );

    setOE <= setOE_sync AND (NOT setOE_prev);

    setFE_sync_stage1: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setFE_raw,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setFE_meta,
            o_qBar     => open
        );

    setFE_sync_stage2: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setFE_meta,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setFE_sync,
            o_qBar     => open
        );

    setFE_edge_detect: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => setFE_sync,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => setFE_prev,
            o_qBar     => open
        );

    setFE <= setFE_sync AND (NOT setFE_prev);

    statusReg: statusRegister
        PORT MAP(
            GClock    => GClock,              
            GReset    => GReset,              
            setTDRE   => setTDRE, 
            setRDRF   => setRDRF, 
            setOE     => setOE,   
            setFE     => setFE, 
            clrTDRE   => clrTDRE, 
            clrRDRF   => clrRDRF,   
            clrOE     => clrOE, 
            clrFE     => clrFE,    
            TDRE      => TDRE, 
            RDRF      => RDRF,     
            OE        => OE, 
            FE        => FE,      
            SCSR      => SCSR_Data         
        );

    clrTDRE <= TDR_WR;
    clrRDRF <= RDR_RD;
    clrOE   <= RDR_RD;
    clrFE   <= RDR_RD;

    tdrReg: nBitRegister
        GENERIC MAP(n => 8)
        PORT MAP(
            i_resetBar  => GReset,	
            i_load      => TDR_WR,
            i_clock     => GClock,
            i_Value     => DataBus_In,
            o_Value     => TDR_Data
        );

    transmitter: transmitterFSM 
        GENERIC MAP(
            dataLen     => 8,
            counterLen  => 4)
        PORT MAP(
            BaudClk     => BaudClk,          
            GClock      => GClock,
            GReset      => GReset,
            tdrData     => TDR_Data,
            TDRE        => tdre_to_tx_sync, 
            loadFlag    => TX_loadFlag,
            doneFlag    => TX_doneFlag,
            shiftFlag   => TX_shiftFlag,   
            o_TX        => TXD,
            stateDebug  => TX_StateDebug    
        );

    receiver: receiverFSM 
        GENERIC MAP(
            dataLen     => 8,
            counterLen  => 4)
        PORT MAP(
            BClkD8     => BClkD8,
            GReset     => GReset,
            RXD        => rxd_sync,     
            RDRF       => rdrf_to_rx_sync, 
            rdrData    => RDR_Data,
            setRDRF    => setRDRF_raw,    
            setOE      => setOE_raw,   
            setFE      => setFE_raw,   
            stateDebug => RX_StateDebug
        );

    intGen: interruptLogic
        PORT MAP(
            TIE  => TIE, 
            RIE  => RIE,     
            TDRE => TDRE, 
            RDRF => RDRF,
            OE   => OE,  
            IRQ  => IRQ
        );

    DataBus_In <= Databus;

    databusMux: nBitMux4to1
        GENERIC MAP (n => 8)
        PORT MAP(
            s0 => ADDR(0),
            s1 => ADDR(1),
            x0 => RDR_Data,
            x1 => SCSR_Data,
            x2 => SCCR_Data,
            x3 => SCCR_Data,
            y  => ReadData_Mux
        );
  
    busTristate: nBitTristate
        GENERIC MAP (n => 8)
        PORT MAP(
            enable => BUS_EN,
            input  => ReadData_Mux,
            output => Databus
        );

    stateOut <= "00";

END structural;