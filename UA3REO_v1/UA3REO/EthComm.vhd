library ieee;
use ieee.std_logic_1164.ALL;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.etherlink_pkg.all;


entity EthComm is
	generic (		 
		ADC_BUFFER_SIZE : natural := 10  -- Number of 16-bit I & Q elements
	);
	port (
		In_CLK_50				: in std_logic; -- PIN 23
	
		In_RMII_CLK				: in std_logic; -- PIN 115
		In_RST					: in std_logic; -- PIN 86			  
		
		In_UDP_data_ready		: in std_logic;
		In_UDP_data				: in std_logic_vector(31 downto 0);
		Out_UDP_data_strob	: out std_logic := '0';
		
		-- UART interface for Loggin data
		Out_Debug_Data_Ready	: out std_logic;
		Out_Debug_Data   		: out std_logic_vector(7 downto 0);
		
		-- RMII --
		-- Receiver
		In_RMII_RX				: in std_logic_vector(1  downto 0); -- PIN 114 113
		In_RMII_CRS_DV			: in std_logic;							-- PIN 119
		-- Sender
		Out_RMII_TX				: out STD_LOGIC_VECTOR(1  downto 0) := (Others => 'Z');  -- PIN 106 112
		Out_RMII_TX_Enable	: out STD_LOGIC := 'Z';												-- PIN 111

		Out_RMII_Reset			: out std_logic := '1';		-- PIN 103
		--Out_PHY_MDIO			: InOut STD_LOGIC := 'Z'; 	-- PIN_120
		--Out_PHY_MDC			: Out STD_LOGIC := '0';		-- PIN_121
		
		Out_Phi_Inc				: out std_logic_vector(23 downto 0);
		
		Out_LEDS					: out std_logic_vector(3 downto 0)	-- PIN 76, 77, 83, 85
	);
end EthComm;
 
