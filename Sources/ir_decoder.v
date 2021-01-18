/* ------------------------------------------------ *
 * Title       : IR Decoder v1.0                    *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : ir_decoder.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 17/01/2021                         *
 * ------------------------------------------------ *
 * Description : Decoder module for a IR receivers  *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module ir_decoder#(parameter CODEBITS = 32)(
  input clk,
  input clk_100kHz, //10us
  input rst,
  input rx,
  output reg [(CODEBITS-1):0] code,
  output reg repeat_press,
  output newCode);
  localparam IDLE = 2'b00,
            START = 2'b01,
         DECODING = 2'b11,
           FINISH = 2'b10;
  reg [1:0] state;
  reg rx_d;
  wire /*inIDLE,*/ inSTART, inDECODING, inFINISH;
  reg [(CODEBITS-1):0] codeBUFF;
  reg [2:0] edgeCount;
  reg [7:0] rx_counter;
  wire bitVAL;
  wire finCOND;
  wire repeatCOND;

  //Decode states
  //assign inIDLE = (state == IDLE);
  assign inSTART = (state == START);
  assign inDECODING = (state == DECODING);
  assign inFINISH = (state == FINISH);
  assign newCode = inFINISH;

  //State transactions
  always@(posedge clk or posedge rst)
    begin
      rx_d <= rx;
      if(rst)
        begin
          state <= IDLE;
        end
      else
        begin
          case(state)
            IDLE:
              begin
                state <= (~rx) ? START : state;
              end
            START:
              begin
                state <= (rx_d & ~rx) ? DECODING : state;
              end
            DECODING:
              begin
                state <= (finCOND) ? FINISH : state;
              end
            FINISH:
              begin
                state <= IDLE;
              end
          endcase
        end
    end
  
  //Count received edges
  always@(posedge rx)
    begin
      if(inSTART)
        begin
          edgeCount <= 3'd0;
        end
      else
        begin
          edgeCount <= edgeCount + {2'd0, inDECODING & ~&edgeCount};
        end
    end
   
  //Rx derivative signals
  assign bitVAL = (rx_counter > 8'd99);
  assign finCOND = (rx_counter > 8'd199);
  assign repeatCOND = ~&edgeCount;

  //Count rx pulse leghts
  //0-99: O; 100-199: 1; 200<: end condition
  always@(posedge clk_100kHz)
    begin
      if(~rx)
        rx_counter <= 8'd0;
      else
        rx_counter <= rx_counter + {7'd0,(~&rx_counter & inDECODING & rx)};
    end

  //Store codeBUFF and repeat cond to output
  always@(posedge inFINISH)
    begin
      code <= (repeatCOND) ? code : codeBUFF;
      repeat_press <= repeatCOND;
    end
  
  //Get code
  always@(negedge rx or posedge inSTART)
    begin
      if(inSTART)
        begin
          codeBUFF <= {CODEBITS{1'b0}};
        end
      else
        begin //Also add reset here?
          codeBUFF <= (inDECODING) ? {codeBUFF[(CODEBITS-2):0], bitVAL} : {CODEBITS{1'b0}};
        end
    end
endmodule

module clkGen97k656hz(
  input clk_i,
  input rst,
  output reg clk_o);
  reg [8:0] clk_a;

  //50MHz
  always@(posedge clk_i or posedge rst)
    begin
      if(rst)
        begin
          clk_a[0] <= 1'b0;
        end
      else
        begin
          clk_a[0] <= ~clk_a[0];
        end
    end
  //25MHz
  always@(posedge clk_a[0] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[1] <= 1'b0;
        end
      else
        begin
          clk_a[1] <= ~clk_a[1];
        end
    end
  //12.5MHz
  always@(posedge clk_a[1] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[2] <= 1'b0;
        end
      else
        begin
          clk_a[2] <= ~clk_a[2];
        end
    end
  //6.25MHz
  always@(posedge clk_a[2] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[3] <= 1'b0;
        end
      else
        begin
          clk_a[3] <= ~clk_a[3];
        end
    end
  //3.125MHz
  always@(posedge clk_a[3] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[4] <= 1'b0;
        end
      else
        begin
          clk_a[4] <= ~clk_a[4];
        end
    end
  //1.5625MHz
  always@(posedge clk_a[4] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[5] <= 1'b0;
        end
      else
        begin
          clk_a[5] <= ~clk_a[5];
        end
    end
  //781.25kHz
  always@(posedge clk_a[5] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[6] <= 1'b0;
        end
      else
        begin
          clk_a[6] <= ~clk_a[6];
        end
    end
  //390.625kHz
  always@(posedge clk_a[6] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[7] <= 1'b0;
        end
      else
        begin
          clk_a[7] <= ~clk_a[7];
        end
    end
  //195.312kHz
  always@(posedge clk_a[7] or posedge rst)
    begin
      if(rst)
        begin
          clk_a[8] <= 1'b0;
        end
      else
        begin
          clk_a[8] <= ~clk_a[8];
        end
    end
  //97.656kHz
  always@(posedge clk_a[8] or posedge rst)
    begin
      if(rst)
        begin
          clk_o <= 1'b0;
        end
      else
        begin
          clk_o <= ~clk_o;
        end
    end
endmodule//clkGen