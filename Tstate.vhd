library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Tstate is
    Port ( EXEC : in  STD_LOGIC;
           CLK : in  STD_LOGIC;           
			  T2c: out STD_LOGIC;
           nT34 : out  STD_LOGIC;
           T2L : out  STD_LOGIC;
           T4H : out  STD_LOGIC);
end Tstate;

architecture Behavioral of Tstate is

   signal T2,T3,T4: std_logic; 
	signal hT2,hT4: std_logic;
	
begin

   SYNC_PROC: process (CLK)
   begin
      if (CLK'event and CLK = '1') then
         T2 <= (not (T2 or T3 or T4)) and EXEC;
			T3 <= T2;
			T4 <= T3;
      end if;
   end process;

	T2c <= T2;
	nT34 <= '0' when (T3 = '1' or T4 = '1') else '1';
	
	HALF_CYCLE: process (T2, T4, CLK)
	begin
      if (CLK'event and CLK = '0') then
			hT2 <= T2;
			hT4 <= T4;
		end if;
	end process;

	T2L <= hT2;					-- T2 delayed by 1/2 clk
	T4H <= hT4 and T4;		-- end of T4 cycle
	
end Behavioral;

