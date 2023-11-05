library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Tstate is
    Port ( EXEC :  in STD_LOGIC;
           M1_n :  in STD_LOGIC;
           CLK :   in STD_LOGIC; 
		   DATA6 : in STD_LOGIC;

		   cycle_T2 :    out STD_LOGIC;
           ncycle_T3T4 : out STD_LOGIC;
           mid_T2T3 :    out STD_LOGIC;
           end_T4 :      out STD_LOGIC);
end Tstate;

architecture Behavioral of Tstate is

   signal T2,T3,T4 :   std_logic := '0'; 
   signal hT2,hT3,hT4: std_logic := '0';
   signal prev_M1_n :  std_logic;
	
begin

   SYNC_PROC: process (CLK)
   begin
      if (CLK'event and CLK = '1') then
            prev_M1_n <= M1_n;

            T2 <= (not (T2 or T3 or T4)) and EXEC and (not M1_n) and prev_M1_n;
			T3 <= hT2;
			T4 <= hT3;
      end if;
   end process;

   cycle_T2 <= T2;
   ncycle_T3T4 <= '0' when (T3 = '1' or T4 = '1') else '1';
	
   HALF_CYCLE: process (CLK, T2, T4, DATA6)
   begin
      if (CLK'event and CLK = '0') then
			hT2 <= T2 and (not DATA6);      -- Stop if Data6='1'
            hT3 <= T3 and M1_n;             -- Stop if M1_n still '0' (Wait ?)
			hT4 <= T4;
      end if;
   end process;

	mid_T2T3 <= hT2;			-- T2 delayed by 1/2 clk
	end_T4   <= hT4 and T4;		-- end of T4 cycle
	
end Behavioral;

