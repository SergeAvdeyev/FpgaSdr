library ieee;
use ieee.std_logic_1164.all;

-- 
-- Converts input RMII stream to am internal byte-stream with a lower data frequency.
-- 
entity rmii_to_bytestream is
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
end entity ; -- rmii_to_bytestream


architecture rtl of rmii_to_bytestream is

    subtype count_t is integer range 0 to 3;

    -- internal register type
    type registers_t is record
        str : std_logic;
        dv : std_logic;
        dt_tmp : std_logic_vector(7 downto 0);
		  dt : std_logic_vector(7 downto 0);
        cnt : count_t;
		  --skip : std_logic;
    end record;
    signal r : registers_t;
	 
	 signal skip : std_logic := '1';

begin


	ff: process (ref_clk)
	variable v : registers_t;
	begin
		if rising_edge(ref_clk) then
			v := r;

			-- no strobe by default
			v.str := '0';

			-- check rmii data-valid signal
			if i_dv = '0' then
				-- rmii data not valid, just reset the counter.
				-- Strobe and DV outputs are reset above.
				v.cnt := 0;
				skip <= '1';
				v.dv := '0';
				--v.dt := (others => '0');
			else
				-- copy data-valid signal
				--v.dv := '1';
				if skip = '1' then
					-- Shift in new data.
					-- LSB is transmitted first, so we shift from the left side in:
					v.dt_tmp := i_dt & v.dt_tmp(7 downto 2);
					if v.dt_tmp = x"D5" then
						v.dv := '1';
						skip <= '0';
						--v.str := '1';
						v.cnt := 0;
					end if;
				else
					-- Shift in new data.
					-- LSB is transmitted first, so we shift from the left side in:
					v.dt_tmp := i_dt & v.dt_tmp(7 downto 2);

					-- rmii data is valid;
					if v.cnt = 3 then
						-- And shifted in the last dibit!
						-- Signal the strobe so that data output is admitted downstream.
						v.str := '1';
						-- Reset count
						v.cnt := 0;
						--v.dt := v.dt_tmp;
					else
						-- Some middle dibit shifted in.
						--if v.cnt = 0 then
						--	v.str := '1';
						--end if;
						v.cnt := v.cnt + 1;
					end if;
				end if;
			end if;

			r <= v;
		end if;
	end process;

	-- Set entity outputs
	o_data <= r.dt_tmp;
	o_dv <= r.dv;
	o_str_dt <= r.str;

end architecture ; -- rtl










--library ieee;
--use ieee.std_logic_1164.all;
--
---- 
---- Converts input RMII stream to am internal byte-stream with a lower data frequency.
---- 
--entity rmii_to_bytestream is
--port (
--    clk         : in std_logic;         -- RMII ref_clk
--    -- RMII
--    i_dv        : in std_logic;
--    i_dt        : in std_logic_vector(1 downto 0);
--    -- internal byte stream
--    o_dv        : out std_logic;        -- kept high so long as we are receiving a frame
--    o_str_dt    : out std_logic;        -- a pulse when r_dt is valid
--    o_dt        : out std_logic_vector(7 downto 0)      -- 1-byte received data, valid only during r_str_dt is active
--) ;
--end entity ; -- rmii_to_bytestream
--
--
--architecture rtl of rmii_to_bytestream is
--
--    subtype count_t is integer range 0 to 3;
--
--    -- internal register type
--    type registers_t is record
--        str : std_logic;
--        dv : std_logic;
--        dt_tmp : std_logic_vector(7 downto 0);
--		  dt : std_logic_vector(7 downto 0);
--        cnt : count_t;
--		  --skip : std_logic;
--    end record;
--    signal r : registers_t;
--	 
--	 signal skip : std_logic := '1';
--
--begin
--
--
--	ff: process (clk)
--	variable v : registers_t;
--	begin
--		if rising_edge(clk) then
--			v := r;
--
--			-- no strobe by default
--			v.str := '0';
--
--			-- check rmii data-valid signal
--			if i_dv = '0' then
--				-- rmii data not valid, just reset the counter.
--				-- Strobe and DV outputs are reset above.
--				v.cnt := 0;
--				skip <= '1';
--				v.dv := '0';
--				--v.dt := (others => '0');
--			else
--				if (skip = '0') or (i_dt(0) = '1' and i_dt(1) = '0') then
--					skip <= '0';
--					-- copy data-valid signal
--					v.dv := '1';
--					-- Shift in new data.
--					-- LSB is transmitted first, so we shift from the left side in:
--					v.dt_tmp := i_dt & v.dt_tmp(7 downto 2);
--
--					-- rmii data is valid;
--					if v.cnt = 3 then
--						-- And shifted in the last dibit!
--						-- Signal the strobe so that data output is admitted downstream.
--						v.str := '1';
--						-- Reset count
--						v.cnt := 0;
--						--v.dt := v.dt_tmp;
--					else
--						-- Some middle dibit shifted in.
--						--if v.cnt = 0 then
--						--	v.str := '1';
--						--end if;
--						v.cnt := v.cnt + 1;
--					end if;
--				end if;
--			end if;
--
--			r <= v;
--		end if;
--	end process;
--
--	-- Set entity outputs
--	o_dt <= r.dt_tmp;
--	o_dv <= r.dv;
--	o_str_dt <= r.str;
--
--end architecture ; -- rtl















