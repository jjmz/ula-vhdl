library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clockgen2 is
    Port ( CLKIN : in  STD_LOGIC;
           RESET_NMI : in  STD_LOGIC;
           CLKOUT : out  STD_LOGIC;
			  CNT_NMI : out  STD_LOGIC;
			  DBL_CLK : out  STD_LOGIC;           
           BACKP : out  STD_LOGIC);
end clockgen2;

architecture Behavioral of clockgen2 is

signal NMICNT: std_logic_vector(7 downto 0) :="00000000";
signal DIVCNT: std_logic_vector(2 downto 0) :="000";

begin

process(CLKIN)
begin
   if CLKIN='1' and CLKIN'event then
		DIVCNT <= DIVCNT + 1;
	end if;
end process;

DBL_CLK <= DIVCNT(1);		-- 26Mhz / 4 => 6.5  Mhz (Pixel Shift)
CLKOUT  <= DIVCNT(2);		-- 26Mhz / 8 => 3.25 Mhz (CPU)

process (DIVCNT(2), RESET_NMI) 
begin
   if RESET_NMI='1' then 
      NMICNT <= (others => '0');
   elsif DIVCNT(2)='1' and DIVCNT(2)'event then
		if NMICNT = 206 then
			NMICNT <= (others => '0');
		else
         NMICNT <= NMICNT + 1;
		end if;
   end if;
end process;

BACKP <= '1' when NMICNT(7 downto 4)="0010" else '0';   -- 31 to 64 -> BPorch
CNT_NMI <= '1' when NMICNT(7 downto 4)="0001" else '0'; -- 16 to 31 -> NMI

end Behavioral;

