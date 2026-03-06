library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity waitgen is
    Port ( halt_n : in  STD_LOGIC;
           nmi_n : in  STD_LOGIC;
           nowait_sw : in  STD_LOGIC;
           wait_n : out  STD_LOGIC);
end waitgen;

architecture Behavioral of waitgen is

signal nowait_armed: std_logic;			-- HALT in NMI interruption -> allow wait
signal enable_wait : std_logic;

begin

enable_wait <= halt_n when nowait_sw='0' else nowait_armed;			-- wait only if '1'
wait_n <= nmi_n or (not enable_wait);

--wait_n <= nmi or (not halt_n);   -- i.e. NMI or not HALT

-- NoWait, based on Wilf Rigter Mod

process(halt_n,nmi_n)
begin
   if nmi_n = '1' then
      nowait_armed <= '0';
   elsif rising_edge(halt_n) then
      nowait_armed <= '1';
   end if;
end process;

end Behavioral;

