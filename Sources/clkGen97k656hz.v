/* ------------------------------------------------ *
 * Title       : 97,656 khz Clock Generator         *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : clkGen97k656hz.v                   *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 19/09/2021                         *
 * ------------------------------------------------ *
 * Description : Divides 100MHz clock to 97,656 khz *
 *               via logic                          *
 * ------------------------------------------------ */


module clkGen97k656hz(
  input clk_i,
  input rst,
  output reg clk_o);
  reg [8:0] clk_a;

  //50MHz
  always@(posedge clk_i or posedge rst) begin
    if(rst) begin
      clk_a[0] <= 1'b0;
    end  else begin
      clk_a[0] <= ~clk_a[0];
    end
  end
  //25MHz
  always@(posedge clk_a[0] or posedge rst) begin
    if(rst) begin
      clk_a[1] <= 1'b0;
    end  else begin
      clk_a[1] <= ~clk_a[1];
    end
  end
  //12.5MHz
  always@(posedge clk_a[1] or posedge rst) begin
    if(rst) begin
      clk_a[2] <= 1'b0;
    end  else begin
      clk_a[2] <= ~clk_a[2];
    end
  end
  //6.25MHz
  always@(posedge clk_a[2] or posedge rst) begin
    if(rst) begin
      clk_a[3] <= 1'b0;
    end  else begin
      clk_a[3] <= ~clk_a[3];
    end
  end
  //3.125MHz
  always@(posedge clk_a[3] or posedge rst) begin
    if(rst) begin
      clk_a[4] <= 1'b0;
    end  else begin
      clk_a[4] <= ~clk_a[4];
    end
  end
  //1.5625MHz
  always@(posedge clk_a[4] or posedge rst) begin
    if(rst) begin
      clk_a[5] <= 1'b0;
    end  else begin
      clk_a[5] <= ~clk_a[5];
    end
  end
  //781.25kHz
  always@(posedge clk_a[5] or posedge rst) begin
    if(rst) begin
      clk_a[6] <= 1'b0;
    end  else begin
      clk_a[6] <= ~clk_a[6];
    end
  end
  //390.625kHz
  always@(posedge clk_a[6] or posedge rst) begin
    if(rst) begin
      clk_a[7] <= 1'b0;
    end  else begin
      clk_a[7] <= ~clk_a[7];
    end
  end
  //195.312kHz
  always@(posedge clk_a[7] or posedge rst) begin
    if(rst) begin
      clk_a[8] <= 1'b0;
    end  else begin
      clk_a[8] <= ~clk_a[8];
    end
  end
  //97.656kHz
  always@(posedge clk_a[8] or posedge rst) begin
    if(rst) begin
      clk_o <= 1'b0;
    end  else begin
      clk_o <= ~clk_o;
    end
  end
endmodule//clkGen
