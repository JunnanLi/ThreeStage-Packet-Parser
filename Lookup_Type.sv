/****************************************************/
//  Module name: Lookup_Type
//  Authority @ lijunnan (lijunnan@nudt.edu.cn)
//  Last edited time: 2024/01/02
//  Function outline: 3-stage programmable parser
/****************************************************/


`timescale 1ns/1ps


module Lookup_Type
#(
  parameter     TYPE_NUM        = 4,
  parameter     TYPE_WIDTH      = 8,
  parameter     KEY_FILED_NUM   = 8,
  parameter     KEY_OFFSET_WIDTH= 6,
  parameter     RULE_NUM        = 4,
  parameter     RULE_WIDTH      = 1 + 2*TYPE_NUM*TYPE_WIDTH + KEY_FILED_NUM*KEY_OFFSET_WIDTH,
  parameter     LOOKUP_NO_DELAHY= 1
)
(
  input   wire                                              i_clk,
  input   wire                                              i_rst_n,
  input   wire  [TYPE_NUM-1:0][TYPE_WIDTH-1:0]              i_type,
  output  reg   [KEY_FILED_NUM-1:0][KEY_OFFSET_WIDTH-1:0]   o_result,
  input   wire  [RULE_NUM-1:0]                              i_rule_wren,
  input   wire  [RULE_WIDTH-1:0]                            i_rule_wdata
);


  //====================================================================//
  //*   internal reg/wire/param declarations
  //====================================================================//
  reg   [RULE_NUM-1:0][RULE_WIDTH-1:0]                      r_rule;
  logic [RULE_NUM-1:0]                                      w_hit_rule;
  logic [TYPE_NUM*TYPE_WIDTH-1:0]                           w_type;
  reg   [KEY_FILED_NUM*KEY_OFFSET_WIDTH-1:0]                w_result;
  // reg   [KEY_FILED_NUM-1:0][KEY_OFFSET_WIDTH-1:0] r_result;
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

  //====================================================================//
  //*   configure rules
  //====================================================================//
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
      for (integer i = 0; i < RULE_NUM; i++) begin
        r_rule[i][RULE_WIDTH-1] <= 1'b0;
      end
    end else begin
      for (integer i = 0; i < RULE_NUM; i++) begin
         r_rule[i]              <= i_rule_wren[i]? i_rule_wdata: r_rule[i];
      end
    end
  end
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

  //====================================================================//
  //*   lookup rules
  //====================================================================//
  //* combine type fields;
  always_comb begin
    for (integer i = 0; i < TYPE_NUM; i++) begin
      w_type[i*TYPE_WIDTH+:TYPE_WIDTH]  = i_type[i]; 
    end
  end
  //* check rules
  always_comb begin
    for (integer i = 0; i < RULE_NUM; i++) begin
      w_hit_rule[i]             = r_rule[i][RULE_WIDTH-1] & 
          (r_rule[i][RULE_WIDTH-1-:TYPE_NUM*TYPE_WIDTH] & w_type == 
            r_rule[i][RULE_WIDTH-1-TYPE_NUM*TYPE_WIDTH:TYPE_NUM*TYPE_WIDTH]);
    end
  end
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//
  
  //====================================================================//
  //*   output result
  //====================================================================//
  // assign o_result = (LOOKUP_NO_DELAHY)? w_result: r_result;
  always_comb begin
    w_result        = 'b0;
    for(integer i= 0; i < RULE_NUM; i++) begin
      w_result      = {KEY_FILED_NUM*KEY_OFFSET_WIDTH{w_hit_rule[i]}} & 
                        r_rule[0+:KEY_FILED_NUM*KEY_OFFSET_WIDTH] |
                        w_result;
    end
  end


  always_ff @(posedge i_clk) begin
    for (integer i = 0; i < KEY_FILED_NUM; i++) begin
       o_result[i]  <= w_result[i*KEY_OFFSET_WIDTH+:KEY_OFFSET_WIDTH];
    end
  end
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

endmodule