architecture rtl of EthComm is

	-- internal byte stream from rmii
	signal r_RMII_RX_dv		: std_logic;        -- kept high so long as we are receiving a frame
	signal r_RMII_RX_str_dt	: std_logic;        -- a pulse when r_dt is valid
	signal r_RMII_RX_data	: std_logic_vector(7 downto 0);      -- 1-byte received data, valid only during r_str_dt is active


	component rmii_to_bytestream is
		port (
			 ref_clk		: in std_logic;         -- RMII ref_clk
			 -- RMII
			 i_dv			: in std_logic;
			 i_dt			: in std_logic_vector(1 downto 0);
			 -- internal byte stream
			 o_dv			: out std_logic;        -- kept high so long as we are receiving a frame
			 o_str_dt	: out std_logic;        -- a pulse when r_dt is valid
			 o_data		: out std_logic_vector(7 downto 0)      -- 1-byte received data, valid only during r_str_dt is active
		) ;
	end component rmii_to_bytestream;

	------------------------
	-- DEBUG
	------------------------
	signal r_Debug_Data_Ready		: std_logic := '0';	   
	signal r_Debug_Data				: std_logic_vector(7 downto 0) := (others => '0');
	constant c_Debug_Buffer_size	: integer := 800;
	signal Debug_Buffer				: std_logic_vector(c_Debug_Buffer_size - 1 downto 0);
	signal Debug_Buffer_count		: integer range 0 to c_Debug_Buffer_size - 1 := 0;

	
	constant c_src_MAC	: STD_LOGIC_VECTOR(47 downto 0) := x"001b11305290";	--	Source Mac address
	signal 	r_dst_MAC	: STD_LOGIC_VECTOR(47 downto 0) := x"7C8BCA0AC10F";--x"888888888888";
	constant	c_src_IP		: STD_LOGIC_VECTOR(31 downto 0) := x"7AD94501";			-- 122.217.69.1
	signal	r_dst_IP		: STD_LOGIC_VECTOR(31 downto 0) := x"7AD945F0";			-- 122.217.69.240
	constant	c_src_Port	: STD_LOGIC_VECTOR(15 downto 0) := x"2710";
	signal	r_dst_Port	: STD_LOGIC_VECTOR(15 downto 0) := x"2710";

	------------------------------------------------------------------------------------------------
	-- TX RMII
	constant FRBUF_MEM_ADDR_W	: natural := 9;
	constant IGAP_LEN 			: natural := 6;                -- inter-frame gap in bytes
	constant M1_SUPPORT_READ	: boolean := true;      -- whether port 2 is read-write (when true) or read-only (when false)
	constant M1_DELAY				: natural := 2;                -- read delay: 2=insert register at inputs
	constant TXFIFO_DEPTH_W		: natural := 4;        -- fifo depth is 2**FIFO_DEPTH_W elements
	constant FRTAG_W				: natural := 0;                  -- nr of bits for frame tag that is moved between fifos

	-- access to frame buffer memory
	signal r_m1_addr			:  std_logic_vector(FRBUF_MEM_ADDR_W - 1 downto 0);  -- buffer address, granularity 32b words
	signal r_m1_wdt			:  std_logic_vector(31 downto 0);            		-- buffer write data 
	signal r_m1_wstrobe		:  std_logic := '0';                               -- strobe to write data into the buffer
	signal r_m1_rstrobe		:  std_logic;                                		-- strobe to write data into the buffer
	signal r_m1_rdt			:  std_logic_vector(31 downto 0);            		-- buffer write data 
	-- for removing processed (sent) frames by the tx-link
	signal r_rf_strobe		:  std_logic;                                  		-- remove frame of lenght rf_frlen from the bottom of the circular buffer
	signal r_rf_tag_len_ptr	: std_logic_vector(FRTAG_W + 2*FRBUF_MEM_ADDR_W - 1 downto 0);
	-- to push-fifo queue of frames to transmit
	signal r_pf_enq			:  std_logic;                                     	-- enqueue data command
	signal r_pf_tag_len_ptr	: std_logic_vector(FRTAG_W + 2*FRBUF_MEM_ADDR_W - 1 downto 0);      -- encodes (tag,len,ptr)
	signal r_pf_full			:  std_logic;                                   	-- full fifo indication (must not enqueue more)
	---------------------------------------------------------------------------------------------------------------
	
	
	signal r_blink_counter 		: natural range 0 to 50_000_000 := 0; --std_logic_vector(25 downto 0) := (others => '0');
	signal r_Out_LED_1			: std_logic := '1';
	signal r_Out_LED_2			: std_logic := '0';
	signal r_Out_LED_3			: std_logic := '0';
	signal r_Out_LED_4			: std_logic := '1';

	type t_rx_eth_state is (RX_IDLE, DISCARD, MAC_HEADER, ARP, IPV4_HEADER, ICMP);
	signal r_rx_eth_state : t_rx_eth_state := RX_IDLE;

	type t_tx_eth_state is (TX_IDLE, PREPARE_ADC_DATA, WRITE_ADC_HEADER, WRITE_ADC_DATA, PREPARE_REPLY_DATA,
									WRITE_REPLY_DATA, ENQUE_DATA);
	signal r_tx_eth_state : t_tx_eth_state := TX_IDLE;
	
	signal r_RMII_RX_buffer : std_logic_vector(1023 downto 0);
	signal r_RMII_RX_buffer_count : integer range 0 to 1023;
	
	signal r_eth_request_ready : std_logic := '0'; 
	type t_eth_request_type is (ARP, ICMP_ECHO);
	signal r_eth_request_type : t_eth_request_type;
	signal r_reply_ready : std_logic := '0'; 
	

	-- internal register type
	type t_arp_data is record
		hw_type				: std_logic_vector(15 downto 0);
		proto					: std_logic_vector(15 downto 0);
		hw_addr_len			: std_logic_vector(7  downto 0);
		prot_addr_len		: std_logic_vector(7  downto 0);
		opcode				: std_logic_vector(15 downto 0);
		sender_hw_addr		: std_logic_vector(47 downto 0);
		sender_prot_addr	: std_logic_vector(31 downto 0);
		target_hw_addr		: std_logic_vector(47 downto 0);
		target_prot_addr	: std_logic_vector(31 downto 0);
	end record;
	signal r_arp_data : t_arp_data;
	
	type t_mac_header is record
		dst_mac	: std_logic_vector(47 downto 0);
		src_mac	: std_logic_vector(47 downto 0);
		proto		: std_logic_vector(15 downto 0);
	end record;
	signal r_rx_mac_header : t_mac_header;

	type t_ipv4_header is record
		version		: std_logic_vector(3  downto 0);
		ihl			: std_logic_vector(3  downto 0);
		tos			: std_logic_vector(7  downto 0);	-- type-of-service
		total_len	: std_logic_vector(15 downto 0);
		identifier	: std_logic_vector(15 downto 0);
		flags			: std_logic_vector(2  downto 0);
		frag_offset	: std_logic_vector(12 downto 0);	-- fragment-offset
		ttl			: std_logic_vector(7  downto 0);
		protocol		: std_logic_vector(7  downto 0);
		check_sum	: std_logic_vector(15 downto 0);
		src_ip		: std_logic_vector(31 downto 0);
		dst_ip		: std_logic_vector(31 downto 0);
	end record;
	signal r_ipv4_header : t_ipv4_header;

	type t_udp_header is record
		src_port		: std_logic_vector(15 downto 0);
		dst_port		: std_logic_vector(15 downto 0);
		udp_len		: std_logic_vector(15 downto 0);
		check_sum	: std_logic_vector(15 downto 0);
	end record;
	
	type t_icmp is record
		icmp_type	: std_logic_vector(7  downto 0);
		code			: std_logic_vector(7  downto 0);
		check_sum	: std_logic_vector(15 downto 0);
		identifier	: std_logic_vector(15 downto 0);
		seq_num		: std_logic_vector(15 downto 0);
		data			: std_logic_vector(255 downto 0);
	end record;
	signal r_icmp : t_icmp;
	

	function str_to_std_logic_vector( s : string ) return std_logic_vector is
		variable r : std_logic_vector( s'length * 8 - 1 downto 0) ;
	begin
		for i in 1 to s'high loop
			r(i * 8 - 1 downto (i - 1) * 8) := std_logic_vector( to_unsigned( character'pos(s(s'length - i + 1)) , 8 ) ) ;
		end loop ;
		return r ;
	end function ;

	function str_to_std_logic_vector_with_return( s : string ) return std_logic_vector is
		variable r : std_logic_vector( (s'length + 1) * 8 - 1 downto 0) ;
	begin
		for i in 1 to s'high loop
			r( (i + 1) * 8 - 1 downto i * 8) := std_logic_vector( to_unsigned( character'pos(s(s'length - i + 1)) , 8 ) ) ;
		end loop ;
		r(7 downto 0) := x"0A";
		return r ;
	end function ;
	
	function to_hstring (value : STD_LOGIC_VECTOR) return STRING is
		constant ne     : INTEGER := (value'length + 3)/4;
		variable pad    : STD_LOGIC_VECTOR(0 to (ne*4 - value'length) - 1);
		variable ivalue : STD_LOGIC_VECTOR(0 to ne*4 - 1);
		variable result : STRING(1 to ne);
		variable quad   : STD_LOGIC_VECTOR(0 to 3);
	begin
		if value'length < 1 then
			return "";
		else
			if value (value'left) = 'Z' then
				pad := (others => 'Z');
			else
				pad := (others => '0');
			end if;
			ivalue := pad & value;
			for i in 0 to ne - 1 loop
				quad := To_X01Z(ivalue(4*i to 4*i+3));
				case quad is
					when x"0"  => result(i+1) := '0';
					when x"1"  => result(i+1) := '1';
					when x"2"  => result(i+1) := '2';
					when x"3"  => result(i+1) := '3';
					when x"4"  => result(i+1) := '4';
					when x"5"  => result(i+1) := '5';
					when x"6"  => result(i+1) := '6';
					when x"7"  => result(i+1) := '7';
					when x"8"  => result(i+1) := '8';
					when x"9"  => result(i+1) := '9';
					when x"A"  => result(i+1) := 'A';
					when x"B"  => result(i+1) := 'B';
					when x"C"  => result(i+1) := 'C';
					when x"D"  => result(i+1) := 'D';
					when x"E"  => result(i+1) := 'E';
					when x"F"  => result(i+1) := 'F';
					when others => result(i+1) := 'X';
				end case;
			end loop;
			return result;
		end if;
	end function to_hstring;
	
	function to_mac_header( arg : std_logic_vector(111 downto 0) ) return t_mac_header is
		variable result : t_mac_header;
	begin
		result.dst_mac	:= arg(111 downto 64);
		result.src_mac	:= arg(63 downto 16);
		result.proto	:= arg(15 downto 0);
		return result;
	end function to_mac_header;

	function from_mac_header( arg : t_mac_header ) return std_logic_vector is
		variable result : std_logic_vector(111 downto 0);
	begin
		result(111 downto 64)	:= arg.dst_mac;
		result(63 downto 16)		:= arg.src_mac;
		result(15 downto 0)		:= arg.proto;
		return result;
	end function from_mac_header;
	
	
	----------------------------------
	--  IP_V4
	----------------------------------
	function ipv4_check_summ(arg : std_logic_vector(159 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(19 downto 0) := (others => '0');
		variable tmp : integer := 0;
	begin
		tmp := to_integer(unsigned(arg(159 downto 144)));
		tmp := tmp + to_integer(unsigned(arg(143 downto 128)));
		tmp := tmp + to_integer(unsigned(arg(127 downto 112)));
		tmp := tmp + to_integer(unsigned(arg(111 downto 96)));
		tmp := tmp + to_integer(unsigned(arg(95  downto 80)));
		tmp := tmp + to_integer(unsigned(arg(63  downto 48)));
		tmp := tmp + to_integer(unsigned(arg(47  downto 32)));
		tmp := tmp + to_integer(unsigned(arg(31  downto 16)));
		tmp := tmp + to_integer(unsigned(arg(15  downto 0)));
		
		result := std_logic_vector(to_unsigned(tmp, result'length));
		tmp := to_integer(unsigned(result(15  downto 0))) + to_integer(unsigned(result(19  downto 16)));
		result := std_logic_vector(to_unsigned(tmp, result'length));
		return result(15 downto 0);
	end function ipv4_check_summ;

	function from_ipv4_header( arg : t_ipv4_header ) return std_logic_vector is
		variable result : std_logic_vector(159 downto 0);
	begin
		result(159 downto 156)	:= arg.version;		-- : std_logic_vector(3 downto 0);
		result(155 downto 152)	:= arg.ihl;				-- : std_logic_vector(3 downto 0);
		result(151 downto 144)	:= arg.tos;				-- : std_logic_vector(7 downto 0);	-- type-of-service		
		result(143 downto 128)	:= arg.total_len;		-- : std_logic_vector(15 downto 0);		
		result(127 downto 112)	:= arg.identifier;	-- : std_logic_vector(15 downto 0);		
		result(111 downto 109)	:= arg.flags;			-- : std_logic_vector(2 downto 0);
		result(108 downto 96)	:= arg.frag_offset;	-- : std_logic_vector(12 downto 0);	-- fragment-offset		
		result(95  downto 88)	:= arg.ttl;				-- : std_logic_vector(7 downto 0);
		result(87  downto 80)	:= arg.protocol;		-- : std_logic_vector(7 downto 0);		
		--result(79  downto 64)	:= arg.check_sum;		-- : std_logic_vector(15 downto 0);		
		result(63  downto 32)	:= arg.src_ip;			-- : std_logic_vector(31 downto 0);		
		result(31  downto 0)		:= arg.dst_ip;			-- : std_logic_vector(31 downto 0);
		
		-- check summ
		result(79  downto 64)	:= not ipv4_check_summ(result);
		return result;
	end function from_ipv4_header;

	function to_ipv4_header( arg : std_logic_vector(159 downto 0)) return t_ipv4_header is
		variable result : t_ipv4_header;
	begin
		result.version			:= arg(159 downto 156);		-- : std_logic_vector(3 downto 0);
		result.ihl				:= arg(155 downto 152);		-- : std_logic_vector(3 downto 0);
		result.tos				:= arg(151 downto 144);		-- : std_logic_vector(7 downto 0);	-- type-of-service		
		result.total_len		:= arg(143 downto 128);		-- : std_logic_vector(15 downto 0);		
		result.identifier		:= arg(127 downto 112);		-- : std_logic_vector(15 downto 0);		
		result.flags			:= arg(111 downto 109);		-- : std_logic_vector(2 downto 0);
		result.frag_offset	:= arg(108 downto 96);		-- : std_logic_vector(12 downto 0);	-- fragment-offset		
		result.ttl				:= arg(95  downto 88);		-- : std_logic_vector(7 downto 0);
		result.protocol		:= arg(87  downto 80);		-- : std_logic_vector(7 downto 0);		
		result.check_sum		:= arg(79  downto 64);		-- : std_logic_vector(15 downto 0);		
		result.src_ip			:= arg(63  downto 32);		-- : std_logic_vector(31 downto 0);		
		result.dst_ip			:= arg(31  downto 0);		-- : std_logic_vector(31 downto 0);
		return result;
	end function to_ipv4_header;
	-----------------------------------
	
	-----------------------------------
	--  UDP
	-----------------------------------
	function from_udp_header( arg : t_udp_header ) return std_logic_vector is
		variable result : std_logic_vector(63 downto 0);
	begin
		result(63 downto 48)	:= arg.src_port;		-- : std_logic_vector(15 downto 0);
		result(47 downto 32)	:= arg.dst_port;		-- : std_logic_vector(15 downto 0);
		result(31 downto 16)	:= arg.udp_len;		-- : std_logic_vector(15 downto 0);
		result(15  downto 0)	:= arg.check_sum;		-- : std_logic_vector(15 downto 0);
		return result;
	end function from_udp_header;
	-------------------------------

	-------------------------------
	--  ARP
	-------------------------------
	function to_arp_data( arg : std_logic_vector(223 downto 0) ) return t_arp_data is
		variable result : t_arp_data;
	begin
		result.hw_type				:= arg(223 downto 208);	
		result.proto				:= arg(207 downto 192);
		result.hw_addr_len		:= arg(191 downto 184);
		result.prot_addr_len		:= arg(183 downto 176);
		result.opcode				:= arg(175 downto 160);
		result.sender_hw_addr	:= arg(159 downto 112);
		result.sender_prot_addr	:= arg(111 downto 80);
		result.target_hw_addr	:= arg(79  downto 32);
		result.target_prot_addr	:= arg(31  downto 0);
		return result;
	end function to_arp_data;
   
	function from_arp_data( arg : t_arp_data  ) return std_logic_vector is
		variable result : std_logic_vector(223 downto 0);
	begin
		result(223 downto 208)	:= arg.hw_type;
		result(207 downto 192)	:= arg.proto;
		result(191 downto 184)	:= arg.hw_addr_len;
		result(183 downto 176)	:= arg.prot_addr_len;
		result(175 downto 160)	:= arg.opcode;
		result(159 downto 112)	:= arg.sender_hw_addr;
		result(111 downto 80)	:= arg.sender_prot_addr;
		result(79  downto 32)	:= arg.target_hw_addr;
		result(31  downto 0)		:= arg.target_prot_addr;
		return result;
	end function from_arp_data;
	------------------------------

	------------------------------
	--  ICMP_ECHO
	------------------------------
	function to_icmp( arg : std_logic_vector(319 downto 0) ) return t_icmp is
		variable result : t_icmp;
	begin
		result.icmp_type	:= arg(319 downto 312);	-- std_logic_vector(7  downto 0);
		result.code			:= arg(311 downto 304); -- std_logic_vector(7  downto 0);
		result.check_sum	:= arg(303 downto 288); -- std_logic_vector(15 downto 0);
		result.identifier	:= arg(287 downto 272); -- std_logic_vector(15 downto 0);
		result.seq_num		:= arg(271 downto 256); -- std_logic_vector(15 downto 0);
		result.data			:= arg(255 downto 0);   -- std_logic_vector(255 downto 0);
		return result;
	end function to_icmp;
   
	function icmp_echo_check_summ(arg : std_logic_vector(319 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(19 downto 0);
		variable tmp : integer := 0;
	begin
		tmp :=       to_integer(unsigned(arg(319 downto 304)));
		tmp := tmp + to_integer(unsigned(arg(287 downto 272)));
		tmp := tmp + to_integer(unsigned(arg(271 downto 256)));
		tmp := tmp + to_integer(unsigned(arg(255 downto 240)));
		tmp := tmp + to_integer(unsigned(arg(239 downto 224)));
		tmp := tmp + to_integer(unsigned(arg(223 downto 208)));
		tmp := tmp + to_integer(unsigned(arg(207 downto 192)));
		tmp := tmp + to_integer(unsigned(arg(191 downto 176)));
		tmp := tmp + to_integer(unsigned(arg(175 downto 160)));
		tmp := tmp + to_integer(unsigned(arg(159 downto 144)));
		tmp := tmp + to_integer(unsigned(arg(143 downto 128)));
		tmp := tmp + to_integer(unsigned(arg(127 downto 112)));
		tmp := tmp + to_integer(unsigned(arg(111 downto 96)));
		tmp := tmp + to_integer(unsigned(arg(95  downto 80)));
		tmp := tmp + to_integer(unsigned(arg(79  downto 64)));
		tmp := tmp + to_integer(unsigned(arg(63  downto 48)));
		tmp := tmp + to_integer(unsigned(arg(47  downto 32)));
		tmp := tmp + to_integer(unsigned(arg(31  downto 16)));
		tmp := tmp + to_integer(unsigned(arg(15  downto 0)));
		
		result := std_logic_vector(to_unsigned(tmp, result'length));
		tmp := to_integer(unsigned(result(15  downto 0))) + to_integer(unsigned(result(19  downto 16)));
		result := std_logic_vector(to_unsigned(tmp, result'length));
		return result(15 downto 0);
	end function icmp_echo_check_summ;

	function from_icmp_echo( arg : t_icmp  ) return std_logic_vector is
		variable result : std_logic_vector(319 downto 0);
	begin
		result(319 downto 312)	:= arg.icmp_type;
		result(311 downto 304)	:= arg.code;
		--result(303 downto 288)	:= arg.check_sum;
		result(287 downto 272)	:= arg.identifier;
		result(271 downto 256)	:= arg.seq_num;
		result(255 downto 0)		:= arg.data;
		
		-- check summ
		result(303 downto 288)	:= not icmp_echo_check_summ(result);
		return result;
	end function from_icmp_echo;
	---------------------------------------
   
	constant c_tx_eth_frame_size 	: natural := 2048*8;	-- 8-bit words
	signal r_tx_eth_frame 			: std_logic_vector(c_tx_eth_frame_size - 1 downto 0) := (others => '0');
	signal r_tx_eth_frame_size		: natural range 0 to c_tx_eth_frame_size - 1 := 0;
	signal r_tx_eth_counter			: natural range 0 to c_tx_eth_frame_size/8 - 1 := 0;

	signal r_test_tx_clock_counter	: natural range 0 to 50000000 := 49999872;
	
	signal r_udp_counter : natural range 0 to 255 := 0;
	
	signal r_phi_inc : std_logic_vector(23 downto 0) := x"400000"; -- decimal 4194304 for NCO freq 5 MHz
	--signal r_phi_inc : std_logic_vector(23 downto 0) := x"0020C5"; -- decimal 8389 for NCO freq 0.01 MHz
	
	 
begin
	Out_Phi_Inc <= r_phi_inc;
	
	--r_RST <= not In_RST;
	Out_RMII_Reset <= not In_RST;

	Out_LEDS(0) <= r_Out_LED_1;
	Out_LEDS(1) <= r_Out_LED_2;
	Out_LEDS(2) <= r_Out_LED_3;
	Out_LEDS(3) <= r_Out_LED_4;
	
	Out_Debug_Data_Ready <= r_Debug_Data_Ready;
	Out_Debug_Data <= r_Debug_Data;

	RMII_RX : rmii_to_bytestream
		port map (
			 ref_clk		=> In_RMII_CLK,
			 -- RMII
			 i_dv			=> In_RMII_CRS_DV,
			 i_dt			=> In_RMII_RX,
			 -- internal byte stream
			 o_dv			=> r_RMII_RX_dv,
			 o_str_dt	=> r_RMII_RX_str_dt,
			 o_data		=> r_RMII_RX_data
		);
		
	dut: eth100_link_tx
		generic map (
			FRBUF_MEM_ADDR_W,   -- : natural := 9;
			IGAP_LEN,           -- : natural := 6;                -- inter-frame gap in bytes
			M1_SUPPORT_READ,    -- : boolean := true;      -- whether port 2 is read-write (when true) or read-only (when false)
			M1_DELAY,           -- : natural := 2;                -- read delay: 2=insert register at inputs
			TXFIFO_DEPTH_W,     --: natural := 4        -- fifo depth is 2**FIFO_DEPTH_W elements
			FRTAG_W
		)
		port map (
			-- RMII
			ref_clk			=> In_RMII_CLK,    --: in std_logic;         -- RMII ref_clk
			rmii_txen		=> Out_RMII_TX_Enable,   --: out std_logic;
			rmii_txdt		=> Out_RMII_TX,   --: out std_logic_vector(1 downto 0);
			--
			clk				=> In_CLK_50,         --: in std_logic;
			rst				=> In_RST,         --: in std_logic;
			-- access to frame buffer memory
			m1_addr			=> r_m1_addr,     --: in std_logic_vector(FRBUF_MEM_ADDR_W-1 downto 0);  -- buffer address, granularity 32b words
			m1_wdt			=> r_m1_wdt,      --: in std_logic_vector(31 downto 0);            -- buffer write data 
			m1_wstrobe		=> r_m1_wstrobe,  --: in std_logic;                                -- strobe to write data into the buffer
			m1_rstrobe		=> r_m1_rstrobe,  --: in std_logic;                                -- strobe to write data into the buffer
			m1_rdt			=> r_m1_rdt,      --: out std_logic_vector(31 downto 0);            -- buffer write data 
			--
			-- for removing processed (sent) frames by the tx-link
			rf_strobe		=> r_rf_strobe,   --: out std_logic;                                  -- remove frame of lenght rf_frlen from the bottom of the circular buffer
			rf_tag_len_ptr	=> r_rf_tag_len_ptr,
			-- to push-fifo queue of frames to transmit
			pf_enq			=> r_pf_enq,      --: in std_logic;                                     -- enqueue data command
			pf_tag_len_ptr	=> r_pf_tag_len_ptr,
			pf_full			=> r_pf_full     --: out std_logic                                   -- full fifo indication (must not enqueue more)
		) ;


	eth_tx_proc:process (In_CLK_50, r_eth_request_ready)
		variable wdt : std_logic_vector(31 downto 0);
		variable v_mac_header	: t_mac_header;
		variable v_ipv4_header	: t_ipv4_header;
		variable v_udp_header	: t_udp_header;	
		variable v_tmp_h, v_tmp_l	: natural;
		variable v_arp_data		: t_arp_data;
		variable v_icmp 			: t_icmp;
	begin
		if rising_edge(In_CLK_50) then
			if In_RST = '1' then
				r_pf_enq <= '0';
				r_pf_tag_len_ptr <= (others => '0');
				r_m1_addr <= (others => '0');
				r_m1_wdt <= (others => '0');
				r_m1_wstrobe <= '0';
				r_m1_rstrobe <= '0';
				r_tx_eth_state <= TX_IDLE;
				r_reply_ready <= '0';
			else
				if r_eth_request_ready = '1' then
					r_reply_ready <= '1';
				end if;
				case r_tx_eth_state is
					when TX_IDLE =>
						r_pf_enq <= '0';
						r_pf_tag_len_ptr <= (others => '0');
						r_m1_addr <= (others => '0');
						r_m1_wdt <= (others => '0');
						r_m1_wstrobe <= '0';
						r_m1_rstrobe <= '0';
						r_tx_eth_counter <= 0;
						
						if r_reply_ready = '1' then
							r_reply_ready <= '0';
							r_tx_eth_state <= PREPARE_REPLY_DATA;
						elsif In_UDP_data_ready = '1' then
							r_tx_eth_state <= PREPARE_ADC_DATA;
						end if;
					
					when PREPARE_ADC_DATA =>
						v_mac_header.dst_mac := r_dst_MAC;
						v_mac_header.src_mac := c_src_MAC;
						v_mac_header.proto 	:= x"0800";
						
						v_ipv4_header.version		:= x"4";
						v_ipv4_header.ihl				:= x"5";
						v_ipv4_header.tos				:= x"00";
						v_ipv4_header.identifier	:= x"B3FE";
						v_ipv4_header.flags			:= b"000";
						v_ipv4_header.frag_offset	:= b"0000000000000";
						v_ipv4_header.ttl				:= x"80";
						v_ipv4_header.protocol		:= x"11";	-- UDP
						--v_ipv4_header.check_sum	:= x"72BA";
						v_ipv4_header.src_ip			:= c_src_IP;
						v_ipv4_header.dst_ip			:= r_dst_IP;
						
						v_udp_header.src_port		:= c_src_Port;
						v_udp_header.dst_port		:= r_dst_Port;
						v_udp_header.check_sum		:= x"0000";
						
						v_tmp_h := ADC_BUFFER_SIZE*4 + 2 + 8; -- ADC payload + 8 bytes for UDP header + 2 padding bytes
						v_udp_header.udp_len := std_logic_vector(to_unsigned(v_tmp_h, 16));
						v_tmp_h := v_tmp_h + 20; -- +20 bytes for IP header
						v_ipv4_header.total_len	:= std_logic_vector(to_unsigned(v_tmp_h, 16));

						v_tmp_l := 112;
						r_tx_eth_frame(c_tx_eth_frame_size - 1
											downto c_tx_eth_frame_size - v_tmp_l) <= from_mac_header(v_mac_header);
						v_tmp_h := v_tmp_l;
						v_tmp_l := v_tmp_l + 160;
						r_tx_eth_frame(c_tx_eth_frame_size - v_tmp_h - 1
											downto c_tx_eth_frame_size - v_tmp_l) <= from_ipv4_header(v_ipv4_header);
						v_tmp_h := v_tmp_l;
						v_tmp_l := v_tmp_l + 64;
						r_tx_eth_frame(c_tx_eth_frame_size - v_tmp_h - 1
											downto c_tx_eth_frame_size - v_tmp_l) <= from_udp_header(v_udp_header);
						r_tx_eth_frame_size <= v_tmp_l;
						
						--v_tmp_h := v_tmp_l;
						--v_tmp_l := v_tmp_l + r_ADC_buffer'length; --1500;
						--r_tx_eth_frame(c_tx_eth_frame_size - v_tmp_h - 1
						--					downto c_tx_eth_frame_size - v_tmp_l) <= r_ADC_buffer(r_ADC_buffer'length - 1 downto 0);
						--r_tx_eth_frame_size <= v_tmp_l;
						r_tx_eth_state <= WRITE_ADC_HEADER;

					when WRITE_ADC_HEADER =>
						v_tmp_h := r_tx_eth_frame'length - r_tx_eth_counter*8*4;
						wdt(7 downto 0)   := r_tx_eth_frame(v_tmp_h - 1  downto v_tmp_h - 8);
						wdt(15 downto 8)  := r_tx_eth_frame(v_tmp_h - 9  downto v_tmp_h - 16);
						if r_tx_eth_counter < 10 then
							wdt(23 downto 16) := r_tx_eth_frame(v_tmp_h - 17 downto v_tmp_h - 24);
							wdt(31 downto 24) := r_tx_eth_frame(v_tmp_h - 25 downto v_tmp_h - 32);
						else			
							wdt(23 downto 16) := std_logic_vector(to_unsigned(r_udp_counter, 8)); --x"00"; --r_ADC_buffer(v_tmp_h - 1  downto v_tmp_h - 8);
							r_udp_counter <= r_udp_counter + 1;
							wdt(31 downto 24) := x"00"; --r_ADC_buffer(v_tmp_h - 9  downto v_tmp_h - 16);
						end if;
						
						r_m1_addr <= std_logic_vector(to_unsigned(r_tx_eth_counter, FRBUF_MEM_ADDR_W));
						r_m1_wdt <= wdt;
						r_m1_wstrobe <= '1';
						--if r_tx_eth_counter*8*4 < r_tx_eth_frame_size - 32 then
						if r_tx_eth_counter < 10 then
							if r_tx_eth_counter = 9 then
								Out_UDP_data_strob <= '1';
							end if;
							r_tx_eth_counter <= r_tx_eth_counter + 1;
						else
							r_tx_eth_counter <= r_tx_eth_counter + 1;
							--Out_IQ_read_strob <= '1';
							r_tx_eth_state <= WRITE_ADC_DATA;
						end if;
						
					when WRITE_ADC_DATA =>
						--v_tmp_h := ADC_BUFFER_SIZE*r_read_RAM_buffer_index + (r_tx_eth_counter - 11);
						wdt(7  downto 0)  := In_UDP_data(15 downto 8);  --x"01";  -- Данные из буфера
						wdt(15 downto 8)  := In_UDP_data(7  downto 0);  --x"02";  -- Данные из буфера
						wdt(23 downto 16) := In_UDP_data(31 downto 24); --x"03";  -- Данные из буфера
						wdt(31 downto 24) := In_UDP_data(23 downto 16); --x"04";  -- Данные из буфера
						
						r_m1_addr <= std_logic_vector(to_unsigned(r_tx_eth_counter, FRBUF_MEM_ADDR_W));
						r_m1_wdt <= wdt;
						r_m1_wstrobe <= '1';
						if In_UDP_data_ready = '1' then
							r_tx_eth_counter <= r_tx_eth_counter + 1;
						else
							r_tx_eth_counter <= r_tx_eth_counter + 1;
							r_tx_eth_state <= ENQUE_DATA;
							Out_UDP_data_strob <= '0';
						end if;
						
					when PREPARE_REPLY_DATA =>
						v_mac_header.dst_mac 		:= r_arp_data.sender_hw_addr; --r_dst_MAC;
						v_mac_header.src_mac 		:= c_src_MAC;
						
						if r_eth_request_type = ARP then
							v_mac_header.proto := x"0806";
							
							v_arp_data.hw_type				:= x"0001"; --r_arp_data.hw_type;
							v_arp_data.proto					:= x"0800"; --r_arp_data.proto;
							v_arp_data.hw_addr_len			:= x"06"; --r_arp_data.hw_addr_len;
							v_arp_data.prot_addr_len		:= x"04"; --r_arp_data.prot_addr_len;
							v_arp_data.opcode					:= x"0002";
							v_arp_data.sender_hw_addr		:= c_src_MAC;
							v_arp_data.sender_prot_addr	:= c_src_IP;
							v_arp_data.target_hw_addr		:= r_arp_data.sender_hw_addr; --r_dst_MAC; --r_arp_data.sender_hw_addr;
							v_arp_data.target_prot_addr	:= r_arp_data.sender_prot_addr; --r_arp_data.sender_prot_addr;
							
							v_tmp_l := 112;
							r_tx_eth_frame(c_tx_eth_frame_size - 1
												downto c_tx_eth_frame_size - v_tmp_l) <= from_mac_header(v_mac_header);
							v_tmp_h := v_tmp_l;
							v_tmp_l := v_tmp_l + 224;
							r_tx_eth_frame(c_tx_eth_frame_size - v_tmp_h - 1
												downto c_tx_eth_frame_size - v_tmp_l) <= from_arp_data(v_arp_data);
							r_tx_eth_frame_size <= v_tmp_l;
						elsif r_eth_request_type = ICMP_ECHO then
							v_mac_header.proto 	:= x"0800";
							
							v_ipv4_header.version		:= x"4";
							v_ipv4_header.ihl				:= x"5";
							v_ipv4_header.tos				:= x"00";
							v_ipv4_header.identifier	:= x"B3FE";
							v_ipv4_header.flags			:= b"000";
							v_ipv4_header.frag_offset	:= b"0000000000000";
							v_ipv4_header.ttl				:= x"80";
							v_ipv4_header.protocol		:= x"01";	-- ICMP
							--v_ipv4_header.check_sum	:= x"72BA";
							v_ipv4_header.src_ip			:= c_src_IP;
							v_ipv4_header.dst_ip			:= r_dst_IP;
							v_ipv4_header.total_len		:= x"003C"; -- 60;
							
							v_icmp.icmp_type	:= x"00";
							v_icmp.code			:= x"00";
							v_icmp.check_sum	:= r_icmp.check_sum;
							v_icmp.identifier	:= r_icmp.identifier;
							v_icmp.seq_num		:= r_icmp.seq_num;
							v_icmp.data			:= r_icmp.data;

							v_tmp_l := 112;
							r_tx_eth_frame(c_tx_eth_frame_size - 1
												downto c_tx_eth_frame_size - v_tmp_l) <= from_mac_header(v_mac_header);
							v_tmp_h := v_tmp_l;
							v_tmp_l := v_tmp_l + 160;
							r_tx_eth_frame(c_tx_eth_frame_size - v_tmp_h - 1
												downto c_tx_eth_frame_size - v_tmp_l) <= from_ipv4_header(v_ipv4_header);
							v_tmp_h := v_tmp_l;
							v_tmp_l := v_tmp_l + 320;
							r_tx_eth_frame(c_tx_eth_frame_size - v_tmp_h - 1
												downto c_tx_eth_frame_size - v_tmp_l) <= from_icmp_echo(v_icmp);
							r_tx_eth_frame_size <= v_tmp_l;
						end if;
						r_tx_eth_state <= WRITE_REPLY_DATA;
						
					when WRITE_REPLY_DATA =>
						wdt(7 downto 0)   := r_tx_eth_frame(c_tx_eth_frame_size - 1  downto c_tx_eth_frame_size - 8);
						wdt(15 downto 8)  := r_tx_eth_frame(c_tx_eth_frame_size - 9  downto c_tx_eth_frame_size - 16);
						wdt(23 downto 16) := r_tx_eth_frame(c_tx_eth_frame_size - 17 downto c_tx_eth_frame_size - 24);
						wdt(31 downto 24) := r_tx_eth_frame(c_tx_eth_frame_size - 25 downto c_tx_eth_frame_size - 32);
						r_tx_eth_frame <= r_tx_eth_frame(c_tx_eth_frame_size - 33 downto 0) & x"00000000";
						r_m1_addr <= std_logic_vector(to_unsigned(r_tx_eth_counter, FRBUF_MEM_ADDR_W));
						r_m1_wdt <= wdt;
						r_m1_wstrobe <= '1';
						--if r_tx_eth_counter < (r_tx_eth_frame_size/8)/4 - 1 then
						if r_tx_eth_counter*8*4 < r_tx_eth_frame_size - 32 then
							r_tx_eth_counter <= r_tx_eth_counter + 1;
						else
							--r_tx_eth_counter <= 0;
							r_tx_eth_counter <= r_tx_eth_counter + 1;
							r_tx_eth_state <= ENQUE_DATA;
						end if;
					
					when ENQUE_DATA =>
						r_m1_wstrobe <= '0';
						--r_pf_tag_len_ptr(2*FRBUF_MEM_ADDR_W-1 downto FRBUF_MEM_ADDR_W) <= std_logic_vector(to_unsigned((r_tx_eth_frame_size/8)/4, FRBUF_MEM_ADDR_W));
						r_pf_tag_len_ptr(2*FRBUF_MEM_ADDR_W-1 downto FRBUF_MEM_ADDR_W) <= std_logic_vector(to_unsigned(r_tx_eth_counter, FRBUF_MEM_ADDR_W));
						r_pf_enq <= '1';
						r_tx_eth_counter <= 0;
						r_tx_eth_state <= TX_IDLE;
					
				end case;
				
			end if;
		end if;
	end process;

		
	Blink_1Hz:process (In_RMII_CLK)
	begin
		if rising_edge(In_RMII_CLK) then
			if In_RST = '1' then
				r_blink_counter <= 0; -- (others => '0');
				--Out_RMII_Reset <= '0';
			else
				--Out_RMII_Reset <= '1';
				if (r_blink_counter = 50_000_000) then
					r_blink_counter <= 0;
					r_Out_LED_3 <= not r_Out_LED_3;
					r_Out_LED_4 <= not r_Out_LED_4;
				else
					r_blink_counter <= r_blink_counter + 1;
				end if;
			end if;
		end if;
	end process;
	
	--r_Out_LED_3 <= not r_Out_LED_3 when r_blink_counter = 50_000_000;
	--r_Out_LED_4 <= not r_Out_LED_4 when r_blink_counter = 50_000_000;
	
	
	-- This is byte stream from rmii_to_bytestream
	eth_rx_proc:process (In_RMII_CLK)	 
		variable v_mac_header		: t_mac_header;
		variable v_arp_data			: t_arp_data;
		variable v_ipv4_header		: t_ipv4_header;
		variable v_icmp				: t_icmp;
		variable v_tmp_h, v_tmp_l	: natural;
	begin
		if rising_edge(In_RMII_CLK) then
			if In_RST = '1' then
				--r_Out_LED_2 <= '1';
				Debug_Buffer_count <= 0;
				r_Debug_Data_Ready <= '0';
				r_eth_request_ready <= '0';
			else
				if Debug_Buffer_count > 0 then
					r_Debug_Data_Ready <= '1';
					r_Debug_Data <= Debug_Buffer(c_Debug_Buffer_size - 1 downto c_Debug_Buffer_size - 8);
					Debug_Buffer <= Debug_Buffer(c_Debug_Buffer_size - 9 downto 0) & x"00";
					Debug_Buffer_count <= Debug_Buffer_count - 8;
				else
					r_Debug_Data_Ready <= '0';
				end if;
				
				if r_RMII_RX_dv = '0' then
--					r_UART_TX_Byte_Ready <= '0';
					-- reset eth_frame structure
					--r_eth_frame_tmp <= (others => '0');
					--r_mac_header_vect_count <= 111;
					--r_arp_data_vect_count <= 223;
					
					r_rx_eth_state <= RX_IDLE;
					
					r_eth_request_ready <= '0';
				else
					case r_rx_eth_state is
						when RX_IDLE =>	
							--r_UART_TX_Buffer_Ready <= '0';
							r_rx_eth_state <= MAC_HEADER;
							r_RMII_RX_buffer_count <= 111;
						
						when DISCARD =>	 
							r_eth_request_ready <= '0';
						
						when MAC_HEADER =>
							if r_RMII_RX_str_dt = '1' then
								-- Reset prev requests --
								r_eth_request_ready <= '0';
								
								r_RMII_RX_buffer(r_RMII_RX_buffer_count downto r_RMII_RX_buffer_count - 7) <= r_RMII_RX_data;
								if r_RMII_RX_buffer_count > 7 then
									r_RMII_RX_buffer_count <= r_RMII_RX_buffer_count - 8;
								else
									--r_mac_header_vect_count <= 111;
									v_mac_header := to_mac_header(r_RMII_RX_buffer(111 downto 8) & r_RMII_RX_data);
									
									-- write to Debug_Buffer
									Debug_Buffer(799 downto 736) <= str_to_std_logic_vector("DSTMAC: ");	-- add 8 bytes of 'DSTMAC: '											
									Debug_Buffer(735 downto 632) <= str_to_std_logic_vector_with_return(to_hstring(v_mac_header.dst_mac));-- add 6 bytes of MAC value											
									Debug_Buffer(631 downto 568) <= str_to_std_logic_vector("SRCMAC: "); -- add 8 bytes of 'SRCMAC: '											
									Debug_Buffer(567 downto 464) <= str_to_std_logic_vector_with_return(to_hstring(v_mac_header.src_mac)); -- add 6 bytes of MAC value											
									Debug_Buffer(463 downto 400) <= str_to_std_logic_vector("PROTO : "); -- add 8 bytes of 'PROTO : '											
									Debug_Buffer(399 downto 360) <= str_to_std_logic_vector_with_return(to_hstring(v_mac_header.proto)); -- add 4 bytes of PROTO ASCII HEX value											
									Debug_Buffer(359 downto 352) <= x"0A"; -- add 2 bytes '0A0A'
									Debug_Buffer_count <= 448;
									if (v_mac_header.dst_mac = x"FFFFFFFFFFFF") or (v_mac_header.dst_mac = c_src_MAC) then
										r_rx_mac_header <= v_mac_header;
										--r_dst_MAC <= x"7C8BCA0AC10F";
										
										if v_mac_header.proto = x"0806" then -- ARP
											r_rx_eth_state <= ARP;
											r_RMII_RX_buffer_count <= 223;
										elsif v_mac_header.proto = x"0800" then -- IP v4
											r_rx_eth_state <= IPV4_HEADER;
											r_RMII_RX_buffer_count <= 159;
										else
											r_rx_eth_state <= DISCARD;
											r_Out_LED_1 <= not r_Out_LED_1;
										end if;
									else
										r_rx_eth_state <= DISCARD;
									end if;
											
								end if;	
							end if;
							
						when ARP =>
							if r_RMII_RX_str_dt = '1' then
								r_RMII_RX_buffer(r_RMII_RX_buffer_count downto r_RMII_RX_buffer_count - 7) <= r_RMII_RX_data;
								if r_RMII_RX_buffer_count > 7 then
									r_RMII_RX_buffer_count <= r_RMII_RX_buffer_count - 8;
								else
									v_arp_data := to_arp_data(r_RMII_RX_buffer(223 downto 8) & r_RMII_RX_data);
									
									-- write to Debug_Buffer
									Debug_Buffer(799 downto 760) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.hw_type));
									Debug_Buffer(759 downto 720) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.proto));
									Debug_Buffer(719 downto 696) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.hw_addr_len));
									Debug_Buffer(695 downto 672) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.prot_addr_len));
									Debug_Buffer(671 downto 632) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.opcode));
									Debug_Buffer(631 downto 528) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.sender_hw_addr));
									Debug_Buffer(527 downto 456) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.sender_prot_addr));
									Debug_Buffer(455 downto 352) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.target_hw_addr));
									Debug_Buffer(351 downto 280) <= str_to_std_logic_vector_with_return(to_hstring(v_arp_data.target_prot_addr));
									Debug_Buffer(279 downto 272) <= x"0A"; -- add 2 bytes '0A0A'
									--Debug_Buffer_count <= 528;
									
									r_arp_data <= v_arp_data;
									r_eth_request_ready <= '1';
									r_eth_request_type <= ARP;
									
									r_rx_eth_state <= DISCARD;
								end if;	
							end if;

						when IPV4_HEADER =>
							if r_RMII_RX_str_dt = '1' then
								r_RMII_RX_buffer(r_RMII_RX_buffer_count downto r_RMII_RX_buffer_count - 7) <= r_RMII_RX_data;
								if r_RMII_RX_buffer_count > 7 then
									r_RMII_RX_buffer_count <= r_RMII_RX_buffer_count - 8;
								else
									v_ipv4_header := to_ipv4_header(r_RMII_RX_buffer(159 downto 8) & r_RMII_RX_data);
									if v_ipv4_header.protocol = x"01" then
										r_rx_eth_state <= ICMP;
										r_RMII_RX_buffer_count <= to_integer(unsigned(v_ipv4_header.total_len))*8 - 160 - 1;  -- 319
										--r_Out_LED_1 <= not r_Out_LED_1;
									else
										r_rx_eth_state <= DISCARD;
									end if;
								end if;
							end if;
									
						when ICMP =>
							if r_RMII_RX_str_dt = '1' then
								r_RMII_RX_buffer(r_RMII_RX_buffer_count downto r_RMII_RX_buffer_count - 7) <= r_RMII_RX_data;
								if r_RMII_RX_buffer_count > 7 then
									r_RMII_RX_buffer_count <= r_RMII_RX_buffer_count - 8;
								else
									v_icmp := to_icmp(r_RMII_RX_buffer(319 downto 8) & r_RMII_RX_data);
									--r_Out_LED_1 <= not r_Out_LED_1;
									if v_icmp.icmp_type = x"08" then
										-- ECHO request
										r_icmp <= v_icmp;
										r_eth_request_ready <= '1';
										r_eth_request_type <= ICMP_ECHO;
										r_Out_LED_2 <= not r_Out_LED_2;
									end if;
									r_rx_eth_state <= DISCARD;

								end if;	
							end if;
						
					end case;
				end if; -- r_RMII_RX_dv = '0'
			end if; -- r_rst = '1'
		end if; -- rising_edge(In_RMII_CLK)
	end process;
	
	
end rtl;