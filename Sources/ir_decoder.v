/* ------------------------------------------------ *
 * Title       : IR Decoder v1.1                    *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : ir_decoder.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 19/09/2021                         *
 * ------------------------------------------------ *
 * Description : Decoder module for a IR receivers  *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 *     v1.1    : Reformat & mv clk div to new file  *
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
  always@(posedge clk or posedge rst) begin
    rx_d <= rx;
    if(rst) begin
      state <= IDLE;
    end else case(state)
          IDLE: state <= (~rx) ? START : state;
         START: state <= (rx_d & ~rx) ? DECODING : state;
      DECODING: state <= (finCOND) ? FINISH : state;
         INISH: state <= IDLE;
    endcase
  end
  
  //Count received edges
  always@(posedge rx) begin
    if(inSTART) begin
        edgeCount <= 3'd0;
    end else begin
        edgeCount <= edgeCount + {2'd0, inDECODING & ~&edgeCount};
    end
  end
   
  //Rx derivative signals
  assign bitVAL = (rx_counter > 8'd99);
  assign finCOND = (rx_counter > 8'd199);
  assign repeatCOND = ~&edgeCount;

  //Count rx pulse leghts
  //0-99: O; 100-199: 1; 200<: end condition
  always@(posedge clk_100kHz) begin
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
  always@(negedge rx or posedge inSTART) begin
    if(inSTART)
      codeBUFF <= {CODEBITS{1'b0}};
    else
      codeBUFF <= (inDECODING) ? {codeBUFF[(CODEBITS-2):0], bitVAL} : {CODEBITS{1'b0}};
  end
endmodule
