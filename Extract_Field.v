/****************************************************/
//  Module name: Extract_Field
//  Authority @ lijunnan (lijunnan@nudt.edu.cn)
//  Last edited time: 2024/01/02
//  Function outline: 3-stage programmable parser
/****************************************************/

module Extract_Field #(
  parameter   PHV_WIDTH             = 1024,
  parameter   EXTRACT_WIDTH         = 8,
  parameter   OFFSET_WIDTH          = $clog2(PHV_WIDTH/EXTRACT_WIDTH),
  parameter   EXTRACT_NO_DELAHY     = 1
)(
  input   wire                      i_clk,
  input   wire                      i_rst_n,
  input   wire  [PHV_WIDTH-1:0]     i_data,
  output  wire  [EXTRACT_WIDTH-1:0] o_extract_data,
  input   wire  [OFFSET_WIDTH-1:0]  i_offset
);

  //====================================================================//
  //*   internal reg/wire/param declarations
  //====================================================================//
  wire  [EXTRACT_WIDTH-1:0]         w_extract_data;
  reg   [EXTRACT_WIDTH-1:0]         r_extract_data;
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//


  //====================================================================//
  //*   extract fields
  //====================================================================//
  assign w_extract_data = i_data[i_offset];
  assign o_extract_data = (EXTRACT_NO_DELAHY)? w_extract_data: r_extract_data;

  always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
      r_extract_data  <= {EXTRACT_WIDTH{1'b0}};
    end else begin
      r_extract_data  <= w_extract_data;
    end
  end
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//
  
endmodule    