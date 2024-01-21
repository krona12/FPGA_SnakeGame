//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2009                 www.xilinx.com
//
//  XAPP xyz
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       rgbtodvi_top.v
//
//  Description :     rgbtodvi_top 
//
//  Date - revision : April 2009 - 1.0.0
//
//  Author :          Bob Feng
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors makeand you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specificallydisclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does notwarrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designswill be
//              uninterrupted or error free, or that defects in theDesigns
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results ofthe
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or forany
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on anytheory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure ofthe
//              essential purpose of any limited remedies herein.
//
//  Copyright 2009 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1ps

module rgbtodvi_top (
  input  wire       sys_clk,        
  input  wire [7:0] blue_din,       // Blue data in
  input  wire [7:0] green_din,      // Green data in
  input  wire [7:0] red_din,        // Red data in
  input  wire       hsync,          // hsync data
  input  wire       vsync,          // vsync data
  input  wire       de,             // data enable
  
  output wire       pclk,           // pixel clock   
  output wire       TMDS_CLK,
  output wire       TMDS_CLKB,  
  output wire [2:0] TMDS,
  output wire [2:0] TMDSB
  );

//wire define  
wire [9:0] red ;
wire [9:0] green ;
wire [9:0] blue ;
wire [4:0] tmds_data0; 
wire [4:0] tmds_data1; 
wire [4:0] tmds_data2;
wire [2:0] tmdsint;
wire [2:0] tmdsint1;

//*****************************************************
//**                    main code
//*****************************************************
 
assign rstin = ~tx_bufpll_lock;
 
  
  pll u_pll
   (// Clock in ports
    .CLK_IN1(sys_clk),     
    // Clock out ports
    .CLK_OUT1(tx_pllclk0),     
    .CLK_OUT2(pclkx2),     
    .CLK_OUT3(pclk),    
    // Status and control signals
    .LOCKED(tx_plllckd));     
  
// regenerate pclkx10 for TX

BUFPLL #(
	.DIVIDE(5)
) tx_ioclk_buf (
	.PLLIN(tx_pllclk0), 
	.GCLK(pclkx2), 
	.LOCKED(tx_plllckd),
    .IOCLK(pclkx10), 
	.SERDESSTROBE(serdesstrobe), 
	.LOCK(tx_bufpll_lock)
);  
  
// Forward TMDS Clock Using OSERDES2 block
reg [4:0] tmdsclkint = 5'b00000;
reg toggle = 1'b0;

always @ (posedge pclkx2 or posedge rstin) begin
  if (rstin)
    toggle <= 1'b0;
  else
    toggle <= ~toggle;
end

always @ (posedge pclkx2) begin
  if (toggle)
    tmdsclkint <= 5'b11111;
  else
    tmdsclkint <= 5'b00000;
end

wire tmdsclk;

serdes_n_to_1 #(
  .SF           (5))
clkout (
  .iob_data_out (tmdsclk),
  .ioclk        (pclkx10),
  .serdesstrobe (serdesstrobe),
  .gclk         (pclkx2),
  .reset        (rstin),
  .datain       (tmdsclkint));

OBUFDS TMDS3 (.I(tmdsclk), .O(TMDS_CLK), .OB(TMDS_CLKB)) ;// clock

//8b/10b编码
encode encb (
  .clkin	(pclk),
  .rstin	(rstin),
  .din		(blue_din),
  .c0		(hsync),
  .c1		(vsync),
  .de		(de),
  .dout		(blue)) ;

encode encg (
  .clkin	(pclk),
  .rstin	(rstin),
  .din		(green_din),
  .c0		(1'b0),
  .c1		(1'b0),
  .de		(de),
  .dout		(green)) ;
  
encode encr (
  .clkin	(pclk),
  .rstin	(rstin),
  .din		(red_din),
  .c0		(1'b0),
  .c1		(1'b0),
  .de		(de),
  .dout		(red)) ;

wire [29:0] s_data = {red[4:0], green[4:0], blue[4:0],
					  red[9:5], green[9:5], blue[9:5]};
					   
convert_30to15_fifo u_convert_30to15_fifo (
  .rst(rstin), // input rst
  .wr_clk(pclk), // input wr_clk
  .rd_clk(pclkx2), // input rd_clk
  .din(s_data), // input [29 : 0] din
  .wr_en(1'b1), // input wr_en
  .rd_en(1'b1), // input rd_en
  .dout({tmds_data2, tmds_data1, tmds_data0}), // output [14 : 0] dout
  .full(), // output full
  .empty() // output empty
);  
  
// Forward TMDS Data: 3 channels
serdes_n_to_1 #(.SF(5)) oserdes0 (
           .ioclk(pclkx10),
           .serdesstrobe(serdesstrobe),
           .reset(rstin),
           .gclk(pclkx2),
           .datain(tmds_data0),
           .iob_data_out(tmdsint[0])) ;

serdes_n_to_1 #(.SF(5)) oserdes1 (
           .ioclk(pclkx10),
           .serdesstrobe(serdesstrobe),
           .reset(rstin),
           .gclk(pclkx2),
           .datain(tmds_data1),
           .iob_data_out(tmdsint[1])) ;

serdes_n_to_1 #(.SF(5)) oserdes2 (
           .ioclk(pclkx10),
           .serdesstrobe(serdesstrobe),
           .reset(rstin),
           .gclk(pclkx2),
           .datain(tmds_data2),
           .iob_data_out(tmdsint[2])) ;

OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0])) ;
OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1])) ;
OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2])) ;

endmodule
