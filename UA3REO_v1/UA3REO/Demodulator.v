module Demodulator(
data_in_a,
data_in_b,
data_out
);

input [11:0] data_in_a;
input [11:0] data_in_b;
output [11:0] data_out;

parameter unsigned [0:0] add_sub = 1'd1; //1-USB 0-LSB

//расширение разрядности для математических операций
wire signed [12:0] result;
wire signed [12:0] data_a_w = (data_in_a[11] == 1'b0)?({1'd0,data_in_a}):({1'd1,data_in_a});//13 bit
wire signed [12:0] data_b_w = (data_in_b[11] == 1'b0)?({1'd0,data_in_b}):({1'd1,data_in_b});

assign result = (add_sub == 1'd1)?( $signed(data_a_w) + $signed(data_b_w)) : ( $signed(data_a_w) - $signed(data_b_w)); //13 bit

assign data_out=result >>> 1;

endmodule
