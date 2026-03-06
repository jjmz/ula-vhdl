library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clockgen2 is
    Port ( CLKIN :     in  STD_LOGIC;
           RESET_NMI : in  STD_LOGIC;
			  START     : in STD_LOGIC;
			  
           CLKOUT :  out  STD_LOGIC;
			  TURBOCLK: out  STD_LOGIC;
		     CNT_NMI : out  STD_LOGIC;
		     DBL_CLK : out  STD_LOGIC;           
           BACKP :   out  STD_LOGIC);
end clockgen2;

architecture Behavioral of clockgen2 is

signal NMICNT: std_logic_vector(7 downto 0) :="00000000";
signal DIVCNT: std_logic_vector(2 downto 0) :="000";

begin

process(CLKIN)
begin
   if rising_edge(CLKIN) then
		DIVCNT(0) <= not DIVCNT(0);
	end if;
end process;

process(DIVCNT(0))
begin
   if rising_edge(DIVCNT(0)) then
		DIVCNT(1) <= not DIVCNT(1);
	end if;
end process;

process(DIVCNT(1))
begin
   if rising_edge(DIVCNT(1)) then
		DIVCNT(2) <= not DIVCNT(2);
	end if;
end process;

TURBOCLK <= DIVCNT(0);
DBL_CLK  <= DIVCNT(1);		-- 26Mhz / 4 => 6.5  Mhz (Pixel Shift)
CLKOUT   <= DIVCNT(2);		-- 26Mhz / 8 => 3.25 Mhz (CPU)

process (DIVCNT(2), RESET_NMI, START) 		-- counter 0-206 (207 cycles)
begin
   if RESET_NMI='1' then 
      NMICNT <= "00"&START&"00000";
   elsif rising_edge(DIVCNT(2)) then
		if NMICNT = 206 then
			NMICNT <= (others => '0');
		else
         NMICNT <= NMICNT + 1;
		end if;
   end if;
end process;

BACKP   <= '1' when NMICNT(7 downto 4)="0010" else '0';   -- 32 to 63 -> BPorch
CNT_NMI <= '1' when NMICNT(7 downto 4)="0001" else '0';   -- 16 to 31 -> NMI

end Behavioral;

