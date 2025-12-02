LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY addressDecoder IS
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
END addressDecoder;

ARCHITECTURE structural OF addressDecoder IS

    SIGNAL addr0_n, addr1_n, rw_n : STD_LOGIC;
    SIGNAL addr_00, addr_01, addr_1x : STD_LOGIC;
    SIGNAL read_en, write_en : STD_LOGIC;
    SIGNAL addr0_and_addr1_n : STD_LOGIC;

BEGIN

    addr0_n <= NOT ADDR(0);
    addr1_n <= NOT ADDR(1);
    rw_n    <= NOT R_W;

    addr_00 <= addr1_n AND addr0_n;       
    addr0_and_addr1_n <= addr1_n AND ADDR(0);
    addr_01 <= addr0_and_addr1_n;         
    addr_1x <= ADDR(1);                  

    read_en  <= UART_Select AND R_W;
    write_en <= UART_Select AND rw_n;

    RDR_RD  <= read_en AND addr_00;
    TDR_WR  <= write_en AND addr_00;
    SCSR_RD <= read_en AND addr_01;
    SCCR_RD <= read_en AND addr_1x;
    SCCR_WR <= write_en AND addr_1x;
    BUS_EN  <= read_en;

END structural;
