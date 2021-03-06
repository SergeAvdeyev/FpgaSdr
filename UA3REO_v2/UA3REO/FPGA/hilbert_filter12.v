// -------------------------------------------------------------
//
// Module: filter12
//
// Generated by MATLAB(R) 7.12 and the Filter Design HDL Coder 2.8.
//
// Generated on: 2014-08-28 21:39:31
//
// -------------------------------------------------------------

// -------------------------------------------------------------
// HDL Code Generation Options:
//
// EDAScriptGeneration: off
// Name: filter12
// TargetLanguage: Verilog
// TestBenchStimulus: impulse step ramp chirp noise 
// GenerateHDLTestBench: off

// -------------------------------------------------------------
// HDL Implementation    : Fully parallel
// Multipliers           : 32
// Folding Factor        : 1
// -------------------------------------------------------------
// Filter Settings:
//
// Discrete-Time FIR Filter (real)
// -------------------------------
// Filter Structure  : Direct-Form FIR
// Filter Length     : 65
// Stable            : Yes
// Linear Phase      : Yes (Type 3)
// Arithmetic        : fixed
// Numerator         : s12,11 -> [-1 1)
// Input             : s12,11 -> [-1 1)
// Filter Internals  : Full Precision
//   Output          : s25,22 -> [-4 4)  (auto determined)
//   Product         : s23,22 -> [-1 1)  (auto determined)
//   Accumulator     : s25,22 -> [-4 4)  (auto determined)
//   Round Mode      : No rounding
//   Overflow Mode   : No overflow
// -------------------------------------------------------------
`timescale 1 ns / 1 ns

module hilbert_filter12
               (
                clk,
                clk_enable,
                reset,
                filter_in,
                filter_out
                );

  input   clk; 
  input   clk_enable; 
  input   reset; 
  input   signed [11:0] filter_in; //sfix12_En11
  output  signed [24:0] filter_out; //sfix25_En22

////////////////////////////////////////////////////////////////
//Module Architecture: filter12
////////////////////////////////////////////////////////////////
  // Local Functions
  // Type Definitions
  // Constants
  parameter signed [11:0] coeff1 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff2 = 12'b111111111011; //sfix12_En11
  parameter signed [11:0] coeff3 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff4 = 12'b111111111011; //sfix12_En11
  parameter signed [11:0] coeff5 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff6 = 12'b111111111000; //sfix12_En11
  parameter signed [11:0] coeff7 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff8 = 12'b111111110100; //sfix12_En11
  parameter signed [11:0] coeff9 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff10 = 12'b111111101111; //sfix12_En11
  parameter signed [11:0] coeff11 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff12 = 12'b111111101001; //sfix12_En11
  parameter signed [11:0] coeff13 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff14 = 12'b111111100001; //sfix12_En11
  parameter signed [11:0] coeff15 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff16 = 12'b111111010111; //sfix12_En11
  parameter signed [11:0] coeff17 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff18 = 12'b111111001010; //sfix12_En11
  parameter signed [11:0] coeff19 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff20 = 12'b111110111010; //sfix12_En11
  parameter signed [11:0] coeff21 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff22 = 12'b111110100100; //sfix12_En11
  parameter signed [11:0] coeff23 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff24 = 12'b111110000110; //sfix12_En11
  parameter signed [11:0] coeff25 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff26 = 12'b111101011000; //sfix12_En11
  parameter signed [11:0] coeff27 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff28 = 12'b111100001000; //sfix12_En11
  parameter signed [11:0] coeff29 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff30 = 12'b111001010101; //sfix12_En11
  parameter signed [11:0] coeff31 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff32 = 12'b101011101011; //sfix12_En11
  parameter signed [11:0] coeff33 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff34 = 12'b010100010101; //sfix12_En11
  parameter signed [11:0] coeff35 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff36 = 12'b000110101011; //sfix12_En11
  parameter signed [11:0] coeff37 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff38 = 12'b000011111000; //sfix12_En11
  parameter signed [11:0] coeff39 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff40 = 12'b000010101000; //sfix12_En11
  parameter signed [11:0] coeff41 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff42 = 12'b000001111010; //sfix12_En11
  parameter signed [11:0] coeff43 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff44 = 12'b000001011100; //sfix12_En11
  parameter signed [11:0] coeff45 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff46 = 12'b000001000110; //sfix12_En11
  parameter signed [11:0] coeff47 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff48 = 12'b000000110110; //sfix12_En11
  parameter signed [11:0] coeff49 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff50 = 12'b000000101001; //sfix12_En11
  parameter signed [11:0] coeff51 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff52 = 12'b000000011111; //sfix12_En11
  parameter signed [11:0] coeff53 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff54 = 12'b000000010111; //sfix12_En11
  parameter signed [11:0] coeff55 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff56 = 12'b000000010001; //sfix12_En11
  parameter signed [11:0] coeff57 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff58 = 12'b000000001100; //sfix12_En11
  parameter signed [11:0] coeff59 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff60 = 12'b000000001000; //sfix12_En11
  parameter signed [11:0] coeff61 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff62 = 12'b000000000101; //sfix12_En11
  parameter signed [11:0] coeff63 = 12'b000000000000; //sfix12_En11
  parameter signed [11:0] coeff64 = 12'b000000000101; //sfix12_En11
  parameter signed [11:0] coeff65 = 12'b000000000000; //sfix12_En11

  // Signals
  reg  signed [11:0] delay_pipeline [0:64] ; // sfix12_En11
  wire signed [22:0] product64; // sfix23_En22
  wire signed [23:0] mul_temp; // sfix24_En22
  wire signed [22:0] product62; // sfix23_En22
  wire signed [23:0] mul_temp_1; // sfix24_En22
  wire signed [22:0] product60; // sfix23_En22
  wire signed [22:0] product58; // sfix23_En22
  wire signed [23:0] mul_temp_2; // sfix24_En22
  wire signed [22:0] product56; // sfix23_En22
  wire signed [23:0] mul_temp_3; // sfix24_En22
  wire signed [22:0] product54; // sfix23_En22
  wire signed [23:0] mul_temp_4; // sfix24_En22
  wire signed [22:0] product52; // sfix23_En22
  wire signed [23:0] mul_temp_5; // sfix24_En22
  wire signed [22:0] product50; // sfix23_En22
  wire signed [23:0] mul_temp_6; // sfix24_En22
  wire signed [22:0] product48; // sfix23_En22
  wire signed [23:0] mul_temp_7; // sfix24_En22
  wire signed [22:0] product46; // sfix23_En22
  wire signed [23:0] mul_temp_8; // sfix24_En22
  wire signed [22:0] product44; // sfix23_En22
  wire signed [23:0] mul_temp_9; // sfix24_En22
  wire signed [22:0] product42; // sfix23_En22
  wire signed [23:0] mul_temp_10; // sfix24_En22
  wire signed [22:0] product40; // sfix23_En22
  wire signed [23:0] mul_temp_11; // sfix24_En22
  wire signed [22:0] product38; // sfix23_En22
  wire signed [23:0] mul_temp_12; // sfix24_En22
  wire signed [22:0] product36; // sfix23_En22
  wire signed [23:0] mul_temp_13; // sfix24_En22
  wire signed [22:0] product34; // sfix23_En22
  wire signed [23:0] mul_temp_14; // sfix24_En22
  wire signed [22:0] product32; // sfix23_En22
  wire signed [23:0] mul_temp_15; // sfix24_En22
  wire signed [22:0] product30; // sfix23_En22
  wire signed [23:0] mul_temp_16; // sfix24_En22
  wire signed [22:0] product28; // sfix23_En22
  wire signed [23:0] mul_temp_17; // sfix24_En22
  wire signed [22:0] product26; // sfix23_En22
  wire signed [23:0] mul_temp_18; // sfix24_En22
  wire signed [22:0] product24; // sfix23_En22
  wire signed [23:0] mul_temp_19; // sfix24_En22
  wire signed [22:0] product22; // sfix23_En22
  wire signed [23:0] mul_temp_20; // sfix24_En22
  wire signed [22:0] product20; // sfix23_En22
  wire signed [23:0] mul_temp_21; // sfix24_En22
  wire signed [22:0] product18; // sfix23_En22
  wire signed [23:0] mul_temp_22; // sfix24_En22
  wire signed [22:0] product16; // sfix23_En22
  wire signed [23:0] mul_temp_23; // sfix24_En22
  wire signed [22:0] product14; // sfix23_En22
  wire signed [23:0] mul_temp_24; // sfix24_En22
  wire signed [22:0] product12; // sfix23_En22
  wire signed [23:0] mul_temp_25; // sfix24_En22
  wire signed [22:0] product10; // sfix23_En22
  wire signed [23:0] mul_temp_26; // sfix24_En22
  wire signed [22:0] product8; // sfix23_En22
  wire signed [23:0] mul_temp_27; // sfix24_En22
  wire signed [22:0] product6; // sfix23_En22
  wire signed [12:0] mulpwr2_temp; // sfix13_En11
  wire signed [22:0] product4; // sfix23_En22
  wire signed [23:0] mul_temp_28; // sfix24_En22
  wire signed [22:0] product2; // sfix23_En22
  wire signed [23:0] mul_temp_29; // sfix24_En22
  wire signed [24:0] sum1; // sfix25_En22
  wire signed [22:0] add_signext; // sfix23_En22
  wire signed [22:0] add_signext_1; // sfix23_En22
  wire signed [23:0] add_temp; // sfix24_En22
  wire signed [24:0] sum2; // sfix25_En22
  wire signed [24:0] add_signext_2; // sfix25_En22
  wire signed [24:0] add_signext_3; // sfix25_En22
  wire signed [25:0] add_temp_1; // sfix26_En22
  wire signed [24:0] sum3; // sfix25_En22
  wire signed [24:0] add_signext_4; // sfix25_En22
  wire signed [24:0] add_signext_5; // sfix25_En22
  wire signed [25:0] add_temp_2; // sfix26_En22
  wire signed [24:0] sum4; // sfix25_En22
  wire signed [24:0] add_signext_6; // sfix25_En22
  wire signed [24:0] add_signext_7; // sfix25_En22
  wire signed [25:0] add_temp_3; // sfix26_En22
  wire signed [24:0] sum5; // sfix25_En22
  wire signed [24:0] add_signext_8; // sfix25_En22
  wire signed [24:0] add_signext_9; // sfix25_En22
  wire signed [25:0] add_temp_4; // sfix26_En22
  wire signed [24:0] sum6; // sfix25_En22
  wire signed [24:0] add_signext_10; // sfix25_En22
  wire signed [24:0] add_signext_11; // sfix25_En22
  wire signed [25:0] add_temp_5; // sfix26_En22
  wire signed [24:0] sum7; // sfix25_En22
  wire signed [24:0] add_signext_12; // sfix25_En22
  wire signed [24:0] add_signext_13; // sfix25_En22
  wire signed [25:0] add_temp_6; // sfix26_En22
  wire signed [24:0] sum8; // sfix25_En22
  wire signed [24:0] add_signext_14; // sfix25_En22
  wire signed [24:0] add_signext_15; // sfix25_En22
  wire signed [25:0] add_temp_7; // sfix26_En22
  wire signed [24:0] sum9; // sfix25_En22
  wire signed [24:0] add_signext_16; // sfix25_En22
  wire signed [24:0] add_signext_17; // sfix25_En22
  wire signed [25:0] add_temp_8; // sfix26_En22
  wire signed [24:0] sum10; // sfix25_En22
  wire signed [24:0] add_signext_18; // sfix25_En22
  wire signed [24:0] add_signext_19; // sfix25_En22
  wire signed [25:0] add_temp_9; // sfix26_En22
  wire signed [24:0] sum11; // sfix25_En22
  wire signed [24:0] add_signext_20; // sfix25_En22
  wire signed [24:0] add_signext_21; // sfix25_En22
  wire signed [25:0] add_temp_10; // sfix26_En22
  wire signed [24:0] sum12; // sfix25_En22
  wire signed [24:0] add_signext_22; // sfix25_En22
  wire signed [24:0] add_signext_23; // sfix25_En22
  wire signed [25:0] add_temp_11; // sfix26_En22
  wire signed [24:0] sum13; // sfix25_En22
  wire signed [24:0] add_signext_24; // sfix25_En22
  wire signed [24:0] add_signext_25; // sfix25_En22
  wire signed [25:0] add_temp_12; // sfix26_En22
  wire signed [24:0] sum14; // sfix25_En22
  wire signed [24:0] add_signext_26; // sfix25_En22
  wire signed [24:0] add_signext_27; // sfix25_En22
  wire signed [25:0] add_temp_13; // sfix26_En22
  wire signed [24:0] sum15; // sfix25_En22
  wire signed [24:0] add_signext_28; // sfix25_En22
  wire signed [24:0] add_signext_29; // sfix25_En22
  wire signed [25:0] add_temp_14; // sfix26_En22
  wire signed [24:0] sum16; // sfix25_En22
  wire signed [24:0] add_signext_30; // sfix25_En22
  wire signed [24:0] add_signext_31; // sfix25_En22
  wire signed [25:0] add_temp_15; // sfix26_En22
  wire signed [24:0] sum17; // sfix25_En22
  wire signed [24:0] add_signext_32; // sfix25_En22
  wire signed [24:0] add_signext_33; // sfix25_En22
  wire signed [25:0] add_temp_16; // sfix26_En22
  wire signed [24:0] sum18; // sfix25_En22
  wire signed [24:0] add_signext_34; // sfix25_En22
  wire signed [24:0] add_signext_35; // sfix25_En22
  wire signed [25:0] add_temp_17; // sfix26_En22
  wire signed [24:0] sum19; // sfix25_En22
  wire signed [24:0] add_signext_36; // sfix25_En22
  wire signed [24:0] add_signext_37; // sfix25_En22
  wire signed [25:0] add_temp_18; // sfix26_En22
  wire signed [24:0] sum20; // sfix25_En22
  wire signed [24:0] add_signext_38; // sfix25_En22
  wire signed [24:0] add_signext_39; // sfix25_En22
  wire signed [25:0] add_temp_19; // sfix26_En22
  wire signed [24:0] sum21; // sfix25_En22
  wire signed [24:0] add_signext_40; // sfix25_En22
  wire signed [24:0] add_signext_41; // sfix25_En22
  wire signed [25:0] add_temp_20; // sfix26_En22
  wire signed [24:0] sum22; // sfix25_En22
  wire signed [24:0] add_signext_42; // sfix25_En22
  wire signed [24:0] add_signext_43; // sfix25_En22
  wire signed [25:0] add_temp_21; // sfix26_En22
  wire signed [24:0] sum23; // sfix25_En22
  wire signed [24:0] add_signext_44; // sfix25_En22
  wire signed [24:0] add_signext_45; // sfix25_En22
  wire signed [25:0] add_temp_22; // sfix26_En22
  wire signed [24:0] sum24; // sfix25_En22
  wire signed [24:0] add_signext_46; // sfix25_En22
  wire signed [24:0] add_signext_47; // sfix25_En22
  wire signed [25:0] add_temp_23; // sfix26_En22
  wire signed [24:0] sum25; // sfix25_En22
  wire signed [24:0] add_signext_48; // sfix25_En22
  wire signed [24:0] add_signext_49; // sfix25_En22
  wire signed [25:0] add_temp_24; // sfix26_En22
  wire signed [24:0] sum26; // sfix25_En22
  wire signed [24:0] add_signext_50; // sfix25_En22
  wire signed [24:0] add_signext_51; // sfix25_En22
  wire signed [25:0] add_temp_25; // sfix26_En22
  wire signed [24:0] sum27; // sfix25_En22
  wire signed [24:0] add_signext_52; // sfix25_En22
  wire signed [24:0] add_signext_53; // sfix25_En22
  wire signed [25:0] add_temp_26; // sfix26_En22
  wire signed [24:0] sum28; // sfix25_En22
  wire signed [24:0] add_signext_54; // sfix25_En22
  wire signed [24:0] add_signext_55; // sfix25_En22
  wire signed [25:0] add_temp_27; // sfix26_En22
  wire signed [24:0] sum29; // sfix25_En22
  wire signed [24:0] add_signext_56; // sfix25_En22
  wire signed [24:0] add_signext_57; // sfix25_En22
  wire signed [25:0] add_temp_28; // sfix26_En22
  wire signed [24:0] sum30; // sfix25_En22
  wire signed [24:0] add_signext_58; // sfix25_En22
  wire signed [24:0] add_signext_59; // sfix25_En22
  wire signed [25:0] add_temp_29; // sfix26_En22
  wire signed [24:0] sum31; // sfix25_En22
  wire signed [24:0] add_signext_60; // sfix25_En22
  wire signed [24:0] add_signext_61; // sfix25_En22
  wire signed [25:0] add_temp_30; // sfix26_En22
  reg  signed [24:0] output_register; // sfix25_En22

  // Block Statements
  always @( posedge clk or posedge reset)
    begin: Delay_Pipeline_process
      if (reset == 1'b1) begin
        delay_pipeline[0] <= 0;
        delay_pipeline[1] <= 0;
        delay_pipeline[2] <= 0;
        delay_pipeline[3] <= 0;
        delay_pipeline[4] <= 0;
        delay_pipeline[5] <= 0;
        delay_pipeline[6] <= 0;
        delay_pipeline[7] <= 0;
        delay_pipeline[8] <= 0;
        delay_pipeline[9] <= 0;
        delay_pipeline[10] <= 0;
        delay_pipeline[11] <= 0;
        delay_pipeline[12] <= 0;
        delay_pipeline[13] <= 0;
        delay_pipeline[14] <= 0;
        delay_pipeline[15] <= 0;
        delay_pipeline[16] <= 0;
        delay_pipeline[17] <= 0;
        delay_pipeline[18] <= 0;
        delay_pipeline[19] <= 0;
        delay_pipeline[20] <= 0;
        delay_pipeline[21] <= 0;
        delay_pipeline[22] <= 0;
        delay_pipeline[23] <= 0;
        delay_pipeline[24] <= 0;
        delay_pipeline[25] <= 0;
        delay_pipeline[26] <= 0;
        delay_pipeline[27] <= 0;
        delay_pipeline[28] <= 0;
        delay_pipeline[29] <= 0;
        delay_pipeline[30] <= 0;
        delay_pipeline[31] <= 0;
        delay_pipeline[32] <= 0;
        delay_pipeline[33] <= 0;
        delay_pipeline[34] <= 0;
        delay_pipeline[35] <= 0;
        delay_pipeline[36] <= 0;
        delay_pipeline[37] <= 0;
        delay_pipeline[38] <= 0;
        delay_pipeline[39] <= 0;
        delay_pipeline[40] <= 0;
        delay_pipeline[41] <= 0;
        delay_pipeline[42] <= 0;
        delay_pipeline[43] <= 0;
        delay_pipeline[44] <= 0;
        delay_pipeline[45] <= 0;
        delay_pipeline[46] <= 0;
        delay_pipeline[47] <= 0;
        delay_pipeline[48] <= 0;
        delay_pipeline[49] <= 0;
        delay_pipeline[50] <= 0;
        delay_pipeline[51] <= 0;
        delay_pipeline[52] <= 0;
        delay_pipeline[53] <= 0;
        delay_pipeline[54] <= 0;
        delay_pipeline[55] <= 0;
        delay_pipeline[56] <= 0;
        delay_pipeline[57] <= 0;
        delay_pipeline[58] <= 0;
        delay_pipeline[59] <= 0;
        delay_pipeline[60] <= 0;
        delay_pipeline[61] <= 0;
        delay_pipeline[62] <= 0;
        delay_pipeline[63] <= 0;
        delay_pipeline[64] <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline[0] <= filter_in;
          delay_pipeline[1] <= delay_pipeline[0];
          delay_pipeline[2] <= delay_pipeline[1];
          delay_pipeline[3] <= delay_pipeline[2];
          delay_pipeline[4] <= delay_pipeline[3];
          delay_pipeline[5] <= delay_pipeline[4];
          delay_pipeline[6] <= delay_pipeline[5];
          delay_pipeline[7] <= delay_pipeline[6];
          delay_pipeline[8] <= delay_pipeline[7];
          delay_pipeline[9] <= delay_pipeline[8];
          delay_pipeline[10] <= delay_pipeline[9];
          delay_pipeline[11] <= delay_pipeline[10];
          delay_pipeline[12] <= delay_pipeline[11];
          delay_pipeline[13] <= delay_pipeline[12];
          delay_pipeline[14] <= delay_pipeline[13];
          delay_pipeline[15] <= delay_pipeline[14];
          delay_pipeline[16] <= delay_pipeline[15];
          delay_pipeline[17] <= delay_pipeline[16];
          delay_pipeline[18] <= delay_pipeline[17];
          delay_pipeline[19] <= delay_pipeline[18];
          delay_pipeline[20] <= delay_pipeline[19];
          delay_pipeline[21] <= delay_pipeline[20];
          delay_pipeline[22] <= delay_pipeline[21];
          delay_pipeline[23] <= delay_pipeline[22];
          delay_pipeline[24] <= delay_pipeline[23];
          delay_pipeline[25] <= delay_pipeline[24];
          delay_pipeline[26] <= delay_pipeline[25];
          delay_pipeline[27] <= delay_pipeline[26];
          delay_pipeline[28] <= delay_pipeline[27];
          delay_pipeline[29] <= delay_pipeline[28];
          delay_pipeline[30] <= delay_pipeline[29];
          delay_pipeline[31] <= delay_pipeline[30];
          delay_pipeline[32] <= delay_pipeline[31];
          delay_pipeline[33] <= delay_pipeline[32];
          delay_pipeline[34] <= delay_pipeline[33];
          delay_pipeline[35] <= delay_pipeline[34];
          delay_pipeline[36] <= delay_pipeline[35];
          delay_pipeline[37] <= delay_pipeline[36];
          delay_pipeline[38] <= delay_pipeline[37];
          delay_pipeline[39] <= delay_pipeline[38];
          delay_pipeline[40] <= delay_pipeline[39];
          delay_pipeline[41] <= delay_pipeline[40];
          delay_pipeline[42] <= delay_pipeline[41];
          delay_pipeline[43] <= delay_pipeline[42];
          delay_pipeline[44] <= delay_pipeline[43];
          delay_pipeline[45] <= delay_pipeline[44];
          delay_pipeline[46] <= delay_pipeline[45];
          delay_pipeline[47] <= delay_pipeline[46];
          delay_pipeline[48] <= delay_pipeline[47];
          delay_pipeline[49] <= delay_pipeline[48];
          delay_pipeline[50] <= delay_pipeline[49];
          delay_pipeline[51] <= delay_pipeline[50];
          delay_pipeline[52] <= delay_pipeline[51];
          delay_pipeline[53] <= delay_pipeline[52];
          delay_pipeline[54] <= delay_pipeline[53];
          delay_pipeline[55] <= delay_pipeline[54];
          delay_pipeline[56] <= delay_pipeline[55];
          delay_pipeline[57] <= delay_pipeline[56];
          delay_pipeline[58] <= delay_pipeline[57];
          delay_pipeline[59] <= delay_pipeline[58];
          delay_pipeline[60] <= delay_pipeline[59];
          delay_pipeline[61] <= delay_pipeline[60];
          delay_pipeline[62] <= delay_pipeline[61];
          delay_pipeline[63] <= delay_pipeline[62];
          delay_pipeline[64] <= delay_pipeline[63];
        end
      end
    end // Delay_Pipeline_process


  assign mul_temp = delay_pipeline[63] * coeff64;
  assign product64 = mul_temp[22:0];

  assign mul_temp_1 = delay_pipeline[61] * coeff62;
  assign product62 = mul_temp_1[22:0];

  assign product60 = $signed({delay_pipeline[59][11:0], 3'b000});

  assign mul_temp_2 = delay_pipeline[57] * coeff58;
  assign product58 = mul_temp_2[22:0];

  assign mul_temp_3 = delay_pipeline[55] * coeff56;
  assign product56 = mul_temp_3[22:0];

  assign mul_temp_4 = delay_pipeline[53] * coeff54;
  assign product54 = mul_temp_4[22:0];

  assign mul_temp_5 = delay_pipeline[51] * coeff52;
  assign product52 = mul_temp_5[22:0];

  assign mul_temp_6 = delay_pipeline[49] * coeff50;
  assign product50 = mul_temp_6[22:0];

  assign mul_temp_7 = delay_pipeline[47] * coeff48;
  assign product48 = mul_temp_7[22:0];

  assign mul_temp_8 = delay_pipeline[45] * coeff46;
  assign product46 = mul_temp_8[22:0];

  assign mul_temp_9 = delay_pipeline[43] * coeff44;
  assign product44 = mul_temp_9[22:0];

  assign mul_temp_10 = delay_pipeline[41] * coeff42;
  assign product42 = mul_temp_10[22:0];

  assign mul_temp_11 = delay_pipeline[39] * coeff40;
  assign product40 = mul_temp_11[22:0];

  assign mul_temp_12 = delay_pipeline[37] * coeff38;
  assign product38 = mul_temp_12[22:0];

  assign mul_temp_13 = delay_pipeline[35] * coeff36;
  assign product36 = mul_temp_13[22:0];

  assign mul_temp_14 = delay_pipeline[33] * coeff34;
  assign product34 = mul_temp_14[22:0];

  assign mul_temp_15 = delay_pipeline[31] * coeff32;
  assign product32 = mul_temp_15[22:0];

  assign mul_temp_16 = delay_pipeline[29] * coeff30;
  assign product30 = mul_temp_16[22:0];

  assign mul_temp_17 = delay_pipeline[27] * coeff28;
  assign product28 = mul_temp_17[22:0];

  assign mul_temp_18 = delay_pipeline[25] * coeff26;
  assign product26 = mul_temp_18[22:0];

  assign mul_temp_19 = delay_pipeline[23] * coeff24;
  assign product24 = mul_temp_19[22:0];

  assign mul_temp_20 = delay_pipeline[21] * coeff22;
  assign product22 = mul_temp_20[22:0];

  assign mul_temp_21 = delay_pipeline[19] * coeff20;
  assign product20 = mul_temp_21[22:0];

  assign mul_temp_22 = delay_pipeline[17] * coeff18;
  assign product18 = mul_temp_22[22:0];

  assign mul_temp_23 = delay_pipeline[15] * coeff16;
  assign product16 = mul_temp_23[22:0];

  assign mul_temp_24 = delay_pipeline[13] * coeff14;
  assign product14 = mul_temp_24[22:0];

  assign mul_temp_25 = delay_pipeline[11] * coeff12;
  assign product12 = mul_temp_25[22:0];

  assign mul_temp_26 = delay_pipeline[9] * coeff10;
  assign product10 = mul_temp_26[22:0];

  assign mul_temp_27 = delay_pipeline[7] * coeff8;
  assign product8 = mul_temp_27[22:0];

  assign mulpwr2_temp = (delay_pipeline[5]==12'b100000000000) ? $signed({1'b0, delay_pipeline[5]}) : -delay_pipeline[5];

  assign product6 = $signed({mulpwr2_temp[12:0], 3'b000});

  assign mul_temp_28 = delay_pipeline[3] * coeff4;
  assign product4 = mul_temp_28[22:0];

  assign mul_temp_29 = delay_pipeline[1] * coeff2;
  assign product2 = mul_temp_29[22:0];

  assign add_signext = product2;
  assign add_signext_1 = product4;
  assign add_temp = add_signext + add_signext_1;
  assign sum1 = $signed({{1{add_temp[23]}}, add_temp});

  assign add_signext_2 = sum1;
  assign add_signext_3 = $signed({{2{product6[22]}}, product6});
  assign add_temp_1 = add_signext_2 + add_signext_3;
  assign sum2 = add_temp_1[24:0];

  assign add_signext_4 = sum2;
  assign add_signext_5 = $signed({{2{product8[22]}}, product8});
  assign add_temp_2 = add_signext_4 + add_signext_5;
  assign sum3 = add_temp_2[24:0];

  assign add_signext_6 = sum3;
  assign add_signext_7 = $signed({{2{product10[22]}}, product10});
  assign add_temp_3 = add_signext_6 + add_signext_7;
  assign sum4 = add_temp_3[24:0];

  assign add_signext_8 = sum4;
  assign add_signext_9 = $signed({{2{product12[22]}}, product12});
  assign add_temp_4 = add_signext_8 + add_signext_9;
  assign sum5 = add_temp_4[24:0];

  assign add_signext_10 = sum5;
  assign add_signext_11 = $signed({{2{product14[22]}}, product14});
  assign add_temp_5 = add_signext_10 + add_signext_11;
  assign sum6 = add_temp_5[24:0];

  assign add_signext_12 = sum6;
  assign add_signext_13 = $signed({{2{product16[22]}}, product16});
  assign add_temp_6 = add_signext_12 + add_signext_13;
  assign sum7 = add_temp_6[24:0];

  assign add_signext_14 = sum7;
  assign add_signext_15 = $signed({{2{product18[22]}}, product18});
  assign add_temp_7 = add_signext_14 + add_signext_15;
  assign sum8 = add_temp_7[24:0];

  assign add_signext_16 = sum8;
  assign add_signext_17 = $signed({{2{product20[22]}}, product20});
  assign add_temp_8 = add_signext_16 + add_signext_17;
  assign sum9 = add_temp_8[24:0];

  assign add_signext_18 = sum9;
  assign add_signext_19 = $signed({{2{product22[22]}}, product22});
  assign add_temp_9 = add_signext_18 + add_signext_19;
  assign sum10 = add_temp_9[24:0];

  assign add_signext_20 = sum10;
  assign add_signext_21 = $signed({{2{product24[22]}}, product24});
  assign add_temp_10 = add_signext_20 + add_signext_21;
  assign sum11 = add_temp_10[24:0];

  assign add_signext_22 = sum11;
  assign add_signext_23 = $signed({{2{product26[22]}}, product26});
  assign add_temp_11 = add_signext_22 + add_signext_23;
  assign sum12 = add_temp_11[24:0];

  assign add_signext_24 = sum12;
  assign add_signext_25 = $signed({{2{product28[22]}}, product28});
  assign add_temp_12 = add_signext_24 + add_signext_25;
  assign sum13 = add_temp_12[24:0];

  assign add_signext_26 = sum13;
  assign add_signext_27 = $signed({{2{product30[22]}}, product30});
  assign add_temp_13 = add_signext_26 + add_signext_27;
  assign sum14 = add_temp_13[24:0];

  assign add_signext_28 = sum14;
  assign add_signext_29 = $signed({{2{product32[22]}}, product32});
  assign add_temp_14 = add_signext_28 + add_signext_29;
  assign sum15 = add_temp_14[24:0];

  assign add_signext_30 = sum15;
  assign add_signext_31 = $signed({{2{product34[22]}}, product34});
  assign add_temp_15 = add_signext_30 + add_signext_31;
  assign sum16 = add_temp_15[24:0];

  assign add_signext_32 = sum16;
  assign add_signext_33 = $signed({{2{product36[22]}}, product36});
  assign add_temp_16 = add_signext_32 + add_signext_33;
  assign sum17 = add_temp_16[24:0];

  assign add_signext_34 = sum17;
  assign add_signext_35 = $signed({{2{product38[22]}}, product38});
  assign add_temp_17 = add_signext_34 + add_signext_35;
  assign sum18 = add_temp_17[24:0];

  assign add_signext_36 = sum18;
  assign add_signext_37 = $signed({{2{product40[22]}}, product40});
  assign add_temp_18 = add_signext_36 + add_signext_37;
  assign sum19 = add_temp_18[24:0];

  assign add_signext_38 = sum19;
  assign add_signext_39 = $signed({{2{product42[22]}}, product42});
  assign add_temp_19 = add_signext_38 + add_signext_39;
  assign sum20 = add_temp_19[24:0];

  assign add_signext_40 = sum20;
  assign add_signext_41 = $signed({{2{product44[22]}}, product44});
  assign add_temp_20 = add_signext_40 + add_signext_41;
  assign sum21 = add_temp_20[24:0];

  assign add_signext_42 = sum21;
  assign add_signext_43 = $signed({{2{product46[22]}}, product46});
  assign add_temp_21 = add_signext_42 + add_signext_43;
  assign sum22 = add_temp_21[24:0];

  assign add_signext_44 = sum22;
  assign add_signext_45 = $signed({{2{product48[22]}}, product48});
  assign add_temp_22 = add_signext_44 + add_signext_45;
  assign sum23 = add_temp_22[24:0];

  assign add_signext_46 = sum23;
  assign add_signext_47 = $signed({{2{product50[22]}}, product50});
  assign add_temp_23 = add_signext_46 + add_signext_47;
  assign sum24 = add_temp_23[24:0];

  assign add_signext_48 = sum24;
  assign add_signext_49 = $signed({{2{product52[22]}}, product52});
  assign add_temp_24 = add_signext_48 + add_signext_49;
  assign sum25 = add_temp_24[24:0];

  assign add_signext_50 = sum25;
  assign add_signext_51 = $signed({{2{product54[22]}}, product54});
  assign add_temp_25 = add_signext_50 + add_signext_51;
  assign sum26 = add_temp_25[24:0];

  assign add_signext_52 = sum26;
  assign add_signext_53 = $signed({{2{product56[22]}}, product56});
  assign add_temp_26 = add_signext_52 + add_signext_53;
  assign sum27 = add_temp_26[24:0];

  assign add_signext_54 = sum27;
  assign add_signext_55 = $signed({{2{product58[22]}}, product58});
  assign add_temp_27 = add_signext_54 + add_signext_55;
  assign sum28 = add_temp_27[24:0];

  assign add_signext_56 = sum28;
  assign add_signext_57 = $signed({{2{product60[22]}}, product60});
  assign add_temp_28 = add_signext_56 + add_signext_57;
  assign sum29 = add_temp_28[24:0];

  assign add_signext_58 = sum29;
  assign add_signext_59 = $signed({{2{product62[22]}}, product62});
  assign add_temp_29 = add_signext_58 + add_signext_59;
  assign sum30 = add_temp_29[24:0];

  assign add_signext_60 = sum30;
  assign add_signext_61 = $signed({{2{product64[22]}}, product64});
  assign add_temp_30 = add_signext_60 + add_signext_61;
  assign sum31 = add_temp_30[24:0];

  always @ (posedge clk or posedge reset)
    begin: Output_Register_process
      if (reset == 1'b1) begin
        output_register <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          output_register <= sum31;
        end
      end
    end // Output_Register_process

  // Assignment Statements
  assign filter_out = output_register;
endmodule  // filter12
