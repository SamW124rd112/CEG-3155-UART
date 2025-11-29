--------------------------------------------------------------------------------
-- UART FSM Simple Testbench
-- Uses fixed bit period based on baud rate selection
-- No auto-detection - directly calculates timing from baud generator specs
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_uartFSM IS
END tb_uartFSM;

ARCHITECTURE behavioral OF tb_uartFSM IS

    ---------------------------------------------------------------------------
    -- Component Declaration
    ---------------------------------------------------------------------------
    COMPONENT uartFSM
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
    END COMPONENT;
    
    ---------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------
    constant CLK_PERIOD     : time := 20 ns;  -- 50 MHz
    
    -- Bit periods calculated from baud generator:
    -- Base: 50MHz, counter divides by 41, then TFF divides by 2 = 609.76 kHz
    -- Then each stage divides by 2 more
    -- SEL=0: div_chain_q(0) period = 41 * 2 * 2 * 20ns = 3280 ns
    -- SEL=7: div_chain_q(7) period = 41 * 2 * 256 * 20ns = 419840 ns
    
    type time_array is array (0 to 7) of time;
   
    constant BIT_PERIODS : time_array := (
        3200 ns,    -- SEL=0 (was 3280)
        6400 ns,    -- SEL=1 (was 6560)
        12800 ns,   -- SEL=2 (was 13120)
        25600 ns,   -- SEL=3 (was 26240)
        51200 ns,   -- SEL=4 (was 52480)
        102400 ns,  -- SEL=5 (was 104960)
        204800 ns,  -- SEL=6 (was 209920)
        409600 ns   -- SEL=7 (was 419840)
    );
        
    -- Use SEL=0 for fastest simulation
    constant BAUD_SEL       : integer := 0;
    constant BIT_PERIOD     : time := BIT_PERIODS(BAUD_SEL);
    
    -- Address Constants
    constant ADDR_TDR       : std_logic_vector(1 downto 0) := "00";
    constant ADDR_RDR       : std_logic_vector(1 downto 0) := "00";
    constant ADDR_SCSR      : std_logic_vector(1 downto 0) := "01";
    constant ADDR_SCCR      : std_logic_vector(1 downto 0) := "10";

    ---------------------------------------------------------------------------
    -- Signals
    ---------------------------------------------------------------------------
    signal GClock           : std_logic := '0';
    signal GReset           : std_logic := '0';
    signal UART_Select      : std_logic := '0';
    signal ADDR             : std_logic_vector(1 downto 0) := "00";
    signal RWFlag           : std_logic := '0';
    signal RXD              : std_logic := '1';
    signal TXD              : std_logic;
    signal IRQ              : std_logic;
    signal Databus          : std_logic_vector(7 downto 0);
    signal stateOut         : std_logic_vector(1 downto 0);
    signal TX_StateDebug    : std_logic_vector(2 downto 0);
    signal RX_StateDebug    : std_logic_vector(2 downto 0);
    
    signal Databus_Drive    : std_logic_vector(7 downto 0) := (others => 'Z');
    signal Drive_Bus        : std_logic := '0';
    signal sim_done         : boolean := false;
    
    -- Test tracking
    signal tests_passed     : integer := 0;
    signal tests_failed     : integer := 0;

