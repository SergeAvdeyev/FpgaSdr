	component nios is
		port (
			clk_clk                                : in  std_logic                     := 'X'; -- clk
			epcs_flash_controller_0_external_dclk  : out std_logic;                            -- dclk
			epcs_flash_controller_0_external_sce   : out std_logic;                            -- sce
			epcs_flash_controller_0_external_sdo   : out std_logic;                            -- sdo
			epcs_flash_controller_0_external_data0 : in  std_logic                     := 'X'; -- data0
			pio_0_external_connection_export       : out std_logic_vector(21 downto 0);        -- export
			pio_mode_external_connection_export    : out std_logic;                            -- export
			reset_reset_n                          : in  std_logic                     := 'X'; -- reset_n
			uart_0_external_connection_rxd         : in  std_logic                     := 'X'; -- rxd
			uart_0_external_connection_txd         : out std_logic                             -- txd
		);
	end component nios;

	u0 : component nios
		port map (
			clk_clk                                => CONNECTED_TO_clk_clk,                                --                              clk.clk
			epcs_flash_controller_0_external_dclk  => CONNECTED_TO_epcs_flash_controller_0_external_dclk,  -- epcs_flash_controller_0_external.dclk
			epcs_flash_controller_0_external_sce   => CONNECTED_TO_epcs_flash_controller_0_external_sce,   --                                 .sce
			epcs_flash_controller_0_external_sdo   => CONNECTED_TO_epcs_flash_controller_0_external_sdo,   --                                 .sdo
			epcs_flash_controller_0_external_data0 => CONNECTED_TO_epcs_flash_controller_0_external_data0, --                                 .data0
			pio_0_external_connection_export       => CONNECTED_TO_pio_0_external_connection_export,       --        pio_0_external_connection.export
			pio_mode_external_connection_export    => CONNECTED_TO_pio_mode_external_connection_export,    --     pio_mode_external_connection.export
			reset_reset_n                          => CONNECTED_TO_reset_reset_n,                          --                            reset.reset_n
			uart_0_external_connection_rxd         => CONNECTED_TO_uart_0_external_connection_rxd,         --       uart_0_external_connection.rxd
			uart_0_external_connection_txd         => CONNECTED_TO_uart_0_external_connection_txd          --                                 .txd
		);

