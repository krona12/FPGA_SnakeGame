//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           rgb_display
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:         vga方块移动显示模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  video_display(
    input             pixel_clk,                  //VGA驱动时钟
    input             sys_rst_n,                //复位信号
    
    input      [10:0] pixel_xpos,               //像素点横坐标
    input      [10:0] pixel_ypos,               //像素点纵坐标   
    input       [3:0]key,//控制上下左右
    output reg [23:0] pixel_data                //像素点数据
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //分辨率--行
parameter  V_DISP  = 11'd720;                   //分辨率--列

localparam SIDE_W  = 11'd40;                    //屏幕边框宽度
localparam BLOCK_W = 11'd40;                    //方块宽度
localparam BLUE    = 24'b00000000_00000000_11111111;    //屏幕边框颜色 蓝色
localparam WHITE   = 24'b11111111_11111111_11111111;    //背景颜色 白色
localparam BLACK   = 24'b00000000_00000000_00000000;    //方块颜色 黑色

//reg define
reg [10:0] block_x = SIDE_W ;                             //方块左上角横坐标
reg [10:0] block_y = SIDE_W ;                             //方块左上角纵坐标
reg [21:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：
reg [1:0]direction;
//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz
assign move_en = (div_cnt == 22'd742500) ? 1'b1 : 1'b0;
//*****************************************************
//**                    main code
//*****************************************************

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
    end
    else if (key[0] == 0) begin  // 上
        if(!(direction==2'd1))
            direction=2'd0;
    end
    else if (key[1] == 0) begin  // 下
        if(!(direction==2'd0))
             direction=2'd1;
    end
    else if (key[2] == 0) begin  // 左
        if(!(direction==2'd3))
            direction=2'd2;
    end
    else if (key[3] == 0) begin  // 右
        if(!(direction==2'd2))
            direction=2'd3;
    end
    // 省略空的else部分
end

//通过对vga驱动时钟计数，实现时钟分频
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 22'd0;
    else begin
        if(div_cnt < 22'd742500) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;                   //计数达10ms后清零
    end
end

//当方块移动到边界时，改变移动方向
// always @(posedge pixel_clk ) begin         
//     if (!sys_rst_n) begin
//         h_direct <= 1'b1;                       //方块初始水平向右移动
//         v_direct <= 1'b1;                       //方块初始竖直向下移动
//     end
//     else begin
//         if(block_x == SIDE_W - 1'b1)            //到达左边界时，水平向右
//             h_direct <= 1'b1;               
//         else                                    //到达右边界时，水平向左
//         if(block_x == H_DISP - SIDE_W - BLOCK_W)
//             h_direct <= 1'b0;               
//         else
//             h_direct <= h_direct;
            
//         if(block_y == SIDE_W - 1'b1)            //到达上边界时，竖直向下
//             v_direct <= 1'b1;                
//         else                                    //到达下边界时，竖直向上
//         if(block_y == V_DISP - SIDE_W - BLOCK_W)
//             v_direct <= 1'b0;               
//         else
//             v_direct <= v_direct;
//     end
// end

//根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        block_x <= SIDE_W;                     // 方块初始位置横坐标
        block_y <= SIDE_W;                     // 方块初始位置纵坐标
    end
    else if (move_en) begin
        case (direction)
            2'd0: block_y <= block_y - 1'b1;   // 方块向上移动
            2'd1: block_y <= block_y + 1'b1;   // 方块向下移动
            2'd2: block_x <= block_x - 1'b1;   // 方块向左移动
            2'd3: block_x <= block_x + 1'b1;   // 方块向右移动
        endcase
    end
end


//给不同的区域绘制不同的颜色
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) 
        pixel_data <= BLACK;
    else begin
        if(  (pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
          || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W))
            pixel_data <= BLUE;                 //绘制屏幕边框为蓝色
        else
        if(  (pixel_xpos >= block_x) && (pixel_xpos < block_x + BLOCK_W)
          && (pixel_ypos >= block_y) && (pixel_ypos < block_y + BLOCK_W))
            pixel_data <= BLACK;                //绘制方块为黑色
        else
            pixel_data <= WHITE;                //绘制背景为白色
    end
end

endmodule 