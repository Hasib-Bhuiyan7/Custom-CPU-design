library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity data_path is
port(
--Clock Signals
Clk, mClk : in std_logic;

--Memory Signals
WEN, EN : in std_logic;

--Register Control Signals
Clr_A, Ld_A : in std_logic;
Clr_B, Ld_B : in std_logic;
Clr_C, Ld_C : in std_logic;
Clr_Z, Ld_Z : in std_logic;
ClrPC, Ld_PC : in std_logic;
ClrIR, Ld_IR : in std_logic;

--Register Outputs
Out_A : out std_logic_vector(31 downto 0);
Out_B : out std_logic_vector(31 downto 0);
Out_C : out std_logic;
Out_Z : out std_logic;
Out_PC : out std_logic_vector(31 downto 0);
Out_IR : out std_logic_vector(31 downto 0);

--Special PC Inputs
Inc_PC : in std_logic;

--Address and Data Bus Signals
ADDR_OUT : out std_logic_vector(31 downto 0);
DATA_IN : in std_logic_vector(31 downto 0);
DATA_BUS, MEM_OUT, MEM_IN : out std_logic_vector(31 downto 0);
MEM_ADDR : out unsigned(7 downto 0);

--MUX Controls
DATA_MUX : in std_logic_vector(1 downto 0);
REG_MUX : in std_logic;
A_MUX, B_MUX : in std_logic;
IM_MUX1 : in std_logic;
IM_MUX2 : in std_logic_vector(1 downto 0);

--ALU Operations
ALU_Op : in std_logic_vector(2 downto 0)
);
end entity;


architecture Behavior of data_path is

--Component Instantations Data Memory Module
component data_mem is
port(
clk : in std_logic;
addr : in unsigned(7 downto 0);
data_in : in std_logic_vector(31 downto 0);
wen : in std_logic;
en : in std_logic;
data_out : out std_logic_vector(31 downto 0)
);
end component;

--Register32
component register32 is
port (
d : in std_logic_vector(31 downto 0) ;
ld : in std_logic ;
clr : in std_logic ; 
clk : in std_logic ;
Q : out std_logic_vector(31 downto 0)) ;
end component;

--Program Counter
component pc is
port (
clr : in std_logic ; 
clk : in std_logic ;
ld : in std_logic ;
inc : in std_logic ;
d : in std_logic_vector(31 downto 0) ; 
q : out std_logic_vector(31 downto 0) ) ;
end component;

--LZE
component LZE is
port(
LZE_in : in std_logic_vector(31 downto 0);
LZE_out : out std_logic_vector(31 downto 0)
);
end component;

--UZE
component UZE is
port(
UZE_in : in std_logic_vector(31 downto 0);
UZE_out : out std_logic_vector(31 downto 0)
);
end component;

--RED
component RED is
port(
    RED_in   : in  std_logic_vector(31 downto 0);
    RED_out  : out unsigned(7 downto 0)
);
end component;

--mux2to1
component mux2to1 is
port (
s : in std_logic ; 
w0, w1 : in std_logic_vector(31 downto 0) ; 
f : out std_logic_vector(31 downto 0) ) ; 
end component;

--mux4to1
component mux4to1 is
port(
s : in std_logic_vector(1 downto 0);
X1, X2, X3, X4 : in std_logic_vector(31 downto 0);
f: out std_logic_vector(31 downto 0)
);
end component;

--ALU  
component ALU32 is
port(
a, b : in std_logic_vector(31 downto 0);
op : in std_logic_vector(2 downto 0);
result : out std_logic_vector(31 downto 0);
zero, cout : out std_logic );
end component;

--Signal Instantations
signal IR_OUT : std_logic_vector(31 downto 0);
signal data_bus_s : std_logic_vector(31 downto 0);
signal LZE_out_PC : std_logic_vector(31 downto 0);
signal LZE_out_A_mux : std_logic_vector(31 downto 0);
signal LZE_out_B_mux : std_logic_vector(31 downto 0);
signal RED_out_data_mem : unsigned(7 downto 0);
signal A_Mux_out : std_logic_vector(31 downto 0);
signal B_Mux_out : std_logic_vector(31 downto 0);
signal reg_A_out : std_logic_vector(31 downto 0);
signal reg_B_out : std_logic_vector(31 downto 0);
signal reg_Mux_out : std_logic_vector(31 downto 0);
signal data_mem_out : std_logic_vector(31 downto 0);
signal UZE_IM_MUX1_out : std_logic_vector(31 downto 0);
signal IM_MUX1_out : std_logic_vector(31 downto 0);
signal LZE_IM_MUX2_out : std_logic_vector(31 downto 0);
signal IM_MUX2_out : std_logic_vector(31 downto 0);
signal ALU_out : std_logic_vector(31 downto 0);
signal zero_flag : std_logic;
signal carry_flag : std_logic;
signal temp : std_logic_vector(30 downto 0) := (others => '0');
signal out_pc_sig : std_logic_vector(31 downto 0);

