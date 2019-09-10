module DeltaSigmaDAC(DACout, DACin, clk);
parameter WIDTH = 11;
input[WIDTH-1:0] DACin;
input clk;
output DACout;

reg[WIDTH:0] acc = 0;
assign DACout = acc[WIDTH];

always @(posedge clk) acc <= acc + DACin + DACout - (DACout << WIDTH);

endmodule