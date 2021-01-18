/* ------------------------------------------------ *
 * Title       : Simple UART interface  v1.0        *
 * Project     : Simple UART                        *
 * ------------------------------------------------ *
 * File        : uart.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 18/01/2021                         *
 * ------------------------------------------------ *
 * Description : UART communication modules         *
 * ------------------------------------------------ */

module uart_dual#(parameter inCLK_PERIOD_ns = 10)(
  input clk,
  input rst,
  //Config signals
  input baseClock_freq, //0: 76,8kHz (13us); 1: 460,8kHz (2,17us)
  input [2:0] divRatio, 
  input data_size, //0: 7bit; 1: 8bit
  input parity_en,
  input [1:0] parity_mode, //11: odd; 10: even, 01: mark(1), 00: space(0)
  input stop_bit_size, //0: 1bit; 1: 2bit
  //Data interface
  input [7:0] data_i,
  output [7:0] data_o,
  output valid,
  output newData,
  output ready_tx,
  output ready_rx,
  input send,
  //UART
  output tx,
  input rx);
  
  uart_rx RxUART(clk, rst, baseClock_freq, divRatio, data_size, parity_en, parity_mode, data_o, valid, ready_rx, new_data, rx,);

  uart_tx TxUART(clk, rst, baseClock_freq, divRatio, data_size, parity_en, parity_mode, stop_bit_size, data_i, ready_tx, send, tx,);
endmodule//uart_dual