BEGIN

    Databus <= Databus_Drive when Drive_Bus = '1' else (others => 'Z');

    ---------------------------------------------------------------------------
    -- DUT Instantiation
    ---------------------------------------------------------------------------
    DUT: uartFSM
        PORT MAP(
            GClock        => GClock,
            GReset        => GReset,
            UART_Select   => UART_Select,
            ADDR          => ADDR,
            RWFlag        => RWFlag,
            RXD           => RXD,
            TXD           => TXD,
            IRQ           => IRQ,
            Databus       => Databus,
            stateOut      => stateOut,
            TX_StateDebug => TX_StateDebug,
            RX_StateDebug => RX_StateDebug
        );

    ---------------------------------------------------------------------------
    -- Clock Generation
    ---------------------------------------------------------------------------
    clk_gen: process
    begin
        while not sim_done loop
            GClock <= '0';
            wait for CLK_PERIOD/2;
            GClock <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    ---------------------------------------------------------------------------
    -- Main Test Process
    ---------------------------------------------------------------------------
    main_test: process
    
        procedure wait_clocks(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(GClock);
            end loop;
        end procedure;
        
        procedure write_reg(
            addr_val : std_logic_vector(1 downto 0);
            data_val : std_logic_vector(7 downto 0)
        ) is
        begin
            wait until rising_edge(GClock);
            UART_Select <= '1';
            ADDR <= addr_val;
            RWFlag <= '0';
            Databus_Drive <= data_val;
            Drive_Bus <= '1';
            wait_clocks(3);
            UART_Select <= '0';
            Drive_Bus <= '0';
            Databus_Drive <= (others => 'Z');
            wait_clocks(1);
        end procedure;
        
        procedure read_reg(
            addr_val : std_logic_vector(1 downto 0);
            data_out : out std_logic_vector(7 downto 0)
        ) is
        begin
            wait until rising_edge(GClock);
            UART_Select <= '1';
            ADDR <= addr_val;
            RWFlag <= '1';
            Drive_Bus <= '0';
            wait_clocks(3);
            data_out := Databus;
            UART_Select <= '0';
            wait_clocks(1);
        end procedure;
        
        -- Capture TX byte using FIXED bit period (no auto-detect)
        procedure capture_tx_byte(
            captured : out std_logic_vector(7 downto 0);
            success  : out boolean;
            timeout  : time
        ) is
            variable start_time : time;
        begin
            success := false;
            start_time := now;
            
            -- Wait for start bit (falling edge on TXD)
            while TXD = '1' loop
                wait for CLK_PERIOD;
                if (now - start_time) > timeout then
                    report "TX capture timeout waiting for start bit" severity warning;
                    return;
                end if;
            end loop;
            
            report "TX: Start bit detected at " & time'image(now);
            
            -- Wait to middle of start bit
            wait for BIT_PERIOD / 2;
            
            -- Verify we're still in start bit
            if TXD /= '0' then
                report "TX: Invalid start bit (not low at midpoint)" severity warning;
                return;
            end if;
            
            -- Sample 8 data bits at middle of each bit period
            for i in 0 to 7 loop
                wait for BIT_PERIOD;
                captured(i) := TXD;
            end loop;
            
            -- Check stop bit
            wait for BIT_PERIOD;
            if TXD /= '1' then
                report "TX: Invalid stop bit" severity warning;
                return;
            end if;
            
            success := true;
            report "TX: Frame captured successfully";
        end procedure;
        
        -- Send RX byte using FIXED bit period
        procedure send_rx_byte(data_val : std_logic_vector(7 downto 0)) is
        begin
            report "RX: Sending byte 0x" & integer'image(to_integer(unsigned(data_val)));
            
            -- Start bit
            RXD <= '0';
            wait for BIT_PERIOD;
            
            -- Data bits (LSB first)
            for i in 0 to 7 loop
                RXD <= data_val(i);
                wait for BIT_PERIOD;
            end loop;
            
            -- Stop bit
            RXD <= '1';
            wait for BIT_PERIOD * 2;
        end procedure;
        
        procedure check_test(name : string; condition : boolean) is
        begin
            if condition then
                report "PASS: " & name severity note;
                tests_passed <= tests_passed + 1;
            else
                report "FAIL: " & name severity error;
                tests_failed <= tests_failed + 1;
            end if;
            wait for CLK_PERIOD;
        end procedure;
        
        variable rd_data    : std_logic_vector(7 downto 0);
        variable tx_data    : std_logic_vector(7 downto 0);
        variable success    : boolean;
        
    begin
        report "================================================================";
        report "         UART FSM SIMPLE TESTBENCH";
        report "         SEL = " & integer'image(BAUD_SEL);
        report "         Bit Period = " & time'image(BIT_PERIOD);
        report "================================================================";
        
        -- Initialize
        GReset <= '0';
        RXD <= '1';
        wait for CLK_PERIOD * 10;
        
        -- Release reset
        GReset <= '1';
        wait for CLK_PERIOD * 20;
        
        -- Configure baud rate (SEL bits in lower 3 bits of SCCR)
        write_reg(ADDR_SCCR, std_logic_vector(to_unsigned(BAUD_SEL, 8)));
        wait for CLK_PERIOD * 10;
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 1: Initial State ===" severity note;
        -----------------------------------------------------------------------
        check_test("TXD idle high", TXD = '1');
        check_test("IRQ low", IRQ = '0');
        
        read_reg(ADDR_SCSR, rd_data);
        report "SCSR after reset: 0x" & integer'image(to_integer(unsigned(rd_data)));
        check_test("TDRE=1 after reset", rd_data(7) = '1');
        check_test("RDRF=0 after reset", rd_data(6) = '0');
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 2: TX Pattern 0x55 (01010101) ===" severity note;
        -----------------------------------------------------------------------
        write_reg(ADDR_TDR, x"55");
        
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0x55 frame captured", success);
        if success then
            report "TX captured data: 0x" & integer'image(to_integer(unsigned(tx_data)));
            check_test("TX 0x55 data correct", tx_data = x"55");
        end if;
        
        -- Wait and verify TDRE
        wait for BIT_PERIOD * 3;
        read_reg(ADDR_SCSR, rd_data);
        check_test("TDRE=1 after TX complete", rd_data(7) = '1');
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 3: TX Pattern 0xAA (10101010) ===" severity note;
        -----------------------------------------------------------------------
        write_reg(ADDR_TDR, x"AA");
        
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0xAA frame captured", success);
        if success then
            report "TX captured data: 0x" & integer'image(to_integer(unsigned(tx_data)));
            check_test("TX 0xAA data correct", tx_data = x"AA");
        end if;
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 4: TX Pattern 0x00 (all zeros) ===" severity note;
        -----------------------------------------------------------------------
        wait for BIT_PERIOD * 3;
        write_reg(ADDR_TDR, x"00");
        
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0x00 frame captured", success);
        if success then
            report "TX captured data: 0x" & integer'image(to_integer(unsigned(tx_data)));
            check_test("TX 0x00 data correct", tx_data = x"00");
        end if;
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 5: TX Pattern 0xFF (all ones) ===" severity note;
        -----------------------------------------------------------------------
        wait for BIT_PERIOD * 3;
        write_reg(ADDR_TDR, x"FF");
        
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0xFF frame captured", success);
        if success then
            report "TX captured data: 0x" & integer'image(to_integer(unsigned(tx_data)));
            check_test("TX 0xFF data correct", tx_data = x"FF");
        end if;
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 6: TX Pattern 0xA5 ===" severity note;
        -----------------------------------------------------------------------
        wait for BIT_PERIOD * 3;
        write_reg(ADDR_TDR, x"A5");
        
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0xA5 frame captured", success);
        if success then
            report "TX captured data: 0x" & integer'image(to_integer(unsigned(tx_data)));
            check_test("TX 0xA5 data correct", tx_data = x"A5");
        end if;
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 7: RX Pattern 0xA5 ===" severity note;
        -----------------------------------------------------------------------
        -- Clear any pending data
        read_reg(ADDR_RDR, rd_data);
        wait_clocks(100);
        
        send_rx_byte(x"A5");
        
        -- Wait for reception to complete
        wait for BIT_PERIOD * 5;
        
        read_reg(ADDR_SCSR, rd_data);
        report "SCSR after RX: 0x" & integer'image(to_integer(unsigned(rd_data)));
        check_test("RDRF=1 after RX", rd_data(6) = '1');
        
        read_reg(ADDR_RDR, rd_data);
        report "RX received data: 0x" & integer'image(to_integer(unsigned(rd_data)));
        check_test("RX 0xA5 data correct", rd_data = x"A5");
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 8: RX Pattern 0x5A ===" severity note;
        -----------------------------------------------------------------------
        send_rx_byte(x"5A");
        wait for BIT_PERIOD * 5;
        
        read_reg(ADDR_SCSR, rd_data);
        check_test("RDRF=1 after RX", rd_data(6) = '1');
        
        read_reg(ADDR_RDR, rd_data);
        report "RX received data: 0x" & integer'image(to_integer(unsigned(rd_data)));
        check_test("RX 0x5A data correct", rd_data = x"5A");
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 9: RX Pattern 0x00 ===" severity note;
        -----------------------------------------------------------------------
        send_rx_byte(x"00");
        wait for BIT_PERIOD * 5;
        
        read_reg(ADDR_SCSR, rd_data);
        check_test("RDRF=1 after RX", rd_data(6) = '1');
        
        read_reg(ADDR_RDR, rd_data);
        report "RX received data: 0x" & integer'image(to_integer(unsigned(rd_data)));
        check_test("RX 0x00 data correct", rd_data = x"00");
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 10: RX Pattern 0xFF ===" severity note;
        -----------------------------------------------------------------------
        send_rx_byte(x"FF");
        wait for BIT_PERIOD * 5;
        
        read_reg(ADDR_SCSR, rd_data);
        check_test("RDRF=1 after RX", rd_data(6) = '1');
        
        read_reg(ADDR_RDR, rd_data);
        report "RX received data: 0x" & integer'image(to_integer(unsigned(rd_data)));
        check_test("RX 0xFF data correct", rd_data = x"FF");
        
        -----------------------------------------------------------------------
        report "=== TEST GROUP 11: Back-to-back TX ===" severity note;
        -----------------------------------------------------------------------
        wait for BIT_PERIOD * 3;
        
        -- First byte
        write_reg(ADDR_TDR, x"12");
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0x12 frame captured", success);
        if success then
            check_test("TX 0x12 data correct", tx_data = x"12");
        end if;
        
        -- Second byte immediately after
        write_reg(ADDR_TDR, x"34");
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0x34 frame captured", success);
        if success then
            check_test("TX 0x34 data correct", tx_data = x"34");
        end if;
        
        -- Third byte
        write_reg(ADDR_TDR, x"56");
        capture_tx_byte(tx_data, success, BIT_PERIOD * 15);
        check_test("TX 0x56 frame captured", success);
        if success then
            check_test("TX 0x56 data correct", tx_data = x"56");
        end if;
        
        -----------------------------------------------------------------------
        -- Summary
        -----------------------------------------------------------------------
        wait for CLK_PERIOD * 100;
        
        report "================================================================";
        report "                    TEST SUMMARY";
        report "================================================================";
        report "Total Passed: " & integer'image(tests_passed);
        report "Total Failed: " & integer'image(tests_failed);
        report "================================================================";
        
        if tests_failed = 0 then
            report "########## ALL TESTS PASSED ##########" severity note;
        else
            report "########## " & integer'image(tests_failed) & " TESTS FAILED ##########" 
                severity error;
        end if;
        
        report "================================================================";
        
        sim_done <= true;
        wait for CLK_PERIOD * 10;
        
        assert false report "Simulation complete" severity failure;
        wait;
        
    end process;

END behavioral;
