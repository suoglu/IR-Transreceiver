/* ------------------------------------------------ *
 * Title       : Testboard for IR Decoder           *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : ir_decoder_test.v                  *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 18/01/2021                         *
 * ------------------------------------------------ *
 * Description : Test for IR Decoder module         *
 * ------------------------------------------------ */

// `include "Test/ssd_util.v"
// `include "Test/uart.v"
// `include "Sources/ir_decoder.v"

module irdec_test(
  input clk,
  input rst,
  input ssd_highbits, //SW15
  //Uart interface
  output uart_tx, //JC2
  //IR interface
  input ir_rx, //JC10
  //SSD interface
  output [6:0] seg,
  output [3:0] an,
  output dp,
  output clk_100kHz);
  //UART signals
  reg [7:0] uart_in;
  wire uart_ready;
  reg uart_ready_d;
  reg UARTactive;
  reg UARTkeep;
  reg [1:0] UARTcounter;
  wire UARTsend;
  //IR signals
  wire [31:0] code;
  wire repeat_press, newCode;
  wire [15:0] ssdIn;
  wire [3:0] digit3, digit2, digit1, digit0;

  ir_decoder uut(clk, clk_100kHz, rst, ir_rx, code, repeat_press, newCode);
  clkGen97k656hz uut_clk(clk, rst, clk_100kHz);

  //SSD
  assign dp = ~repeat_press;
  assign ssdIn = (ssd_highbits) ? code[31:16] : code[15:0];
  assign {digit3, digit2, digit1, digit0} = ssdIn;
  ssdController4 ssdCnrt(clk, rst, 4'b1111, digit3, digit2, digit1, digit0, seg, an);
  //UART Mode: 8N1
  uart_tx uartTransmitter(clk, rst, 1'b1, 3'd0, 1'b1, 1'b0, 2'b00, 1'b0, uart_in, uart_ready, uart_send, uart_tx,);
  assign uart_send = UARTkeep | UARTactive;
  always@(posedge clk)
    begin
      uart_ready_d <= uart_ready;
    end
  always@*
    begin
      case(UARTcounter)
        2'd0:
          begin
            uart_in = code[31:24];
          end
        2'd1:
          begin
            uart_in = code[23:16];
          end
        2'd2:
          begin
            uart_in = code[15:8];
          end
        2'd3:
          begin
            uart_in = code[7:0];
          end
      endcase
      
    end
  always@(negedge uart_ready_d or posedge rst)
    begin
      if(rst)
        begin
          UARTcounter <= 2'd0;
        end
      else
        begin
          UARTcounter <= 2'd1 + UARTcounter;
        end
    end
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          UARTkeep <= 1'd0;
        end
      else
        begin
          case(UARTkeep)
            1'd0:
              begin
                UARTkeep <= newCode;
              end
            1'd1:
              begin
                UARTkeep <= (UARTcounter != 2'd2);
              end
          endcase
        end
    end
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          UARTactive <= 1'd0;
        end
      else
        begin
          case(UARTactive)
            1'd0:
              begin
                UARTactive <= UARTkeep;
              end
            1'd1:
              begin
                UARTactive <= UARTkeep | (UARTcounter != 2'd0);
              end
          endcase
        end
    end
  
endmodule