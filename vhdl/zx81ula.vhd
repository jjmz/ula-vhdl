library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity zx81ula is
    Port ( MAINCLK :  in  STD_LOGIC;
           Z80CLK_n : out  STD_LOGIC;

           IORQ_n, MREQ_n : in  STD_LOGIC;
           RD_n, WR_n :     in  STD_LOGIC;
           M1_n, HALT_n :   in  STD_LOGIC;
           
           NMI_n  :  out  STD_LOGIC;
           WAIT_n :  out  STD_LOGIC;
			  
			  Ah : in      STD_LOGIC_VECTOR(15 downto 13);
           A  : inout   STD_LOGIC_VECTOR(8 downto 0);
			  D  : inout   STD_LOGIC_VECTOR(7 downto 0);

           ROMCS_n, RAMCS_n : out  STD_LOGIC;

           VIDEO   : inout  STD_LOGIC;
           nTAPEIN : in     STD_LOGIC;				-- 0=default, 1=pulse High->Low
           KBD :     in     STD_LOGIC_VECTOR(4 downto 0);

			  CLK_EXT: in  STD_LOGIC;
			  
           TST6, TST7 : out  STD_LOGIC);
end zx81ula;

architecture Behavioral of zx81ula is

signal CPU_CLK, CLK65, CLK325, CLK13 : std_logic;
signal clock_select: std_logic;
signal SEL_CLK: std_logic;

signal in_fe, io_wr: std_logic;
signal out_fe, out_fd: std_logic;

signal exec: std_logic;
signal addlatch_en, latch_out: std_logic;
signal t_nop, t_load: std_logic;
signal nT34: std_logic;                 -- low during T3&T4 of M1/EXEC cycle to extend RAM/ROM access (equiv. to RFSH)

signal nmi_on: std_logic := '0';
signal intack,reset_nmi,nmi_intern: std_logic;

signal inv_char, inv_char2: std_logic;
signal vsync: std_logic := '0';
signal hsync:std_logic;
signal bp: std_logic;
signal pixel: std_logic;

signal configreg: std_logic_vector(7 downto 0) := "00000000";
signal reset_emu: std_logic;
																				
signal cfg_unlocked: std_logic;
signal romsel, memaccess: std_logic;


-- CONFIGREG
-- Unlock access with : poke 67,89
-- Place value in 66 (poke 66,value)
-- bit 0 -> Inverse Video (char)
-- bit 1 -> Inverse Video (border)
-- bit 2 -> NoWait mod(wait signal on Pin 22 - unused for 50Hz)
-- bit 3 -> M1Not
-- bit 4 -> Reset nmi counter : intack (default) or vsync (Metropolis compatible)
-- bit 6/7 -> Clock 3.25 (6.5 / 13 / 26)

begin

-- TESTs : debug pins

TST6 <= not nTAPEIN;							-- Led ON ('0') when signal present
TST7 <= not cfg_unlocked;							-- 

-- Used or Unused -- if used then mapped to pin 22 (US/UK)
-- Default design, equiv. to the ZX81 transistor logic

WAIT_GENE: entity work.waitgen
	port map (
		halt_n => HALT_n,
		nmi => nmi_intern,
		nowait_sw => configreg(2),
		wait_n => WAIT_n
	);

-- CLOCK generator & NMI generator

CLOCK_BLK: entity work.clockgen2
	port map (
        CLKIN => MAINCLK,
        RESET_NMI => reset_nmi ,  -- intack           , start @0 - 16-31(sync) / 32-63(bp)
		  START => configreg(4),    -- (io_wr and vsync), start@32 - i.e.  bp,---,sync	  
        CLKOUT => CLK325, 
		  TURBOCLK => CLK13,
        CNT_NMI => hsync, 
        DBL_CLK => CLK65, 
        BACKP => bp
    );

nmi_intern <= not (hsync and nmi_on);		   -- active low
intack <= not (M1_n or IORQ_n);				   -- Reset NMI cnt whem M1=0 & IORQ=0
Z80CLK_n <= not CPU_CLK;                     -- re-inverted before Z80

reset_nmi <= (io_wr and vsync) when configreg(4)='1' else intack;

NMI_n <= nmi_intern;