module uart_tx#(parameter inCLK_PERIOD_ns = 10)(
  input clk,
  input rst,
  //Config signals
  input baseClock_freq, //0: 76,8kHz (13us); 1: 460,8kHz (2,17us)
  input [2:0] divRatio, 
  input data_size, //0: 7bit; 1: 8bit
  input parity_en,
  input [1:0] parity_mode, //11: odd; 10: even, 01: mark(1), 00: space(0)
  input stop_bit_size, //0: 1bit; 1: 2bit
  //Data interface
  input [7:0] data,
  output ready,
  input send,
  //UART transmit
  output reg tx,
  output uartClock);
  localparam READY = 3'b000,
             START = 3'b001,
              DATA = 3'b011,
            PARITY = 3'b110,
               END = 3'b100;
  reg [2:0] counter;
  reg [2:0] state;
  reg [7:0] data_buff;
  wire in_Ready, in_Start, in_Data, in_Parity, in_End;
  reg en, parity_calc, in_End_d;
  wire countDONE;
  
  //Decode states
  assign in_Ready = (state == READY);
  assign in_Start = (state == START);
  assign in_Data = (state == DATA);
  assign in_Parity = (state == PARITY);
  assign in_End = (state == END);
  assign ready = in_Ready;

  //delay in_End
  always@(posedge clk)
    begin
      in_End_d <= in_End;
    end

  assign countDONE = (in_End & (counter[0] == stop_bit_size)) | (in_Data & (counter == {2'b11, data_size}));

  //Internal enable signal
  always@(posedge clk)
    begin
      if(rst)
        begin
          en <= 1'd0;
        end
      else
        begin
          case(en)
            1'b0:
              begin
                en <= send;
              end
            1'b1:
              begin
                en <= ~in_End_d | in_End; //only high on negative edge
              end
          endcase
        end
    end
  
  //State transactions
  always@(negedge uartClock or posedge rst)
    begin
      if(rst)
        begin
          state <= READY;
        end
      else
        begin
          case(state)
            READY:
              begin
                state <= (en) ? START : state;
              end
            START:
              begin
                state <= DATA;
              end
            DATA:
              begin
                state <= (countDONE) ? ((parity_en) ? PARITY : END) : state;
              end
            PARITY:
              begin
                state <= END;
              end
            END:
              begin
                state <= (countDONE) ? READY : state;
              end
            default:
              begin
                state <= READY;
              end
          endcase
        end
    end
  
  //Counter
  always@(negedge uartClock or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          case(state)
            DATA:
              begin
                counter <= (countDONE) ? 3'd0 : (counter + 3'd1);
              end
            END:
              begin
                counter <= (countDONE) ? 3'd0 : (counter + 3'd1);
              end
            default:
              begin
                counter <= 3'd0;
              end
          endcase
          
        end
    end
  
  //handle data_buff
  always@(negedge uartClock)
    begin
      case(state)
        START:
          begin
            data_buff <= data;
          end
        DATA:
          begin
            data_buff <= (data_buff >> 1);
          end
        default:
          begin
            data_buff <= data_buff;
          end
      endcase
    end
  
  //tx routing
  always@*
    begin
      case(state)
        START:
          begin
            tx = 1'b0;
          end
        DATA:
          begin
            tx = data_buff[0];
          end
        PARITY:
          begin
            tx = parity_calc;
          end
        default:
          begin
            tx = 1'b1;
          end
      endcase
      
    end
  
  //Parity calc
  always@(posedge uartClock)
    begin
      if(in_Start) //reset
        begin
          parity_calc <= parity_mode[0];
        end
      else
        begin
          parity_calc <= (in_Data) ? (parity_calc ^ (tx & parity_mode[1])) : parity_calc;
        end
    end
  
  baudRGen #(inCLK_PERIOD_ns) clk_gen(clk, rst, baseClock_freq,  divRatio, (en & (~in_End_d | in_End)), uartClock);
endmodule//uart_tx

module uart_rx#(parameter inCLK_PERIOD_ns = 10)(
  input clk,
  input rst,
  //Config signals
  input baseClock_freq, //0: 76,8kHz (13us); 1: 460,8kHz (2,17us)
  input [2:0] divRatio,
  input data_size, //0: 7bit; 1: 8bit
  input parity_en,
  input [1:0] parity_mode, //11: odd; 10: even, 01: mark(1), 00: space(0)
  //Data interface
  output reg [7:0] data,
  output reg valid,
  output ready,
  output newData,
  //UART receive
  input rx,
  output uartClock);
  localparam READY = 3'b000,
             START = 3'b001,
              DATA = 3'b011,
            PARITY = 3'b110,
               END = 3'b100;
  reg [2:0] counter; 
  reg [2:0] state;
  reg [7:0] data_buff;
  wire in_Ready, in_Start, in_Data, in_Parity, in_End;
  reg parity_calc, in_End_d, en;
  //Decode states
  assign in_Ready = (state == READY);
  assign in_Start = (state == START);
  assign in_Data = (state == DATA);
  assign in_Parity = (state == PARITY);
  assign in_End = (state == END);
  assign ready = in_Ready;

  assign newData = ~in_End & in_End_d; //New data add negedge of in_End
  assign countDONE = in_Data & (counter == {2'b11, data_size});

  //internal enable
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          en <= 1'b0;
        end
      else
        begin
          case(en)
            1'b0:
              begin
                en <= (rx) ? en : 1'b1;
              end
            1'b1:
              begin
                en <= ~in_End_d | in_End;
              end
          endcase
          
        end
    end
  

  //Counter
  always@(negedge uartClock or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          case(state)
            DATA:
              begin
                counter <= (countDONE) ? 3'd0 : (counter + 3'd1);
              end
            default:
              begin
                counter <= 3'd0;
              end
          endcase
        end
    end
  
  //State transactions
  always@(negedge uartClock or posedge rst)
    begin
      if(rst)
        begin
          state <= READY;
        end
      else
        begin
          case(state)
            READY:
              begin
                state <= (en) ? START : state;
              end
            START:
              begin
                state <= DATA;
              end
            DATA:
              begin
                state <= (countDONE) ? ((parity_en) ? PARITY : END) : state;
              end
            PARITY:
              begin
                state <= END;
              end
            END:
              begin
                state <= READY;
              end
            default:
              begin
                state <= READY;
              end
          endcase
        end
    end

  //delay in_End
  always@(posedge clk)
    begin
      in_End_d <= in_End;
    end

  //Store received data
  always@(posedge clk)
    begin
      if(in_End)
        data <= data_buff;
    end
  
  //Handle data_buff
  always@(posedge uartClock)
    begin
      case(state)
        START:
          begin //clear buffer
            data_buff <= 8'd0;
          end
        DATA:
          begin //Shift in new data from MS
            data_buff <= {rx, data_buff[7:1]};
          end
        END:
          begin //Shift one more 7bit data mode
            data_buff <= (data_size) ? data_buff : (data_buff >> 1);
          end
        default:
          begin
            data_buff <= data_buff;
          end
      endcase
      
    end
  
  //Parity check
  always@(posedge clk)
    begin
      if(rst)
        begin
          valid <= 1'b0;
        end
      else
        begin
          valid <= (in_Parity) ? (rx == parity_calc) : valid;
        end
    end
  
  //Parity calc
  always@(posedge uartClock)
    begin
      if(in_Start) //reset
        begin
          parity_calc <= parity_mode[0];
        end
      else
        begin
          parity_calc <= (in_Data) ? (parity_calc ^ (rx & parity_mode[1])) : parity_calc;
        end
    end
  
  baudRGen #(inCLK_PERIOD_ns) clk_gen(clk, rst, baseClock_freq,  divRatio, (en & (~in_End_d | in_End)), uartClock);
endmodule//uart_tx

//Generate a clock freqency for various baudrates, just clock divider 
module baudRGen#(parameter inCLK_PERIOD_ns = 10)(
  input clk,
  input rst,
  input baseClock_freq, //0: 76,8kHz (13us) 1: 460,8kHz (2,17us)
  input [2:0] divRatio, //Higher the value lower the freq
  input en,
  output uartClock);

  localparam sec6_5u = (6500 / inCLK_PERIOD_ns) - 1;
  localparam sec1_08u = (1080 / inCLK_PERIOD_ns) - 1;
  localparam counterWIDTH = $clog2(sec6_5u);
  localparam CLKRST = 1'b0;
  localparam CLKDEF = 1'b1;

  wire en_rst;

  reg baseClock;
  wire countDONE;

  reg [(counterWIDTH-1):0] counter;
  wire [(counterWIDTH-1):0] countTO;

  wire [7:0] clockArray;
  reg [6:0] divClock;

  assign en_rst = en | rst;

  assign countTO = (baseClock_freq) ? sec1_08u : sec6_5u;
  assign countDONE = (countTO == counter);

  assign clockArray = {divClock, baseClock};
  assign uartClock = (en) ? clockArray[divRatio] : CLKDEF;

  //Counter
  always@(posedge clk)
    begin
      if(~en)
        counter <= 0;
      else
        counter <= (countDONE) ? 0 : (counter +  1);
    end
  
  //Generate base clock with counter
  always@(posedge clk)
    begin
      if(~en)
        baseClock <= CLKRST;
      else
        baseClock <= (countDONE) ? ~baseClock : baseClock;
    end
  
  //Clock dividers
  // 1/2
  always@(posedge baseClock or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[0] <= CLKRST;
        end
      else
        begin
          divClock[0] <= ~divClock[0];
        end
    end
  // 1/4
  always@(posedge divClock[0] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[1] <= CLKRST;
        end
      else
        begin
          divClock[1] <= ~divClock[1];
        end
    end
  // 1/8
  always@(posedge divClock[1] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[2] <= CLKRST;
        end
      else
        begin
          divClock[2] <= ~divClock[2];
        end
    end
  // 1/16
  always@(posedge divClock[2] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[3] <= CLKRST;
        end
      else
        begin
          divClock[3] <= ~divClock[3];
        end
    end
  // 1/32
  always@(posedge divClock[3] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[4] <= CLKRST;
        end
      else
        begin
          divClock[4] <= ~divClock[4];
        end
    end
  // 1/64
  always@(posedge divClock[4] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[5] <= CLKRST;
        end
      else
        begin
          divClock[5] <= ~divClock[5];
        end
    end
  // 1/128
  always@(posedge divClock[5] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[6] <= CLKRST;
        end
      else
        begin
          divClock[6] <= ~divClock[6];
        end
    end
endmodule

//Generate a clock freqency for non standard higher frequencies
module baudRGen_HS(
  input clk,
  input rst,
  input [1:0] divRatio, //Higher the value lower the freq
  input en,
  output uartClock);

  localparam CLKRST = 1'b0;
  localparam CLKDEF = 1'b1;

  wire en_rst;

  reg baseClock;

  reg [3:0] divClock;

  assign en_rst = en | rst;

  assign uartClock = (en) ? divClock[divRatio] : CLKDEF;

  //Generate base clock with counter
  always@(posedge clk)
    begin
      if(~en)
        baseClock <= CLKRST;
      else
        baseClock <= ~baseClock;
    end

  //Clock dividers
  // 1/2
  always@(posedge baseClock or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[0] <= CLKRST;
        end
      else
        begin
          divClock[0] <= ~divClock[0];
        end
    end
  // 1/4
  always@(posedge divClock[0] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[1] <= CLKRST;
        end
      else
        begin
          divClock[1] <= ~divClock[1];
        end
    end
  // 1/8
  always@(posedge divClock[1] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[2] <= CLKRST;
        end
      else
        begin
          divClock[2] <= ~divClock[2];
        end
    end
  // 1/16
  always@(posedge divClock[2] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[3] <= CLKRST;
        end
      else
        begin
          divClock[3] <= ~divClock[3];
        end
    end
endmodule
