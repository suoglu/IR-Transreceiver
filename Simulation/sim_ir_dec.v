/* ------------------------------------------------ *
 * Title       : Simulation for IR decoder          *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : sim_ir_dec.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 18/01/2021                         *
 * ------------------------------------------------ *
 * Description : Decoder module for a IR receivers  *
 * ------------------------------------------------ */

//`include "Sources/ir_decoder.v"

module ir_dec_tb();
  reg clk, rst, rx;
  wire clk_100kHz, repeat_press, newCode;
  wire [31:0] code;

  clkGen97k656hz uut_clk(clk, rst, clk_100kHz);
  ir_decoder uut(clk, clk_100kHz,  rst, rx, code, repeat_press, newCode);

  always #5 clk = ~clk;

  /*
    Delays:
    1µs: #1000
    400µs: #400000
    650µs: #650000
    1.65ms: #1650000
    2.5ms: #2500000
    4ms: #4000000
    Data:
    0:
      //0
      rx = 0;
      #400000
      rx = 1;
      #650000
    1:
      //1
      rx = 0;
      #400000
      rx = 1;
      #1650000
  */
  initial
    begin
      clk = 0;
      rst = 0;
      rx = 1;
      #12
      rst = 1;
      #10
      rst = 0;
      //Start cond.
      #10000000
      rx = 0;
      #4000000
      rx = 1;
      #3000000
      //data start here
      //0x0
      //0 ~ 0
      rx = 0;
      #400000
      rx = 1;
      #650000
      //0 ~ 1
      rx = 0;
      #400000
      rx = 1;
      #650000
      //0 ~ 2
      rx = 0;
      #400000
      rx = 1;
      #650000
      //0 ~ 3
      rx = 0;
      #400000
      rx = 1;
      #650000
      //0xF
      //1 ~ 4
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //1 ~ 5
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //1 ~ 6
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //1 ~ 7
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //0xA
      //1 ~ 8
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //0 ~ 9
      rx = 0;
      #400000
      rx = 1;
      #650000
      //1 ~ 10
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //0 ~ 11
      rx = 0;
      #400000
      rx = 1;
      #650000
      //0xA
      //1 ~ 012
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //0 ~ 13
      rx = 0;
      #400000
      rx = 1;
      #650000
      //1 ~ 14
      rx = 0;
      #400000
      rx = 1;
      #1650000
      //0 ~ 15
      rx = 0;
      #400000
      rx = 1;
      #650000
      //Send end con
      rx = 0;
      #400000
      rx = 1;
      #10000000
      $finish;
    end
endmodule//ir_dec_tb
