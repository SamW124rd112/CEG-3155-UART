LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY oneBitAddSubUnit IS
    PORT(
        i_Ai, i_Bi     : IN  STD_LOGIC;
        i_OpFlag       : IN  STD_LOGIC;
        i_CarryIn      : IN  STD_LOGIC;
        o_Sum, o_CarryOut : OUT STD_LOGIC
    );
END oneBitAddSubUnit;

ARCHITECTURE rtl OF oneBitAddSubUnit IS
    SIGNAL xor_Bi, xorABi, andABi, andABCi : STD_LOGIC;
BEGIN
    xor_Bi  <= i_Bi xor i_OpFlag;
    xorABi  <= i_Ai xor xor_Bi;
    andABi  <= i_Ai and xor_Bi;
    andABCi <= i_CarryIn and xorABi;

    o_Sum      <= i_CarryIn xor xorABi;
    o_CarryOut <= andABCi or andABi;
END rtl;

