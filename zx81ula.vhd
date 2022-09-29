library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity zx81ula is
    Port ( MAINCLK : in  STD_LOGIC;
           Z80_CLK : out  STD_LOGIC;

           IORQ, MREQ : in  STD_LOGIC;
           RD, WR :     in  STD_LOGIC;
           M1, HALT :   in  STD_LOGIC;
           
           NMI :   out  STD_LOGIC;
           WAITs : out  STD_LOGIC;
			  
			  Ah : in  STD_LOGIC_VECTOR(15 downto 13);
           A : inout  STD_LOGIC_VECTOR(8 downto 0);
			  D : inout  STD_LOGIC_VECTOR(7 downto 0);

           ROMCS, RAMCS : out  STD_LOGIC;

           VIDEO : inout  STD_LOGIC;
           nTAPEIN : in  STD_LOGIC;
           KBD :     in  STD_LOGIC_VECTOR(4 downto 0);

           TST6, TST7 : out  STD_LOGIC);
end zx81ula;

architecture Behavioral of zx81ula is

signal CPU_CLK, CLK65: std_logic;
signal nT34: std_logic;

signal intack,nmi_intern: std_logic;
signal in_fe, io_wr: std_logic;
signal out_fe, out_fd: std_logic;

signal exec: std_logic;
signal addlatch_en, latch_out: std_logic;
signal t_nop, t_load: std_logic;

signal inv_char, inv_char2: std_logic;
signal vsync: std_logic := '0';
signal hsync,csync:std_logic;
signal bp,bp_masked: std_logic;
signal nmi_on: std_logic := '0';

signal configreg: std_logic_vector(7 downto 0) := "00000000";
signal wr_mem8: std_logic;

signal pixel, video_tri: std_logic;

begin

-- TESTs
TST6 <= CLK65;
TST7 <= hsync;

-- Used or Unused ?

WAITs <= nmi_intern or (not HALT);  -- i.e. NMI or not HALT

-- CLOCK generator & NMI generator

CLOCK_BLK: entity work.clockgen2
	port map (
    CLKIN => MAINCLK,
    RESET_NMI => intack, 
    CLKOUT => CPU_CLK, 
    CNT_NMI => hsync, 
    DBL_CLK => CLK65, 
    BACKP => bp
    );

nmi_intern <= not (hsync and nmi_on);		-- active low
intack <= not (M1 or IORQ);					-- Reset NMI cnt whem M1=0 & IORQ=0
Z80_CLK <= not CPU_CLK;

NMI <= nmi_intern;

-- ChipSelect

RAMCS <= (not (Ah(15) or Ah(14) or Ah(13))) or (MREQ and nT34) or t_nop;
ROMCS <=       (Ah(15) or Ah(14) or Ah(13)) or (MREQ and nT34) or t_nop;

wr_mem8 <= '1' when (Ah="000" and A="000001000" and MREQ='0' and WR='0') else '0';

process(CPU_CLK,wr_mem8)
begin
 if (CPU_CLK='1' and CPU_CLK'event) then
	if (wr_mem8='1') then
		configreg <= D;
	end if;
 end if;
end process;

-- IN/OUT

io_wr <= not (IORQ or WR);							-- 1 if IORQ=0 & WR=0 (i.e. any OUT)
in_fe <= not (IORQ or RD or A(0));				-- 1 if IORQ=0 & RD=0 & A0=0
																-- used for KBD/Tape too
process(in_fe, io_wr)
begin
 if io_wr='1' then
   vsync <= '0';
 elsif (in_fe='1' and in_fe'event) then
   vsync <= not nmi_on;								-- 1 if nmi_on was '0'
 end if;
end process;

out_fe <= io_wr and not A(0);
out_fd <= io_wr and not A(1);

process(out_fe, out_fd)
begin
 if out_fd='1' then
   nmi_on <= '0';
 elsif (out_fe='1' and out_fe'event) then
   nmi_on <= '1';
 end if;
end process;

-- TState Decoder

exec <= Ah(15) and HALT and (not M1) and (not MREQ);
			  
STATE_DEC: entity work.Tstate
	port map (
		EXEC => exec,
		CLK => CPU_CLK,
		DATA6 => D(6),
		cycle_T2 => addlatch_en,
		ncycle_T3T4 => nT34,
		mid_T2T3 => t_nop,
		end_T4 => t_load );

-- A8-A0 address generator

latch_out <= not (nT34 or Ah(14));	-- nT34=0 & A14=0 => A[8:0] forced by ULA

ADDR8_0_GEN: entity work.addrgen
	port map (
		INCA => hsync,
		RSTA => vsync,
		D => D,
		LATCH_EN => addlatch_en,
		CLK => CPU_CLK,
		EN_OUT => latch_out,
		INV => inv_char,
		A => A);
		
-- NOP/DataOut

DATA_OUT: entity work.outport
	port map (
		ForceNop => t_nop,
		InPortFE => in_fe,
		TapeIn => nTAPEIN,
		UsUk => '1',
		Bit5 => '0',
		Kbd => KBD,
		D => D);

-- VIDEO : Shifter + TriState output

inv_char2 <= inv_char xor configreg(0);

PIXSHIFT_BLK: entity work.shifter2
	port map (
		LOAD => t_load,
		CLK => CLK65,
		CARRYIN => configreg(1),
		INV => inv_char2,
		D => D,
		SHIFTOUT => pixel);

-- bp_masked <= bp and (not vsync);	
-- csync <= not (hsync or vsync);		-- active low when hsync or vsync
--video_tri <= bp_masked or pixel;		-- TRI-state (black level) when Backporch or Black		
-- VIDEO <= csync when (video_tri='0' or csync='0') else 'Z';	-- 0=sync, TRI=black, 1=white
 
VIDEO <=         '0' when (hsync='1' or vsync='1')
            else 'Z' when (bp='1' or pixel='1')
				else '1';
				
end Behavioral;

