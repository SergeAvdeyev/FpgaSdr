//одноканальный модуль понижения разрядности шины
module shifter_iq_single(
data_in,
data_out
);

parameter in_width = 16;
parameter out_width = 12;


input [in_width-1:0] data_in;
output [out_width-1:0] data_out;

assign data_out = data_in >>> (in_width-out_width);

endmodule