-- ChipSelect

romsel <= '1' when Ah="000" else '0';
memaccess <= MREQ_n or t_nop;                -- t_nop masks all mem access (Data forced to x00)

RAMCS_n <= memaccess when romsel='0' else '1';
ROMCS_n <= memaccess when romsel='1' else '1';

-- Config Register (Unlock & CFG Reg)

process(CPU_CLK,reset_emu)
begin
 if (reset_emu='1') then
  configreg <= (others=>'0');
 else
  if (CPU_CLK='1' and CPU_CLK'event) then
   if (romsel='1' and A(8 downto 6)="001" and MREQ_n='0' and WR_n='0') then 	-- Any Write to Rom (64-127) , locks CFG
    cfg_unlocked <= '0';
    if (A(5 downto 0)="000011" and D="01011001") then
     cfg_unlocked <= '1';														-- Unlck access CFG (poke 67,89) - 67=0x43,89=0x59
	 end if;
    if (A(5 downto 0)="000010" and cfg_unlocked='1') then			-- Mem66 - 66=0x42
	  configreg <= D;										
	 end if;
   end if;
  end if;
 end if;
end process;

-- Reset Emulation

process(M1_n)
begin
 if (M1_n='1' and M1_n'event) then
  if (romsel='1' and A="000000000" and D="11010011") then				-- executing (M1) opcode D3 @ 0x00 => Out(x),a
   reset_emu <= '1';
  else
   reset_emu <= '0';
  end if;
 end if;
end process;

-- CPU_CLK

CPU_CLK <= CLK325 when (clock_select='0') else SEL_CLK;

-- probably OK for CLK325->CLK13, but not CLK_EXT (to sync on rising edge)

SEL_CLK <= MAINCLK when configreg(7 downto 6)="11"
      else CLK13   when configreg(7 downto 6)="10"
		else CLK65   when configreg(7 downto 6)="01"
		else CLK325;

process(CLK325,reset_emu)
begin
 if (reset_emu='1') then
  clock_select<= '0';
 else 
  if (CLK325='0' and CLK325'event) then
   if (HALT_n='0' or out_fd='1' or (A(7 downto 0)="11111111" and io_wr='1')) then  
    clock_select<= '0';
   else
    if (out_fe='1') then
     clock_select <= configreg(7) or configreg(6);
	 end if;
   end if;
  end if;
 end if;
end process;

-- IN/OUT

io_wr <= not (IORQ_n or WR_n);						-- 1 if IORQ=0 & WR=0 (i.e. any OUT)
in_fe <= not (IORQ_n or RD_n or A(0));				-- 1 if IORQ=0 & RD=0 & A0=0
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

-- Was : exec <= Ah(15) and HALT_n and (not MREQ_n);
-- If ConfigReg(3)=1, then take A14 into account (=> M1NOT)
exec <= Ah(15) and (not configreg(3) or Ah(14)) and HALT_n and (not MREQ_n);

STATE_DEC: entity work.Tstate
	port map (
		EXEC => exec,
      M1_n => M1_n,
		CLK65 => CLK65,
		DATA6 => D(6),
		RESET => reset_emu,
		cycle_T2 => addlatch_en,
		ncycle_T3T4 => nT34,
		mid_T2T3 => t_nop,
		end_T4 => t_load );

-- A8-A0 address generator

latch_out <= not (nT34 or Ah(14));	-- nT34=0 & A14=0 => A[8:0] forced by ULA

ADDR8_0_GEN: entity work.addrgen
	port map (
		INCA => hsync, RSTA => vsync,		
		D => D,
		LATCH_EN => addlatch_en, CLK => CLK65,
		EN_OUT => latch_out, INV => inv_char, A => A);
		
-- NOP/DataOut, basically a big MUX

DATA_OUT: entity work.outport
	port map (
		ForceNop => t_nop,
		InPortFE => in_fe,
		TapeIn => nTAPEIN,
		UsUk => '1', Bit5 => '0',
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

VIDEO <=   '0' when (hsync='1' or vsync='1')      -- sync level = '0'
      else 'Z' when (bp='1' or pixel='1')         -- backporch and black level = 'Z'
		else '1';                                   -- white = '1'
				
end Behavioral;

