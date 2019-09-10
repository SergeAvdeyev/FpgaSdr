
module nios (
	clk_clk,
	epcs_flash_controller_0_external_dclk,
	epcs_flash_controller_0_external_sce,
	epcs_flash_controller_0_external_sdo,
	epcs_flash_controller_0_external_data0,
	pio_0_external_connection_export,
	pio_mode_external_connection_export,
	reset_reset_n,
	uart_0_external_connection_rxd,
	uart_0_external_connection_txd);	

	input		clk_clk;
	output		epcs_flash_controller_0_external_dclk;
	output		epcs_flash_controller_0_external_sce;
	output		epcs_flash_controller_0_external_sdo;
	input		epcs_flash_controller_0_external_data0;
	output	[21:0]	pio_0_external_connection_export;
	output		pio_mode_external_connection_export;
	input		reset_reset_n;
	input		uart_0_external_connection_rxd;
	output		uart_0_external_connection_txd;
endmodule
