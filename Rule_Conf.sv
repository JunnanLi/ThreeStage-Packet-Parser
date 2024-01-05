/****************************************************/
//  Module name: Rule_Conf
//  Authority @ lijunnan (lijunnan@nudt.edu.cn)
//  Last edited time: 2024/01/03
//  Function outline: 3-stage programmable parser
/****************************************************/

module Rule_Conf
#(
  parameter     TYPE_OFFSET_WIDTH = 7,
  parameter     TYPE_NUM          = 4,
  parameter     RULE_NUM          = 4,
  parameter     RULE_WIDTH        = 129
)
(
  input   wire                                              i_clk,
  input   wire                                              i_rst_n,
  input   wire                                              i_rule_wren,
  input   wire  [63:0]                                      i_rule_wdata,
  input   wire  [31:0]                                      i_rule_addr,
  output  reg   [TYPE_NUM-1:0][TYPE_OFFSET_WIDTH-1:0]       o_type_offset,
  output  reg   [RULE_NUM-1:0]                              o_typeRule_wren,
  output  wire  [RULE_WIDTH-1:0]                            o_typeRule_wdata
);

  //====================================================================//
  //*   internal reg/wire/param declarations
  //====================================================================//
  reg   [255:0]                           r_typeRule_wdata;
  assign o_typeRule_wdata = r_typeRule_wdata[RULE_WIDTH-1:0];
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

  //====================================================================//
  //*   configure rules & type_offset
  //====================================================================//
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
      o_typeRule_wren           <= 'b0;
    end else begin
      if(i_rule_wren == 1'b1) begin
        if(i_rule_addr[16] == 1'b0) begin //* conf type_offset;
          for(integer i=0; i<TYPE_NUM; i++)
            o_type_offset[i]  <= i_rule_wdata[i*TYPE_OFFSET_WIDTH+:TYPE_OFFSET_WIDTH];
        end
        else begin //* conf rules;
          o_typeRule_wren                     <= 'b0;
          case(i_rule_addr[9:8])
            2'd0: r_typeRule_wdata[63:0]      <= i_rule_wdata;
            2'd1: r_typeRule_wdata[64+:64]    <= i_rule_wdata;
            2'd2: r_typeRule_wdata[64*2+:64]  <= i_rule_wdata;
            2'd3: begin 
              r_typeRule_wdata[64*3+:64]      <= i_rule_wdata;
              o_typeRule_wren                 <= i_rule_addr[RULE_NUM-1:0];
            end
          endcase
        end
      end
    end
  end
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//


endmodule