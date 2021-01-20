/* ------------------------------------------------ *
 * Title       : Remote RGB LED controller v1.0     *
 * Project     : IR Transreceiver                   *
 * ------------------------------------------------ *
 * File        : rgbLEDremote.v                     *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : /01/2021                         *
 * ------------------------------------------------ *
 * Description : Remote controler for a RGB LED     *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module RGBremoteController(
  input clk,
  input rst,
  input [31:0] code,
  input newCode,
  output red_o,
  output green_o,
  output blue_o,
  input an);
  //Color codes for buttons
  localparam WHITE = 24'hFFFFFF,
               RED = 24'hFF0000,
             GREEN = 24'h00FF00,
              BLUE = 24'h0000FF,
              RED1 = 24'hFF4000,
            GREEN1 = 24'h99FF99,
             BLUE1 = 24'hB3CCFF,
              RED2 = 24'hFF5500,
            GREEN2 = 24'h00CCAA,
             BLUE2 = 24'hFFE6FB,
              RED3 = 24'hFF8000,
            GREEN3 = 24'h4DC3FF,
             BLUE3 = 24'hFF80BF,
              RED4 = 24'hFFD500,
            GREEN4 = 24'h0066CC,
             BLUE4 = 24'hFF3399;
  localparam COLOR = 2'd0,
             FLASH = 2'd1,
            STROBE = 2'd2,
            SMOOTH = 2'd3;
  reg [1:0] mode;
  reg lightOn;
  reg [3:0] colorCounter;
  reg [7:0] red_store, blue_store, green_store;
  reg [7:0] red_val, green_val, blue_val;
  reg [7:0] red_dynamic, green_dynamic, blue_dynamic;
  wire sync;
  wire [4:0] button;
  reg [2:0] brightness;
  wire red_c, green_c, blue_c, r_o, g_o, b_o;
  wire pulse, pulseEn;
  reg strobeOn;

  always@*
    begin
      if(~strobeOn & (mode == STROBE))
        {red_dynamic, green_dynamic, blue_dynamic} = 24'h0;
      else
        case(colorCounter)
          4'd0: {red_dynamic, green_dynamic, blue_dynamic} = RED;
          4'd1: {red_dynamic, green_dynamic, blue_dynamic} = RED1;
          4'd2: {red_dynamic, green_dynamic, blue_dynamic} = RED2;
          4'd3: {red_dynamic, green_dynamic, blue_dynamic} = RED3;
          4'd4: {red_dynamic, green_dynamic, blue_dynamic} = RED4;
          4'd5: {red_dynamic, green_dynamic, blue_dynamic} = GREEN;
          4'd6: {red_dynamic, green_dynamic, blue_dynamic} = GREEN1;
          4'd7: {red_dynamic, green_dynamic, blue_dynamic} = GREEN2;
          4'd8: {red_dynamic, green_dynamic, blue_dynamic} = GREEN3;
          4'd9: {red_dynamic, green_dynamic, blue_dynamic} = GREEN4;
          4'd10: {red_dynamic, green_dynamic, blue_dynamic} = BLUE;
          4'd11: {red_dynamic, green_dynamic, blue_dynamic} = BLUE1;
          4'd12: {red_dynamic, green_dynamic, blue_dynamic} = BLUE2;
          4'd13: {red_dynamic, green_dynamic, blue_dynamic} = BLUE3;
          4'd14: {red_dynamic, green_dynamic, blue_dynamic} = BLUE4;
          default: {red_dynamic, green_dynamic, blue_dynamic} = 24'h0;
        endcase
        
    end
  
  //Color counter
  always@(negedge pulse or posedge rst)
    begin
      if(rst)
        begin
          colorCounter <= 4'd0;
        end
      else
        begin
          if((mode == FLASH) | (~strobeOn & (mode == STROBE)))
            colorCounter <= (colorCounter == 4'd14) ? 4'd0 : (colorCounter + 4'd1);
        end
    end
  
  //strobeOff
  always@(negedge pulse or posedge rst)
    begin
      if(rst)
        begin
          strobeOn <= 8'd1;
        end
      else
        begin
          strobeOn <= strobeOn ^ (mode == STROBE);
        end
    end
  
  //Update color regs
  always@(negedge newCode or posedge rst)
    begin
      if(rst)
        begin
          {red_store, blue_store, green_store} <= WHITE;
        end
      else
        begin
          case(button)
            5'd4:
              begin
                {red_store, blue_store, green_store} <= RED;
              end
            5'd5:
              begin
                {red_store, blue_store, green_store} <= GREEN;
              end
            5'd6:
              begin
                {red_store, blue_store, green_store} <= BLUE;
              end
            5'd7:
              begin
                {red_store, blue_store, green_store} <= WHITE;
              end
            5'd8:
              begin
                {red_store, blue_store, green_store} <= RED1;
              end
            5'd9:
              begin
                {red_store, blue_store, green_store} <= GREEN1;
              end
            5'd10:
              begin
                {red_store, blue_store, green_store} <= BLUE1;
              end
            5'd12:
              begin
                {red_store, blue_store, green_store} <= RED2;
              end
            5'd13:
              begin
                {red_store, blue_store, green_store} <= GREEN2;
              end
            5'd14:
              begin
                {red_store, blue_store, green_store} <= BLUE2;
              end
            5'd16:
              begin
                {red_store, blue_store, green_store} <= RED3;
              end
            5'd17:
              begin
                {red_store, blue_store, green_store} <= GREEN3;
              end
            5'd18:
              begin
                {red_store, blue_store, green_store} <= BLUE3;
              end
            5'd20:
              begin
                {red_store, blue_store, green_store} <= RED4;
              end
            5'd21:
              begin
                {red_store, blue_store, green_store} <= GREEN4;
              end
            5'd22:
              begin
                {red_store, blue_store, green_store} <= BLUE4;
              end
          endcase
          
        end
    end

  //Handle mode
  always@(negedge newCode or posedge rst)
    begin
      if(rst)
        begin
          mode <= 2'd0;
        end
      else
        begin
          if(~&button & lightOn & (5'd3 < button))
            begin
              if(button == 5'd23)
                mode <= mode + 2'd1;
              else
                case(button)
                  5'd11:
                    begin
                      mode <= FLASH;
                    end
                  5'd15:
                    begin
                      mode <= STROBE;
                    end
                  5'd19:
                    begin
                      mode <= SMOOTH;
                    end
                  default:
                    begin
                      mode <= COLOR;
                    end
                endcase
            end
        end
    end
  
  //handle brightness
  always@(negedge newCode or posedge rst)
    begin
      if(rst)
        begin
          brightness <= 3'd5;
        end
      else
        begin
          if(~|button)
            begin
              brightness <= brightness + {2'd0,~&brightness};
            end
          else if(button == 5'd1)
            begin
              brightness <= brightness - {2'd0, |brightness};
            end
        end
    end
  
  //Handle lightOn
  always@(negedge newCode or posedge rst)
    begin
      if(rst)
        begin
          lightOn <= 1'b1;
        end
      else
        case(lightOn)
          1'b1: lightOn <= (button == 5'd2) ? 1'b0 : lightOn;
          1'b0: lightOn <= (button == 5'd3) ? 1'b1 : lightOn;
        endcase
    end
  
  //Mode handle & power off
  assign {red_o, green_o, blue_o} = {(r_o & lightOn), (g_o & lightOn), (b_o & lightOn)};
  always@* //Route color data to pwm
    begin
      case(mode)
        COLOR: {red_val, green_val, blue_val} = {red_store, blue_store, green_store};
        SMOOTH: {red_val, green_val, blue_val} = 24'd0; //Not implemented
        default: {red_val, green_val, blue_val} = {red_dynamic, green_dynamic, blue_dynamic};
      endcase
    end

  assign pulseEn = (mode == FLASH) | (mode == STROBE);

  RGBremoteMapper codeDecoder(code, , button);
  brightnessControllerRGB brgt_pwm(sync, rst, {red_c, green_c, blue_c}, {r_o, g_o, b_o}, brightness, an);
  rgb_led_controller8 color_pwm(clk, rst, red_val, green_val, blue_val, sync, , red_c, green_c, blue_c, an);
  pulseGen pulseGenerator(clk, rst, pulseEn, pulse);
endmodule

module RGBremoteMapper(
  input [31:0] code,
  output valid,
  output reg [4:0] button);
  wire [15:0] controlCode, btnCode;
  //Button codes, in array format
  localparam  REMOTECode = 16'h00FF,
                 btn_0_0 = 16'h00FF,
                 btn_0_1 = 16'h40BF,
                 btn_0_2 = 16'h609F,
                 btn_0_3 = 16'hE01F,
                 btn_1_0 = 16'h10EF,
                 btn_1_1 = 16'h906F,
                 btn_1_2 = 16'h50AF,
                 btn_1_3 = 16'hC03F,
                 btn_2_0 = 16'h30CF,
                 btn_2_1 = 16'hB04F,
                 btn_2_2 = 16'h708F,
                 btn_2_3 = 16'hF00F,
                 btn_3_0 = 16'h08F7,
                 btn_3_1 = 16'h8877,
                 btn_3_2 = 16'h48B7,
                 btn_3_3 = 16'hC837,
                 btn_4_0 = 16'h28D7,
                 btn_4_1 = 16'hA857,
                 btn_4_2 = 16'h6897,
                 btn_4_3 = 16'hE817,
                 btn_5_0 = 16'h18E7,
                 btn_5_1 = 16'h9867,
                 btn_5_2 = 16'h58A7,
                 btn_5_3 = 16'hD827;
  assign {controlCode, btnCode} = code;
  assign valid = ~&button & (controlCode != REMOTECode);
  always@*
    begin
      case(btnCode)
        btn_0_0: button = 5'd0;
        btn_0_1: button = 5'd1;
        btn_0_2: button = 5'd2;
        btn_0_3: button = 5'd3;
        btn_1_0: button = 5'd4;
        btn_1_1: button = 5'd5;
        btn_1_2: button = 5'd6;
        btn_1_3: button = 5'd7;
        btn_2_0: button = 5'd8;
        btn_2_1: button = 5'd9;
        btn_2_2: button = 5'd10;
        btn_2_3: button = 5'd11;
        btn_3_0: button = 5'd12;
        btn_3_1: button = 5'd13;
        btn_3_2: button = 5'd14;
        btn_3_3: button = 5'd15;
        btn_4_0: button = 5'd16;
        btn_4_1: button = 5'd17;
        btn_4_2: button = 5'd18;
        btn_4_3: button = 5'd19;
        btn_5_0: button = 5'd20;
        btn_5_1: button = 5'd21;
        btn_5_2: button = 5'd22;
        btn_5_3: button = 5'd23;
        default: button = 5'b11111;
      endcase
    end
endmodule

module brightnessControllerRGB(sync, rst, rgb_i, rgb_o, brightness, an);
  input rst, an, sync;
  input [2:0] brightness, rgb_i;
  output [2:0] rgb_o;
  wire pass;
  reg [2:0] counter;
  assign rgb_o = (pass) ? rgb_i : {3{an}};
  assign pass = ~(brightness < counter);
  always@(posedge sync or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          counter <= counter + 3'd0;
        end
    end
endmodule

module rgb_led_controller8(clk, rst, rcolor_i, gcolor_i, bcolor_i, sync, half, r_o, g_o, b_o, an);
  input clk, rst;
  output sync, half; //start of a new cycle, second half of the cycle

  input an; //High when connecting to anode, low for cathode

  input [7:0] rcolor_i, gcolor_i, bcolor_i; //Color data ins
  output r_o, g_o, b_o; //Connected to LEDs

  reg [7:0] rcolor_reg, gcolor_reg, bcolor_reg;
  reg red, green, blue;
  reg [7:0] counter;

  assign r_o = red ^ an;
  assign g_o = green ^ an;
  assign b_o = blue ^ an;
  assign half = counter[7]; 
  assign sync = ~|counter;

  //Counter for full cycle
  always @(posedge clk or posedge rst) 
    begin
      if(rst)
        begin
          counter <= 8'd0;
        end
      else
        begin
          counter <= counter + 8'd1;
        end
    end

  //Only change color in new cycles
  always@(posedge sync or posedge rst)
    begin
      if(rst)
        begin
          rcolor_reg <= rcolor_i;
          gcolor_reg <= gcolor_i;
          bcolor_reg <= bcolor_i;
        end
      else
        begin
          rcolor_reg <= rcolor_i;
          gcolor_reg <= gcolor_i;
          bcolor_reg <= bcolor_i;
        end
    end
  
  //Drive LED pins
  always@(posedge clk)
    begin //       All 1s          All 0s         New cycle           Pulse end
        red <= (&rcolor_reg) | ((|rcolor_reg) & ((~|counter) | ((counter != rcolor_reg) & red)));
       blue <= (&bcolor_reg) | ((|bcolor_reg) & ((~|counter) | ((counter != bcolor_reg) & blue)));
      green <= (&gcolor_reg) | ((|gcolor_reg) & ((~|counter) | ((counter != gcolor_reg) & green)));
    end
endmodule//RGB LED controller with 8 bit resolution

module pulseGen(clk, rst, en, pulse);
  input clk, rst, en;
  output pulse;
  reg [24:0] counter;

  assign pulse = (counter == 25'd29_999_999);

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          counter <= 25'd0;
        end
      else
        begin
          counter <= (pulse) ? 25'd0 : (counter + {24'd0, en});
        end
    end 
endmodule