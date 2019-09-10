module FrequencyRegister(

    output [21:0] OUT_phase
         
);

//freq in hz/oscil in hz*2^bits
//assign OUT_phase = (freq/50000000)*4194304;
assign OUT_phase = 593410; //7.074

endmodule