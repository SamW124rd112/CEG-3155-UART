LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY resetToOneLatch IS
    PORT(
        GClock      : IN  STD_LOGIC;
        GReset      : IN  STD_LOGIC;
        enable      : IN  STD_LOGIC; 
        dataIn      : IN  STD_LOGIC; 
        dataOut     : OUT STD_LOGIC 
    );
END resetToOneLatch;

ARCHITECTURE structural OF resetToOneLatch IS

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

    SIGNAL stored_n     : STD_LOGIC; 
    SIGNAL stored       : STD_LOGIC; 
    SIGNAL next_n       : STD_LOGIC; 
    SIGNAL dataIn_n     : STD_LOGIC; 

BEGIN

    dataIn_n <= NOT dataIn;

    mux_data: oneBitMux2to1
        PORT MAP(
            s  => enable,
            x0 => stored_n, 
            x1 => dataIn_n, 
            y  => next_n
        );


    ff_storage: enARdFF_2
        PORT MAP(
            i_resetBar => GReset,
            i_d        => next_n,
            i_enable   => '1',
            i_clock    => GClock,
            o_q        => stored_n,
            o_qBar     => stored 
        );

    dataOut <= stored;

END structural;