--library ieee;
--use ieee.std_logic_1164.all;
--
---- 
---- Converts input RMII stream to am internal byte-stream with a lower data frequency.
---- 
--entity rmii_to_bytestream is
--port (
--    clk         : in std_logic;         -- RMII ref_clk
--    -- RMII
--    i_dv        : in std_logic;
--    i_dt        : in std_logic_vector(1 downto 0);
--    -- internal byte stream
--    o_dv        : out std_logic;        -- kept high so long as we are receiving a frame
--    o_str_dt    : out std_logic;        -- a pulse when r_dt is valid
--    o_dt        : out std_logic_vector(7 downto 0)      -- 1-byte received data, valid only during r_str_dt is active
--) ;
--end entity ; -- rmii_to_bytestream
--
--
--architecture rtl of rmii_to_bytestream is
--
--    subtype count_t is integer range 0 to 3;
--
--    -- internal register type
--    type registers_t is record
--        str : std_logic;
--        dv : std_logic;
--        dt : std_logic_vector(7 downto 0);
--        cnt : count_t;
--    end record;
--
--    signal r, rin : registers_t;
--	 signal skip : std_logic := '1';
--
--begin
--
--	comb: process (r, i_dv, i_dt)
--	variable v : registers_t;
--	begin
--		v := r;
--
--		-- no strobe by default
--		v.str := '0';
--
--		-- check rmii data-valid signal
--		if i_dv = '0' then
--			-- rmii data not valid, just reset the counter.
--			-- Strobe and DV outputs are reset above.
--			v.cnt := 0;
--			skip <= '1';
--			v.dv := '0';
--		else
--			if (skip = '0') or (i_dt(0) = '1' and i_dt(1) = '0') then
--				skip <= '0';
--				-- copy data-valid signal
--				v.dv := '1';
--				-- Shift in new data.
--				-- LSB is transmitted first, so we shift from the left side in:
--				v.dt := i_dt & v.dt(7 downto 2);
--
--				-- rmii data is valid;
--				if v.cnt = 3 then
--					-- And shifted in the last dibit!
--					-- Signal the strobe so that data output is admitted downstream.
--					v.str := '1';
--					-- Reset count
--					v.cnt := 0;
--				else
--					-- Some middle dibit shifted in.
--					v.cnt := v.cnt + 1;
--				end if;
--			end if;
--		end if;
--
--		rin <= v;
--	end process;
--
--	ff: process (clk)
--	begin
--		if rising_edge(clk) then
--			r <= rin;
--		end if;
--	end process;
--
--	-- Set entity outputs
--	o_dv <= r.dv;
--	o_str_dt <= r.str;
--	o_dt <= r.dt;
--
--end architecture ; -- rtl
