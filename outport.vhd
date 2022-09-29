library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity outport is
    Port ( ForceNop : in  STD_LOGIC;
           InPortFE : in  STD_LOGIC;
           Kbd : in  STD_LOGIC_VECTOR (4 downto 0);
           TapeIn : in  STD_LOGIC;
           UsUk : in  STD_LOGIC;
           Bit5 : in  STD_LOGIC;
           D : inout  STD_LOGIC_VECTOR (7 downto 0));
end outport;

architecture Behavioral of outport is

signal Dout: std_logic_vector(7 downto 0);

begin

Dout <= TapeIn&UsUk&Bit5&Kbd when (InPortFE='1') else (others=>'0');
D <= Dout when ((ForceNop='1') or (InPortFE='1')) else (others=>'Z');

end Behavioral;

