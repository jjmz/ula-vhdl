library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity zx81ula is
    Port ( MAINCLK : in  STD_LOGIC;
           IORQ : in  STD_LOGIC;
           MREQ : in  STD_LOGIC;
           RD : in  STD_LOGIC;
           WR : in  STD_LOGIC;
           M1 : in  STD_LOGIC;
           A15 : in  STD_LOGIC;
           A14 : in  STD_LOGIC;
           A13 : in  STD_LOGIC;
           NMI : out  STD_LOGIC;
           HALT : in  STD_LOGIC;
           WAITs : out  STD_LOGIC;
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : inout  STD_LOGIC_VECTOR (8 downto 0);
           ROMCS : out  STD_LOGIC;
           RAMCS : out  STD_LOGIC;
           VIDEO : inout  STD_LOGIC;
           Z80_CLK : out  STD_LOGIC;
           nTAPEIN : in  STD_LOGIC;
           KBD : in  STD_LOGIC_VECTOR (4 downto 0);
           TST6 : out  STD_LOGIC;
           TST7 : out  STD_LOGIC);
end zx81ula;

architecture Behavioral of zx81ula is

signal CPU_CLK, CLK65: std_logic;
signal nT34: std_logic;

signal intack,nmi_intern: std_logic;
signal in_fe, in_fe2, io_wr: std_logic;
signal out_fe, out_fd: std_logic;

signal exec: std_logic;
signal addlatch_en, latch_out: std_logic;
signal t_nop, t_load: std_logic;

signal inv_char: std_logic;
signal hsync,vsync,csync:std_logic;
signal bp,bp_masked: std_logic;
signal nmi_on: std_logic;

signal pixel, video_tri: std_logic;

begin

-- TESTs
TST6 <= CLK65;
TST7 <= hsync;

-- Unused

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

RAMCS <= not (A13 or A14 or A15) or (nT34 and MREQ);
ROMCS <= (A13 or A14 or A15) or (nT34 and MREQ);

-- IN/OUT

io_wr <= not (IORQ or WR);
in_fe <= not (IORQ or RD or A(0));
in_fe2 <= in_fe and not nmi_on;

process(in_fe2, io_wr)
begin
 if io_wr='1' then
   vsync <= '0';
 elsif (in_fe2='1' and in_fe2'event) then
   vsync <= '1';
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

exec <= A15 and HALT and (not M1) and (not D(6)) and (not MREQ);

STATE_DEC: entity work.Tstate
	port map (
		EXEC => exec,
		CLK => CPU_CLK,
		T2c => addlatch_en,
		nT34 => nT34,
		T2L => t_nop,
		T4H => t_load );

-- A8-A0 address generator

latch_out <= not (nT34 or A14);	-- nT34=0 & A14=0 => A[8:0] forced by ULA

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
		TapeIn => not nTAPEIN,
		UsUk => '1',
		Bit5 => '0',
		Kbd => KBD,
		D => D);

-- VIDEO : Shifter + TriState output

PIXSHIFT_BLK: entity work.shifter2
	port map (
		LOAD => t_load,
		CLK => CLK65,
		CARRYIN => '0',
		INV => inv_char,
		D => D,
		SHIFTOUT => pixel);

bp_masked <= bp and (not vsync);
		
csync <= not (hsync or vsync);		-- active low when hsync or vsync
video_tri <= bp_masked or pixel;		-- TRI-state (black level) when Backporch or Black
		
VIDEO <= csync when video_tri='0' else 'Z';	-- 0=sync, TRI=black, 1=white

end Behavioral;

