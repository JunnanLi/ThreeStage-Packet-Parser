/*
 *  Project:            HyPipe_SoC.
 *  Module name:        HyPipe_SoC for K7-325t.
 *  Description:        Top Module of HyPipe_SoC_hardware.
 *  Last updated date:  2024.01.11.
 *
 *  Communicate with Junnan Li <lijunnan@nudt.edu.cn>.
 *  Copyright (C) 2021-2024 NUDT.
 *
 *  Noted:
 *    1) rgmii2gmii & gmii_rx2rgmii are processed by language templates;
 *    2) rgmii_rx is constrained by set_input_delay "-2.0 ~ -0.7";
 *    3) 134b pkt data definition: 
 *      [133:132] head tag, 2'b01 is head, 2'b10 is tail;
 *      [131:128] valid tag, 4'b1111 means sixteen 8b data is valid;
 *      [127:0]   pkt data, invalid part is padded with 0;
 *
 *  Space = 2;
 */

module HyPipe_SoC(
  //* system input, clk;
  input   wire          sys_clk_p
  ,input  wire          sys_clk_n
  ,input  wire          cpu_resetn
  //* rgmii port;
  ,output wire          eth_rst_n
  ,input  wire          eth_rxck 
  ,input  wire          eth_rxctl
  ,input  wire  [3:0]   eth_rxd  
  ,output wire          eth_txck 
  ,output wire          eth_txctl
  ,output wire  [3:0]   eth_txd  
  ,inout  wire          eth_mdio 
  ,output wire          eth_mdc  

  //* uart rx/tx from/to host;
  ,input               uart_rx      //* fpga receive data from host;
  ,output  wire        uart_tx      //* fpga send data to host;
);

  
  //====================================================================//
  //*   internal reg/wire/param declarations
  //====================================================================//
  //* clock & locker;
  wire                  clk_125m, clk_50m;        //* 25M clk for Core;
  wire                  clk_200m, clk_125m_90;
  wire                  locked;                   //* locked =1 means generating 125M clock successfully;

  //* system reset signal, low is active;
  wire                  sys_rst_n;
  assign                sys_rst_n     = cpu_resetn & locked;

  //* connected wire (TODO,...)
  //* speed_mode, clock_speed, mdio (gmii_to_rgmii IP)
  wire    [1:0]         speed_mode, clock_speed;
  wire                  mdio_gem_mdc, mdio_gem_o, mdio_gem_t;
  wire                  mdio_gem_i;
  
  //* assign eth_rst_n = 1, haven't been used;
  assign                eth_rst_n     = cpu_resetn;
  //* assign eth_mdc = 0, haven't been used;
  assign                eth_mdc       = 1'b0;
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

  //====================================================================//
  //*   clk wiz
  //====================================================================//
  //* gen 125M clock (Xilinx ip: clk_wiz);
  clk_to_125m clk_to_125m_inst(
    //* Clock out ports
    .clk_out1           (clk_125m             ),  //* output 125m;
    .clk_out2           (clk_50m              ),  //* output 25m;
    .clk_out3           (clk_200m             ),
    .clk_out4           (clk_125m_90          ),
    //* Status and control signals
    .reset              (!cpu_resetn          ),  //* input reset
    .locked             (locked               ),  //* output locked
    // Clock in ports
    // .clk_in1            (sys_clk              )
    .clk_in1_p          (sys_clk_p            ),  //* input clk_in1_p
    .clk_in1_n          (sys_clk_n            )   //* input clk_in1_n
  );
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//
  

  (* mark_debug = "true"*)wire  [133:0]             pktData_gmii, pktData_um;
  (* mark_debug = "true"*)wire                      pktData_valid_gmii, pktData_valid_um;
  

  //====================================================================//
  //*   soc_runtime
  //====================================================================//
  //* rgmii <==> 134b pkt (without metadata);
  soc_runtime runtime(
    .clk_125m             (clk_125m                     ),
    .clk_200m             (clk_200m                     ),
    .clk_125m_90          (clk_125m_90                  ),
    .i_pe_clk             (clk_125m                     ),
    .sys_rst_n            (sys_rst_n                    ),
    //* rgmii input;
    .rgmii_rd             (eth_rxd                      ),  //* input
    .rgmii_rx_ctl         (eth_rxctl                    ),  //* input
    .rgmii_rxc            (eth_rxck                     ),  //* input
    //* rgmii output;
    .rgmii_txc            (eth_txck                     ),  //* output
    .rgmii_td             (eth_txd                      ),  //* output
    .rgmii_tx_ctl         (eth_txctl                    ),  //* output
    //* um;
    .pktData_valid_gmii   (pktData_valid_gmii           ),
    .pktData_gmii         (pktData_gmii                 ),
    .pkt_length_gmii      (                             ),
    .ready_in             (1'b1                         ),
    .pktData_valid_um     (pktData_valid_um             ),
    .pktData_um           (pktData_um                   )
  );
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//
  

  //====================================================================//
  //*   PE_ARRAY
  //====================================================================//
  HyPipe_Top HyPipe_Top(
    //* clock & resets;
    .i_clk                (clk_125m                     ),
    .i_rst_n              (sys_rst_n                    ),
    .i_data_valid         (pktData_valid_gmii           ),
    .i_data               (pktData_gmii                 ),
    .o_data_valid         (pktData_valid_um             ),
    .o_data               (pktData_um                   )

  );
  //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//





endmodule