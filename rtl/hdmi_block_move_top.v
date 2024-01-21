//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           top_hdmi_colorbar
// Last modified Date:  2019/7/1 9:30:00
// Last Version:        V1.1
// Descriptions:        HDMI彩条显示实验顶层模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/7/1 9:30:00
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  hdmi_block_move_top(
    input        sys_clk,
    input        sys_rst_n,
    input       [3:0]key,//控制上下左右
 	 
    output       tmds_clk_p,    // TMDS 时钟通道
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS 数据通道
    output [2:0] tmds_data_n
);

//wire define
wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;

//*****************************************************
//**                    main code
//*****************************************************

//例化视频显示驱动模块
video_driver u_video_driver(
    .pixel_clk      (tx_pclk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),      //行信号
    .video_vs       (video_vs),      //场信号
    .video_de       (video_de),      //数据使能
    .video_rgb      (video_rgb),     //像素点颜色数据输出

    .pixel_xpos     (pixel_xpos_w),  //像素点横坐标
    .pixel_ypos     (pixel_ypos_w),  //像素点纵坐标
    .pixel_data     (pixel_data_w)   //像素点颜色数据输入
    );

//例化视频显示模块
video_display  u_video_display(
    .pixel_clk      (tx_pclk),
    .sys_rst_n      (sys_rst_n),
    .key            (key),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
    );

rgbtodvi_top u_rgbtodvi_top (
  .sys_clk     (sys_clk),
  .blue_din    (video_rgb[7:0]),
  .green_din   (video_rgb[15:8]),
  .red_din     (video_rgb[23:16]),
  .hsync       (video_hs),
  .vsync       (video_vs),
  .de          (video_de),	 

  .pclk        (tx_pclk),  
  .TMDS_CLK    (tmds_clk_p),          // TMDS 时钟通道
  .TMDS_CLKB   (tmds_clk_n),	  
  .TMDS        (tmds_data_p),         // TMDS 数据通道
  .TMDSB       (tmds_data_n)
 );
 
endmodule 