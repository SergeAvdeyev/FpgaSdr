module ADC2LedDebug(

    input signed [11:0] ADC_Data,
	 input ADC_OTR,

    output out1,
	 output out2,
	 output out3,
	 output out4,
	 output out5,
	 output out6,
	 output out7,
	 output out8
         
);
assign out1 = ADC_Data [11];
assign out2 = ADC_Data [10];
assign out3 = ADC_Data [9];
assign out4 = ADC_Data [8];
assign out5 = ADC_Data [7];
assign out6 = ADC_Data [6];
assign out7 = ADC_Data [5];
assign out8 = ADC_Data [4];

endmodule