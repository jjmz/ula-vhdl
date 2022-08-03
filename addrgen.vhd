library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity addrgen is
    Port ( D : in  STD_LOGIC_VECTOR (7 downto 0);
           LATCH_EN : in  STD_LOGIC;
			  CLK : in STD_LOGIC;
           INCA : in  STD_LOGIC;
           RSTA : in  STD_LOGIC;
           A : inout  STD_LOGIC_VECTOR (8 downto 0);
           EN_OUT : in  STD_LOGIC;
           INV : out  STD_LOGIC);
end addrgen;

architecture Behavioral of addrgen is

signal LCNT: std_logic_vector(2 downto 0) :="000";
signal CHAR: std_logic_vector(7 downto 0);

begin

process (INCA, RSTA) 
begin
   if RSTA='1' then 
      LCNT <= (others => '0');
   elsif INCA='1' and INCA'event then
      LCNT <= LCNT + 1;
   end if;
end process;

-- Latch Data @ T2.5 (falling edge of CPU_CLK)
-- CHAR <= D 
LATCH_FDCE: for ii in 0 to 7 generate
 inst_FDCEx: FDCE
  port map (
		Q => CHAR(ii),
		C => not CLK,
		CE => LATCH_EN,
		CLR => '0',
		D => D(ii)
	);
end generate LATCH_FDCE;

A <= CHAR(5 downto 0)&LCNT when EN_OUT='1' else (others => 'Z');
INV <= CHAR(7);

end Behavioral;

