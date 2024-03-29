/*
 *  Project:            timelyRV_v0.1 -- a RISCV-32I SoC.
 *  Module name:        util_gmii_to_rgmii.
 *  Description:        RGMII <-> GMII. As this module use language templates 
 *                        to receive and send packets (rgmii), you need to 
 *                        choose IDDR (ODDR) or IDDRE1 (ODDRE1);
 *  Last updated date:  2021.07.13.
 *
 *  Copyright (C) 2021-2022 Junnan Li <lijunnan@nudt.edu.cn>.
 *  Copyright and related rights are licensed under the MIT license.
 *
 */

module util_gmii_to_rgmii (
  input               clk_200m,
  input               clk_125m_90,
  input               rst_n,
  output  wire  [3:0] rgmii_td,
  output  wire        rgmii_tx_ctl,
  output  wire        rgmii_txc,
  input         [3:0] rgmii_rd,
  input               rgmii_rx_ctl,
  input               rgmii_rxc,

  output  wire        gmii_rx_clk,
  output  wire  [7:0] gmii_rxd,
  output  wire        gmii_rx_dv,
  output  wire        gmii_rx_er,
  input   wire        gmii_tx_clk,
  input         [7:0] gmii_txd,
  input               gmii_tx_en,
  input               gmii_tx_er
);
  
  genvar i;
  
  //* gen gmii_rx_clk;
  //* bufg
  // BUFG bufmr_rgmii_rxc(
  //   .I(rgmii_rxc),
  //   .O(gmii_rx_clk)
  // );
  
  //* bufr
  wire clk_io;
  // pass through RX clock to input buffers
  BUFIO
  clk_bufio (
      .I(rgmii_rxc),
      .O(clk_io)
  );

  // pass through RX clock to logic
  BUFR #(
      .BUFR_DIVIDE("BYPASS")
  )
  clk_bufr (
      .I(rgmii_rxc),
      .O(gmii_rx_clk),
      .CE(1'b1),
      .CLR(1'b0)
  );

  IDELAYCTRL
  idelayctrl_inst (
    .REFCLK(clk_200m),
    .RST(rst_n),
    .RDY()
  );

  wire rgmii_rx_ctl_delay;
  wire [3:0]  rgmii_rd_delay;
  generate
    for (i = 0; i < 4; i = i + 1) begin
      IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
      )
      phy_rxd_idelay_0 (
        .IDATAIN(rgmii_rd[i]),
        .DATAOUT(rgmii_rd_delay[i]),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
      );
    end
  endgenerate

  IDELAYE2 #(
    .IDELAY_VALUE(0),
    .IDELAY_TYPE("FIXED")
  )
  phy_rx_ctl_idelay(
    .IDATAIN(rgmii_rx_ctl),
    .DATAOUT(rgmii_rx_ctl_delay),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
  );



  //* gen gmii_rx_er, gmii_rxd, gmii_rx_dv;
  //* from clock domain of rgmii_rxc to gmii_rx_clk;
  (* mark_debug = "true"*)wire      gmii_rx_er_w, gmii_rx_dv_w, gmii_rx_ctl_w;
  (* mark_debug = "true"*)wire  [7:0] gmii_rxd_w;
  
  assign gmii_rx_er = gmii_rx_dv_w ^ gmii_rx_ctl_w;
  assign gmii_rx_dv = gmii_rx_dv_w;
  assign gmii_rxd = gmii_rxd_w;

  //* gen gmii_rxd
  generate
    for (i = 0; i < 4; i = i + 1) begin
      IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
        .INIT_Q1(0),
        .INIT_Q2(0),
        .SRTYPE("ASYNC")
      ) rgmii_rx_iddr (
        .Q1(gmii_rxd_w[i]),
        .Q2(gmii_rxd_w[i+4]),
        .C(clk_io),
        .CE(1'b1),
        .D(rgmii_rd_delay[i]),
        .R(1'b0),
        .S(1'b0)
      );
         
    end
  endgenerate

  //* gen gmii_rx_dv;
  IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
    .INIT_Q1(0),
    .INIT_Q2(0),
    .SRTYPE("ASYNC")
  ) rgmii_rx_ctl_iddr (
    .Q1(gmii_rx_dv_w),
    .Q2(gmii_rx_ctl_w),
    .C(clk_io),
    .CE(1'b1),
    .D(rgmii_rx_ctl_delay),
    .R(1'b0),
    .S(1'b0)
  );



  //* gen rgmii_txc;
  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"),
    .SRTYPE("ASYNC")
  ) rgmii_txc_out (
    .Q (rgmii_txc),
    .C (clk_125m_90),
    .CE(1'b1),
    .D1(1'b1),
    .D2(1'b0),
    .R(1'b0),
    .S(1'b0)
  );
  
  

  //* gen rgmii_td;
  
  generate
    for (i = 0; i < 4; i = i + 1) begin : gen_tx_data
      ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .SRTYPE("ASYNC")
      ) rgmii_td_out (
        .Q (rgmii_td[i]),
        .C (gmii_tx_clk),
        .CE(1'b1),
        .D1(gmii_txd[i]),
        .D2(gmii_txd[4+i]),
        .R(1'b0),
        .S(1'b0)
      );
    end
  endgenerate

  //* gen rgmii_tx_ctl;
  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"),
    .SRTYPE("ASYNC")
  ) rgmii_tx_ctl_out (
    .Q (rgmii_tx_ctl),
    .C (gmii_tx_clk),
    .CE(1'b1),
    .D1(gmii_tx_en),
    .D2(gmii_tx_en^gmii_tx_er),
    .R(1'b0),
    .S(1'b0)
  );
  

  

endmodule
