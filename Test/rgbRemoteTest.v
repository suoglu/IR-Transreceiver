/* ------------------------------------------------ *
 * Title       : Testboard for RGB Remote           *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : rgbRemoteTest.v                    *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 20/01/2021                         *
 * ------------------------------------------------ *
 * Description : Test for RGB Remote module         *
 * ------------------------------------------------ */

// `include "Sources/rgbLEDremote.v"
// `include "Sources/ir_decoder.v"

module rgb_test(
  input clk,
  input nrst,
  input an,
  output red,
  output green,
  output blue,
  input IRrx,
  output [3:0] led,
  input ledCntr);
  wire [4:0] button;
  wire  [31:0] code;
  wire rst;
  wire newCode, valid;
  wire clk_100kHz;
  assign rst = ~nrst;
  assign led = 0;
  clkGen97k656hz countClockGen(clk, rst, clk_100kHz);
  ir_decoder decoder(clk, clk_100kHz, rst, IRrx, code, , newCode);
  RGBremoteController uut(clk,rst, code, newCode, red, green, blue, an);
endmodule