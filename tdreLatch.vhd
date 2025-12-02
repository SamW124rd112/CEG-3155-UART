LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tdreLatch IS
    PORT(
        GClock      : IN  STD_LOGIC;
        GReset      : IN  STD_LOGIC;
        scsr_valid  : IN  STD_LOGIC;
        dataBus_bit7: IN  STD_LOGIC;
        tdre_out    : OUT STD_LOGIC
    );
END tdreLatch;

ARCHITECTURE structural OF tdreLatch IS

    COMPONENT enARdFF_2
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_d         : IN  STD_LOGIC;
            i_enable    : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT oneBitMux2to1
        PORT(
            s, x0, x1 : IN  STD_LOGIC;
            y         : OUT STD_LOGIC);
    END COMPONENT;

    SIGNAL tdre_current : STD_LOGIC;
    SIGNAL tdre_next    : STD_LOGIC;
    SIGNAL tdre_bar     : STD_LOGIC;

BEGIN

    mux_tdre: oneBitMux2to1
        PORT MAP(
            s  => scsr_valid,
            x0 => tdre_current, 
            x1 => dataBus_bit7,
            y  => tdre_next
        );
    
    ff_tdre: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => tdre_next,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => tdre_current,
            o_qBar     => tdre_bar
        );

    tdre_out <= tdre_current;

END structural;