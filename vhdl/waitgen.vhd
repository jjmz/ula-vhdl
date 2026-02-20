library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity waitgen is
    Port ( halt_n : in  STD_LOGIC;
           nmi : in  STD_LOGIC;
           nowait_sw : in  STD_LOGIC;
           wait_n : out  STD_LOGIC);
end waitgen;

architecture Behavioral of waitgen is

signal nowait_armed: std_logic;

begin

wait_n <= nmi or (not halt_n) when nowait_sw='0'       -- i.e. NMI or not HALT
    else  nmi or (not nowait_armed) ;

-- NoWait, based on Wilf Rigter Mod

process(halt_n,nmi)
begin
   if nmi = '1' then
      nowait_armed <= '0';
   elsif (halt_n'event and halt_n= '1') then
      nowait_armed <= '1';
   end if;
end process;

end Behavioral;

