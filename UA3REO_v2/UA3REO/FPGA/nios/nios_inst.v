	nios u0 (
		.clk_clk                                (<connected-to-clk_clk>),                                //                              clk.clk
		.epcs_flash_controller_0_external_dclk  (<connected-to-epcs_flash_controller_0_external_dclk>),  // epcs_flash_controller_0_external.dclk
		.epcs_flash_controller_0_external_sce   (<connected-to-epcs_flash_controller_0_external_sce>),   //                                 .sce
		.epcs_flash_controller_0_external_sdo   (<connected-to-epcs_flash_controller_0_external_sdo>),   //                                 .sdo
		.epcs_flash_controller_0_external_data0 (<connected-to-epcs_flash_controller_0_external_data0>), //                                 .data0
		.pio_0_external_connection_export       (<connected-to-pio_0_external_connection_export>),       //        pio_0_external_connection.export
		.pio_mode_external_connection_export    (<connected-to-pio_mode_external_connection_export>),    //     pio_mode_external_connection.export
		.reset_reset_n                          (<connected-to-reset_reset_n>),                          //                            reset.reset_n
		.uart_0_external_connection_rxd         (<connected-to-uart_0_external_connection_rxd>),         //       uart_0_external_connection.rxd
		.uart_0_external_connection_txd         (<connected-to-uart_0_external_connection_txd>)          //                                 .txd
	);

