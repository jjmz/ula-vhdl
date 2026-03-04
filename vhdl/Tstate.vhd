library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Tstate is
    Port ( EXEC :  in STD_LOGIC;
           M1_n :  in STD_LOGIC;
			  CLK65:  in STD_LOGIC;
		     DATA6 : in STD_LOGIC;
			  RESET : in STD_LOGIC;
			  
		     cycle_T2 :    out STD_LOGIC;
           ncycle_T3T4 : out STD_LOGIC;
           mid_T2T3 :    out STD_LOGIC;
           end_T4 :      out STD_LOGIC);
end Tstate;

architecture Behavioral of Tstate is

	type t_m1 is (Idle, T2a, T2b, T3a, T3b, T4a, T4e);
	signal next_state, state: t_m1;
	
begin

   SYNC_PROC: process (CLK65, RESET)
   begin
	   if RESET='1' then
		   state <= Idle;
      elsif (CLK65'event and CLK65 = '1') then
         state <= next_state;
      end if;
   end process;

	process (state, EXEC, M1_n, DATA6)
	begin
		cycle_T2 <= '0';
		ncycle_T3T4 <= '1';
		mid_T2T3 <= '0';
		end_T4 <= '0';
		next_state <= state;
		
		case state is
			when Idle =>
				if EXEC='1' and (M1_n='0') then
					next_state <= T2a;
				end if;
			when T2a =>
				cycle_T2 <= '1';
				next_state <= T2b;
				if (DATA6='1') then
					next_state <= Idle;
				end if;
			when T2b =>
				mid_T2T3 <= '1';
				next_state <= T3a;
				--if (M1_n='0') then
				--	next_state <= Idle;
				--end if;
			when T3a =>
				mid_T2T3 <= '1';
				ncycle_T3T4 <= '0';
				next_state <= T3b;
			when T3b =>
				ncycle_T3T4 <= '0';
				next_state <= T4a;
			when T4a =>
				ncycle_T3T4 <= '0';
				next_state <= T4e;
			when T4e =>
				ncycle_T3T4 <= '0';
				end_T4   <= '1';
				next_state <= Idle;
		end case;
	end process;
	
end Behavioral;

