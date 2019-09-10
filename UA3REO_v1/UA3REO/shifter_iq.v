//двухканальный модуль понижения разрядности шины
module shifter_iq(
data_in1,
data_in2,
data_out1,
data_out2
);

parameter in_width = 16;
parameter out_width = 12;


input [in_width-1:0] data_in1;
output [out_width-1:0] data_out1;
input [in_width-1:0] data_in2;
output [out_width-1:0] data_out2;

assign data_out1 = data_in1 >>> (in_width-out_width);
assign data_out2 = data_in2 >>> (in_width-out_width);

endmodule