begin
	IR: register32 port map(
	data_bus_s,
	Ld_IR,
	ClrIR,
	Clk,
	IR_OUT
	);

	LZE_PC: LZE port map(
	IR_OUT,
	LZE_out_PC
	);
	
	PC0: pc port map(
	CLRPC,
	Clk,
	ld_PC,
	INC_PC,
	LZE_out_PC,
	--ADDR OUT
	out_pc_sig
	);
	
	LZE_A_Mux: LZE port map(
	IR_OUT,
	LZE_out_A_mux
	);
	
	A_Mux0: mux2to1 port map(
	A_MUX,
	data_bus_s,
	LZE_out_A_mux,
	A_mux_out
	);
	
	Reg_A: register32 port map(
	A_mux_out,
	Ld_A,
	Clr_A,
	Clk,
	reg_A_out
	);
	
	LZE_B_Mux: LZE port map(
	IR_OUT,
	LZE_out_B_mux
	);
	
	B_Mux0: mux2to1 port map(
	B_MUX,
	data_bus_s,
	LZE_out_B_mux,
	B_mux_out
	);
	
	Reg_B: register32 port map(
	B_mux_out,
	Ld_B,
	Clr_B,
	Clk, 
	reg_B_out
	);
	
	Reg_Mux0: mux2to1 port map(
	REG_MUX,
	Reg_A_out,
	Reg_B_out,
	Reg_Mux_out
	);
	
	RED_Data_Mem: RED port map(
	IR_OUT,
	RED_out_data_mem
	);
	
	Data_Mem0: data_mem port map(
	mClk,
	RED_out_data_mem,
	Reg_Mux_out,
	WEN,
	EN,
	data_mem_out
	);
	
	UZE_IM_MUX1: UZE port map(
	IR_OUT,
	UZE_IM_MUX1_out
	);
	
	IM_MUX1a: mux2to1 port map(
	IM_MUX1,
	reg_A_out,
	UZE_IM_MUX1_out,
	IM_MUX1_out
	);
	
	LZE_IM_MUX2: LZE port map(
	IR_OUT,
	LZE_IM_MUX2_out
	);
	
	IM_MUX2a: mux4to1 port map(
	IM_MUX2,
	reg_B_out,
	LZE_IM_MUX2_out, (temp &'1'), (others =>'0'),
	IM_MUX2_out
	);
	
	ALU0: ALU32 port map(
	IM_MUX1_out,
	IM_MUX2_out,
	ALU_Op,
	ALU_out,
	zero_flag,
	carry_flag
	);
	
	DATA_MUX0: mux4to1 port map(
	DATA_MUX,
	DATA_IN,
	data_mem_out,
	ALU_out,
	(others => '0'),
	data_bus_s
	);
	
	DATA_BUS <= data_bus_s;
	OUT_A <= reg_A_out;
	OUT_B <= reg_B_out;
	OUT_IR <= IR_OUT;
	ADDR_OUT <= out_pc_sig;
	OUT_PC <= out_pc_sig;
	
	MEM_ADDR <= RED_out_data_mem;
	MEM_IN <= Reg_Mux_out;
	MEM_OUT <= data_mem_out;
	
end Behavior;

--END Questions:
 --1) a)INCA: The Increment Function is implemented by placing Reg A as the first ALU input, by loading and opening the MUX(IM_MUX1) And the other input for the ALU
 --           is a single value '1'(by setting IM_MUX2 to 2). Reg A and '1' are added in the ALU(OpCode = 010)
 --   b)ADDI: The Adding with intermediate function is implemented by enabling the mux and loading reg A as one of the input. The other input would be the DATA_IN 
 --           that is directly loaded to the IR reg, from there it makes it's way to the second input(where IM_MUX2 is set as 1). Reg A and the DATA_IN value in 
 --           Reg IR are then added (OpCode = 010)
 --   c)LDBI: The Loading B with intermediate function is implemented by first loading IR reg with the DATA_IN value. Then the B_mux and load for Reg B is enabled 
 --           allowing the DATA_IN from IR Reg to make its way there, and thus the DATA_IN value is loaded into reg B .
 --   d)LDA: The Load memory with A function takes the first DATA_IN input and enables the A_MUX and loades reg A with it. Now this function uses the Data Memory 
 --          unit; the reg A is used as the data_in for memory, and the next DATA_IN from the cpu is the specified address to where the contents of reg A will be 
 --          stored. The address(last 2 of the 8 hex) comes form the IR reg and the data memory unit is in writing mode(WEN=1 and EN=1), where the contents of reg A
 --          will be written in the address. Later reg A is cleared and data_in is no longer in use. Now the same address is accessed by loading it in the IR reg 
 --          again, but this time it is in read mode(just EN=1), and the memory unit generates output(content of regA that was written previously).   
 
 --2) The Maximum Reliable clock speed is determined by the delays that indicate the time required to execute the process. Most specifically the longest 
   -- combinational delay from the time it takes to progress through the combinational logic gate circuit, that is the "Critcial Path Delay".
   -- The clock period, T_clk must be atleast as long as T_criticalpathdelay: Tclk >= T_criticalpathdelay
	-- The Reliable clock speed also includes the setup time, since data signals must be settled before the clock edge, and data must remain stable after the clock 
	-- cycle ends(T_setup):
	-- Thus, the acceptable Maximum Reliable clock speed must include two factors, the critical path delay and setup time: 
	-- T_clk = T_criticalpathdelay + T_setup

--3) The relaible limit for the data-path clock is(in frequency): 
--   f_reliable_clk = 1 / (T_criticalpathdelay + T_setup) 
--   f_reliable_clk = 1 / (20 ns + 1 ns) [The criticla path delay is assumed to be the current clock cycle that is successful(20ns); the setup time is assumed to 
--                                        be 1ns as per usual cirumstances]
--   f_reliable_clk = 1 / (20 ns + 1 ns) = 1 / (21 ns) = 47.6 MHz 
 