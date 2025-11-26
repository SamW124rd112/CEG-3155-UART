LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_receiverFSM IS
END tb_receiverFSM;

ARCHITECTURE behavior OF tb_receiverFSM IS

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
            rdrData       : OUT STD_LOGIC_VECTOR(7 downto 0);
            setRDRF       : OUT STD_LOGIC;
            setOE         : OUT STD_LOGIC;
            setFE         : OUT STD_LOGIC;
            stateDebug    : OUT STD_LOGIC_VECTOR(2 downto 0)
        );
    END COMPONENT;
    
    function slv_to_int(slv : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(slv));
    end function;
    
    -- Test signals
    signal BClkD8       : STD_LOGIC := '0';
    signal GReset       : STD_LOGIC := '0';
    signal RXD          : STD_LOGIC := '1';
    signal RDRF         : STD_LOGIC := '0';
    signal rdrData      : STD_LOGIC_VECTOR(7 downto 0);
    signal setRDRF      : STD_LOGIC;
    signal setOE        : STD_LOGIC;
    signal setFE        : STD_LOGIC;
    signal stateDebug   : STD_LOGIC_VECTOR(2 downto 0);
    
    -- Captured flag signals (simulates status register behavior)
    signal fe_captured  : STD_LOGIC := '0';
    signal rdrf_captured: STD_LOGIC := '0';
    signal oe_captured  : STD_LOGIC := '0';
    signal clear_flags  : STD_LOGIC := '0';
    
    -- Timing
    constant bclkd8_period : time := 100 ns;
    constant bit_period    : time := 800 ns;
    
    signal sim_done : boolean := false;
    signal total_tests : integer := 0;
    signal passed_tests : integer := 0;
    
BEGIN

    uut: receiverFSM 
        GENERIC MAP(
            dataLen    => 8,
            counterLen => 4
        )
        PORT MAP (
            BClkD8     => BClkD8,
            GReset     => GReset,
            RXD        => RXD,
            RDRF       => RDRF,
            rdrData    => rdrData,
            setRDRF    => setRDRF,
            setOE      => setOE,
            setFE      => setFE,
            stateDebug => stateDebug
        );

    -- BClkD8 generation
    bclkd8_process: process
    begin
        while not sim_done loop
            BClkD8 <= '0';
            wait for bclkd8_period/2;
            BClkD8 <= '1';
            wait for bclkd8_period/2;
        end loop;
        wait;
    end process;

    -- Flag capture process (simulates SCSR status register)
    -- Captures pulses from setRDRF, setOE, setFE
    flag_capture: process(BClkD8, GReset)
    begin
        if GReset = '0' then
            fe_captured <= '0';
            rdrf_captured <= '0';
            oe_captured <= '0';
        elsif rising_edge(BClkD8) then
            if clear_flags = '1' then
                fe_captured <= '0';
                rdrf_captured <= '0';
                oe_captured <= '0';
            else
                if setFE = '1' then
                    fe_captured <= '1';
                end if;
                if setRDRF = '1' then
                    rdrf_captured <= '1';
                end if;
                if setOE = '1' then
                    oe_captured <= '1';
                end if;
            end if;
        end if;
    end process;

    stim_process: process
        procedure send_byte(
            data : std_logic_vector(7 downto 0);
            bad_stop : boolean := false
        ) is
        begin
            report "  Sending byte: " & integer'image(slv_to_int(data)) &
                   " (binary: " & 
                   std_logic'image(data(7))(2) & std_logic'image(data(6))(2) &
                   std_logic'image(data(5))(2) & std_logic'image(data(4))(2) &
                   std_logic'image(data(3))(2) & std_logic'image(data(2))(2) &
                   std_logic'image(data(1))(2) & std_logic'image(data(0))(2) & ")";
            
            -- Start bit (0)
            RXD <= '0';
            wait for bit_period;
            
            -- 8 data bits (LSB first)
            for i in 0 to 7 loop
                RXD <= data(i);
                wait for bit_period;
            end loop;
            
            -- Stop bit
            if bad_stop then
                RXD <= '0';
                report "  (Intentionally sending bad stop bit = 0)";
            else
                RXD <= '1';
            end if;
            wait for bit_period;
            
            -- Return to idle
            RXD <= '1';
        end procedure;
        
        procedure verify_data(
            expected : std_logic_vector(7 downto 0);
            test_name : string
        ) is
        begin
            total_tests <= total_tests + 1;
            wait for 2 us;
            
            report "----------------------------------------";
            report "TEST: " & test_name;
            report "  Expected: " & integer'image(slv_to_int(expected));
            report "  Received: " & integer'image(slv_to_int(rdrData));
            report "  State: " & integer'image(slv_to_int(stateDebug));
            report "  RDRF captured: " & std_logic'image(rdrf_captured);
            report "  FE captured: " & std_logic'image(fe_captured);
            
            if rdrData = expected and fe_captured = '0' then
                report "  RESULT: PASS" severity note;
                passed_tests <= passed_tests + 1;
            else
                report "  RESULT: FAIL" severity error;
            end if;
            
            -- Clear flags for next test
            clear_flags <= '1';
            wait for bclkd8_period * 2;
            clear_flags <= '0';
        end procedure;
        
        procedure verify_framing_error(test_name : string) is
        begin
            total_tests <= total_tests + 1;
            wait for 2 us;
            
            report "----------------------------------------";
            report "TEST: " & test_name;
            report "  FE captured: " & std_logic'image(fe_captured);
            report "  State: " & integer'image(slv_to_int(stateDebug));
            
            if fe_captured = '1' then
                report "  RESULT: PASS (Framing error captured)" severity note;
                passed_tests <= passed_tests + 1;
            else
                report "  RESULT: FAIL (Framing error not captured)" severity error;
            end if;
            
            -- Clear flags for next test
            clear_flags <= '1';
            wait for bclkd8_period * 2;
            clear_flags <= '0';
        end procedure;
        
    begin
        RXD <= '1';
        RDRF <= '0';
        clear_flags <= '0';
        
        -- Reset
        GReset <= '0';
        wait for 500 ns;
        GReset <= '1';
        wait for 500 ns;
        
        report "========================================";
        report "Starting receiverFSM Test Suite";
        report "========================================";
        
        -- Test 1: 0x55
        wait for 2 us;
        send_byte("01010101");
        verify_data("01010101", "Receive 0x55");
        
        RDRF <= '0';
        wait for 2 us;
        
        -- Test 2: 0xAA
        send_byte("10101110");
        verify_data("10101110", "Receive 0xAA");

        RDRF <= '0';
        wait for 2 us;
        
        -- Test 3: 0xFF
        send_byte("11111111");
        verify_data("11111111", "Receive 0xFF");
        
        RDRF <= '0';
        wait for 2 us;
        
        -- Test 4: 0x00
        send_byte("00000000");
        verify_data("00000000", "Receive 0x00");
        
        RDRF <= '0';
        wait for 2 us;
        
        -- Test 5: Framing error (bad stop bit)
        send_byte("11111111", bad_stop => true);
        verify_framing_error("Framing error detection");
        
        wait for 2 us;
        
        report "========================================";
        report "Total: " & integer'image(total_tests);
        report "Passed: " & integer'image(passed_tests);
        report "========================================";
        
        if passed_tests = total_tests then
            report "ALL TESTS PASSED!" severity note;
        else
            report "SOME TESTS FAILED!" severity error;
        end if;
        
        sim_done <= true;
        wait;
    end process;

END behavior;
