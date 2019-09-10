	component SFL_Flash is
		port (
			noe_in : in std_logic := 'X'  -- noe
		);
	end component SFL_Flash;

	u0 : component SFL_Flash
		port map (
			noe_in => CONNECTED_TO_noe_in  -- noe_in.noe
		);

