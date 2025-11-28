LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY oneBitTristate IS
    PORT(
        enable : IN  STD_LOGIC;
        input   : IN  STD_LOGIC;
        output  : OUT STD_LOGIC
    );
END oneBitTristate;

ARCHITECTURE behavioral OF oneBitTristate IS
BEGIN
    -- Tristate is a primitive/atomic gate
    -- Behavioral is acceptable at this level
    output <= input WHEN enable = '1' ELSE 'Z';
END behavioral;
