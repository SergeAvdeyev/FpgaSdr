----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
--
-- Top-level Entity
--
--	Echo i_RX_Serial data to o_TX_Serial
-- Send HEX '31' every 1 second if there is no i_RX_Serial data 
--
-- Configured for 50MHz i_Clk and UART speed 256000 baud (g_CLKS_PER_BIT = 195)
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UDP_BUFFER is
	generic (
		ADC_BUFFER_SIZE : natural := 10  -- Number of 16-bit I & Q elements
	);
	port (
		In_RST			: in std_logic;
		
		In_Signal_I		: in std_logic_vector(15 downto 0);
		In_Signal_Q		: in std_logic_vector(15 downto 0);
		In_Signal_CLK	: in std_logic;
		
		In_Data_CLK		: in std_logic;
		In_Data_strob	: in std_logic;
		Out_Data			: out std_logic_vector(31 downto 0);
		Out_Data_ready	: out std_logic
	);
end UDP_BUFFER;
 
architecture rtl of UDP_BUFFER is

	type t_RAM_word is record
		I : std_logic_vector(15 downto 0); 
		Q : std_logic_vector(15 downto 0);
	end record;
	type t_RAM_memory is array(ADC_BUFFER_SIZE*2 - 1 downto 0) of t_RAM_word;	-- 2 buffers: 1 - for write, 2 - for read
	-- Declare the RAM signal.
	shared variable RAM : t_RAM_memory := (others => ((others => '0'),(others => '0')));		
	signal r_write_RAM_buffer_index	: natural range 0 to 1 := 0;
	signal r_write_RAM_buffer_addr	: natural range 0 to ADC_BUFFER_SIZE - 1 := 0;	
	signal r_read_RAM_buffer_index	: natural range 0 to 1 := 1; 
	signal r_read_RAM_buffer_addr		: natural range 0 to ADC_BUFFER_SIZE - 1 := 0;
	signal r_Data_ready						: std_logic := '0';
   
begin
	Out_Data_ready <= r_Data_ready;

	write_RAM_proc : process(In_Signal_CLK)	 
		variable v_write_addr : natural range 0 to ADC_BUFFER_SIZE*2 - 1;
	begin
		if rising_edge(In_Signal_CLK) then 
			if In_RST = '1' then
				r_write_RAM_buffer_index <= 0;
				r_write_RAM_buffer_addr <= 0;
			else
				v_write_addr := ADC_BUFFER_SIZE*r_write_RAM_buffer_index + r_write_RAM_buffer_addr;
				RAM(v_write_addr).I := In_Signal_I;
				RAM(v_write_addr).Q := In_Signal_Q;
				if r_write_RAM_buffer_addr = ADC_BUFFER_SIZE - 1 then
					r_write_RAM_buffer_addr <= 0;  
					r_write_RAM_buffer_index <= 1 - r_write_RAM_buffer_index;
				else
					r_write_RAM_buffer_addr <= r_write_RAM_buffer_addr + 1;
				end if;
			end if;
		end if;
	end process;
	
	read_RAM_proc : process(In_Data_CLK)
	begin
		if rising_edge(In_Data_CLK) then 
			if In_RST = '1' then
				r_read_RAM_buffer_index <= 1;
				r_read_RAM_buffer_addr <= 0;
			else
				if r_read_RAM_buffer_index /= 1 - r_write_RAM_buffer_index then
					r_read_RAM_buffer_index <= 1 - r_write_RAM_buffer_index;
					r_read_RAM_buffer_addr <= 0;
					r_Data_ready <= '1';
				else
					Out_Data(15 downto 0) <= RAM(ADC_BUFFER_SIZE*r_read_RAM_buffer_index + r_read_RAM_buffer_addr).I;
					Out_Data(31 downto 16) <= RAM(ADC_BUFFER_SIZE*r_read_RAM_buffer_index + r_read_RAM_buffer_addr).Q;
					if In_Data_strob = '1' then
						if r_read_RAM_buffer_addr = ADC_BUFFER_SIZE - 1 then
							r_Data_ready <= '0';
							r_read_RAM_buffer_addr <= 0;
						else
							r_read_RAM_buffer_addr <= r_read_RAM_buffer_addr + 1;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

 
end rtl;