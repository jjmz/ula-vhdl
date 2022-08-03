library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shifter2 is
    Port ( LOAD : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           CARRYIN : in  STD_LOGIC;
           D : in  STD_LOGIC_VECTOR (7 downto 0);
           INV : in  STD_LOGIC;
           SHIFTOUT : out  STD_LOGIC);
end shifter2;

architecture Behavioral of shifter2 is

signal REG: std_logic_vector(7 downto 0);

begin

process(CLK,LOAD)
begin
	if CLK='1' and CLK'event then
	   if (LOAD='1') then
			REG <= D xor (INV&INV&INV&INV&INV&INV&INV&INV);
		else
			REG <= REG(6 downto 0) & CARRYIN;
		end if;
	end if;
end process;

SHIFTOUT <= REG(7);

end Behavioral;

