LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_baudRateGen IS
END tb_baudRateGen;

ARCHITECTURE behavior OF tb_baudRateGen IS 

    -- Component Declaration
    COMPONENT baudRateGen
        PORT(
            SEL       : IN  STD_LOGIC_VECTOR(2 downto 0);
            in_Clock  : IN  STD_LOGIC;
            G_Reset   : IN  STD_LOGIC;
            baudClk   : OUT STD_LOGIC;
            BClkD8    : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- Test signals
    signal SEL       : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal in_Clock  : STD_LOGIC := '0';
    signal G_Reset   : STD_LOGIC := '0';
    signal baudClk   : STD_LOGIC;
    signal BClkD8    : STD_LOGIC;
    
    -- Clock period definition (50 MHz clock)
    constant clk_period : time := 20 ns;
    
    -- Simulation control
    signal sim_done : boolean := false;
    
    -- Test result tracking
    signal test_failed : boolean := false;
    signal total_tests : integer := 0;
    signal passed_tests : integer := 0;
    
BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: baudRateGen 
        PORT MAP (
            SEL      => SEL,
            in_Clock => in_Clock,
            G_Reset  => G_Reset,
            baudClk  => baudClk,
            BClkD8   => BClkD8
        );

    -- Clock generation process
    clk_process: process
    begin
        while not sim_done loop
            in_Clock <= '0';
            wait for clk_period/2;
            in_Clock <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Reset generation process
    reset_process: process
    begin
        G_Reset <= '0';  -- Assert reset (active low)
        wait for 100 ns;
        G_Reset <= '1';  -- Release reset
        wait;
    end process;

    -- Edge counting and verification process
    verify_process: process
        variable in_clk_count   : integer := 0;
        variable baud_clk_count : integer := 0;
        variable bclk8_count    : integer := 0;
        variable actual_div     : integer := 0;
        
        -- Procedure to reset counters
        procedure reset_counters is
        begin
            in_clk_count := 0;
            baud_clk_count := 0;
            bclk8_count := 0;
        end procedure;
        
        -- Fixed edge counting procedure
        procedure count_edges(duration : time) is
            variable start_time : time;
            variable prev_in_clk : std_logic := '0';
            variable prev_baud : std_logic := '0';
            variable prev_bclk8 : std_logic := '0';
        begin
            reset_counters;
            start_time := now;
            
            -- Initialize previous values
            prev_in_clk := in_Clock;
            prev_baud := baudClk;
            prev_bclk8 := BClkD8;
            
            while (now - start_time) < duration loop
                wait for clk_period / 10;  -- Sample at 10x clock rate
                
                -- Detect rising edges
                if in_Clock = '1' and prev_in_clk = '0' then
                    in_clk_count := in_clk_count + 1;
                end if;
                
                if baudClk = '1' and prev_baud = '0' then
                    baud_clk_count := baud_clk_count + 1;
                end if;
                
                if BClkD8 = '1' and prev_bclk8 = '0' then
                    bclk8_count := bclk8_count + 1;
                end if;
                
                -- Update previous values
                prev_in_clk := in_Clock;
                prev_baud := baudClk;
                prev_bclk8 := BClkD8;
            end loop;
        end procedure;
        
        -- Procedure to verify division ratio
        procedure verify_division(
            sel_value : std_logic_vector(2 downto 0);
            expected_divisor : integer;
            test_duration : time;
            test_description : string
        ) is
            variable actual_ratio : real;
            variable expected_ratio : real;
            variable error_percent : real;
            variable tolerance_percent : real := 3.0;  -- 3% tolerance
        begin
            total_tests <= total_tests + 1;
            
            report "========================================";
            report "TEST: " & test_description;
            report "SEL = " & integer'image(to_integer(unsigned(sel_value))) & 
                   ", Expected divisor = " & integer'image(expected_divisor);
            
            -- Wait for settling
            wait for 5 us;
            
            -- Count edges
            count_edges(test_duration);
            
            -- Calculate actual division ratio
            if baud_clk_count > 0 then
                actual_div := in_clk_count / baud_clk_count;
                actual_ratio := real(in_clk_count) / real(baud_clk_count);
                expected_ratio := real(expected_divisor);
                error_percent := abs((actual_ratio - expected_ratio) / expected_ratio) * 100.0;
                
                report "Input clock edges: " & integer'image(in_clk_count);
                report "Baud clock edges: " & integer'image(baud_clk_count);
                report "BClkD8 edges: " & integer'image(bclk8_count);
                report "Actual division ratio: " & real'image(actual_ratio);
                report "Expected division ratio: " & integer'image(expected_divisor);
                report "Error: " & real'image(error_percent) & "%";
                
                -- Check if within tolerance (percentage based)
                if error_percent <= tolerance_percent then
                    report "RESULT: PASS (within " & real'image(tolerance_percent) & "% tolerance)" severity note;
                    passed_tests <= passed_tests + 1;
                else
                    report "RESULT: FAIL - Division ratio incorrect!" severity error;
                    report "  Expected: " & integer'image(expected_divisor) & 
                           ", Got ratio: " & real'image(actual_ratio);
                    test_failed <= true;
                end if;
                
                -- Verify BClkD8 is 8x FASTER than baudClk (only if enough edges)
                if baud_clk_count >= 10 and bclk8_count > 0 then
                    -- Changed: Now BClkD8 should have 8x MORE edges than baudClk
                    actual_ratio := real(bclk8_count) / real(baud_clk_count);
                    error_percent := abs((actual_ratio - 8.0) / 8.0) * 100.0;
                    
                    report "BClkD8 check: BClkD8 edges = " & integer'image(bclk8_count) &
                           ", baudClk edges = " & integer'image(baud_clk_count) &
                           ", ratio = " & real'image(actual_ratio);
                    
                    if error_percent <= tolerance_percent then
                        report "BClkD8 speed: PASS (8x faster than baudClk)" severity note;
                    else
                        report "BClkD8 speed: FAIL (expected 8x faster, got ratio " & 
                               real'image(actual_ratio) & ")" severity error;
                        test_failed <= true;
                    end if;
                else
                    report "BClkD8 check: Not enough edges (need >10 baud edges)" severity note;
                end if;
            else
                report "RESULT: FAIL - No baudClk edges detected!" severity error;
                test_failed <= true;
            end if;
            
            report "========================================";
        end procedure;
        
    begin
        -- Wait for start
        wait for 1 ns;
        
        report "========================================";
        report "STARTING BAUD RATE GENERATOR TEST SUITE";
        report "Clock period: " & time'image(clk_period);
        report "========================================";
        
        -- Wait for reset to be released
        wait until G_Reset = '1';
        wait for 500 ns;
        
        -- Test SEL = 000 (÷164 = ÷82*2)
        -- Need ~100 baud edges: 100 * 164 * 20ns = 328us
        SEL <= "000";
        verify_division("000", 164, 500 us, "Divide by 164 (SEL=000)");
        
        -- Test SEL = 001 (÷328 = ÷82*4)
        -- Need ~100 baud edges: 100 * 328 * 20ns = 656us
        SEL <= "001";
        verify_division("001", 328, 1 ms, "Divide by 328 (SEL=001)");
        
        -- Test SEL = 010 (÷656 = ÷82*8)
        SEL <= "010";
        verify_division("010", 656, 2 ms, "Divide by 656 (SEL=010)");
        
        -- Test SEL = 011 (÷1312 = ÷82*16)
        SEL <= "011";
        verify_division("011", 1312, 4 ms, "Divide by 1312 (SEL=011)");
        
        -- Test SEL = 100 (÷2624 = ÷82*32)
        SEL <= "100";
        verify_division("100", 2624, 8 ms, "Divide by 2624 (SEL=100)");
        
        -- Test SEL = 101 (÷5248 = ÷82*64)
        SEL <= "101";
        verify_division("101", 5248, 16 ms, "Divide by 5248 (SEL=101)");
        
        -- Test SEL = 110 (÷10496 = ÷82*128)
        SEL <= "110";
        verify_division("110", 10496, 32 ms, "Divide by 10496 (SEL=110)");
        
        -- Test SEL = 111 (÷20992 = ÷82*256)
        SEL <= "111";
        verify_division("111", 20992, 64 ms, "Divide by 20992 (SEL=111)");
        
        -- Final report
        -- Final report
        wait for 1 us;
        report "========================================";
        report "TEST SUITE COMPLETE";
        report "========================================";
        report "Total tests: " & integer'image(total_tests);
        report "Passed: " & integer'image(passed_tests);
        report "Failed: " & integer'image(total_tests - passed_tests);

        -- FIXED: Check the actual counts instead of the test_failed signal
        if passed_tests /= total_tests then
            report "========================================";
            report "OVERALL RESULT: FAIL";
            report "========================================";
            assert false report "TEST SUITE FAILED!" severity failure;
        else
            report "========================================";
            report "OVERALL RESULT: PASS";
            report "========================================";
            report "All tests passed successfully!" severity note;
        end if;

        sim_done <= true;
        wait;
      end process;

END behavior;
