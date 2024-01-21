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
localparam BLOCK_W = 11'd20;                    //方块宽度
localparam BLUE    = 24'b00000000_00000000_11111111;    //屏幕边框颜色 蓝色
localparam WHITE   = 24'b11111111_11111111_11111111;    //背景颜色 白色
localparam BLACK   = 24'b00000000_00000000_00000000;    //方块颜色 黑色

localparam INI_X =11'd640 ;//初始位置
localparam INI_Y =11'd360 ;

//reg define
reg [10:0] block_x = INI_X ;                             //方块左上角横坐标
reg [10:0] block_y = INI_Y ;                             //方块左上角纵坐标
reg [10:0] SnakeSize=3;//定义蛇长度
reg [10:0] Snake_Array[24:0][1:0]; // 定义蛇的每节的坐标数组


reg [21:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：
reg [1:0]direction;
//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz
reg MOEN;                                       //按键移动是能
assign move_en = (div_cnt == 25'd74250) ? 1'b1 : 1'b0;
//*****************************************************
//**                    main code
//*****************************************************

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        MOEN=0;
    end
    else if (key[0] == 0) begin  // 上
        if(!(direction==2'd1))
            direction=2'd0;
            MOEN=1;
    end
    else if (key[1] == 0) begin  // 下
        if(!(direction==2'd0))
             direction=2'd1;
            MOEN=1;            
    end
    else if (key[2] == 0) begin  // 左
        if(!(direction==2'd3))
            direction=2'd2;
            MOEN=1;
    end
    else if (key[3] == 0) begin  // 右
        if(!(direction==2'd2))
            direction=2'd3;
            MOEN=1;
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
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
//根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        for(index0=0; index0<SnakeSize; index0=index0+1) begin
            Snake_Array[index0][0] = INI_X - index0 * BLOCK_W;
            Snake_Array[index0][1] = INI_Y;
        end
    end
    else if (move_en&&MOEN) begin
        case (direction)
            2'd0:
            begin
                for(index1=SnakeSize-1; index1>0; index1=index1-1) begin
                    Snake_Array[index1][0] = Snake_Array[index1-1][0];
                    Snake_Array[index1][1] = Snake_Array[index1-1][1];
                end
                Snake_Array[0][1] = Snake_Array[0][1] -BLOCK_W;//这里要注意是加BLOCK_W,之前设为1，导致蛇重合成一个方块了。还以为是蛇移动和draw频率的问题
            end
            2'b1:
            begin
                for(index2=SnakeSize-1; index2>0; index2=index2-1) begin
                    Snake_Array[index2][0] = Snake_Array[index2-1][0];
                    Snake_Array[index2][1] = Snake_Array[index2-1][1];
                end
                Snake_Array[0][1] = Snake_Array[0][1] + BLOCK_W;
            end
            2'd2:
            begin
                for(index3=SnakeSize-1; index3>0; index3=index3-1) begin
                    Snake_Array[index3][0] = Snake_Array[index3-1][0];
                    Snake_Array[index3][1] = Snake_Array[index3-1][1];
                end
                Snake_Array[0][0] = Snake_Array[0][0] -BLOCK_W; // 修正为x坐标
            end
            2'd3:
            begin
                for(index4=SnakeSize-1; index4>0; index4=index4-1) begin
                    Snake_Array[index4][0] = Snake_Array[index4-1][0]; // 修正变量名称
                    Snake_Array[index4][1] = Snake_Array[index4-1][1];
                end
                Snake_Array[0][0] = Snake_Array[0][0] + BLOCK_W; // 修正为x坐标
            end
        endcase
    end
end


integer index_draw;
reg found_match = 0; // 添加一个标志来指示是否找到匹配

// 给不同的区域绘制不同的颜色
always @(posedge pixel_clk) begin
    if (!sys_rst_n) begin
        pixel_data <= BLACK;
    end else begin
        if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
            || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) begin
            pixel_data <= BLUE; // 绘制屏幕边框为蓝色
        end else begin
            found_match = 0; // 在每次像素时钟的边缘重置标志
            for (index_draw = 0; index_draw < SnakeSize && !found_match; index_draw = index_draw + 1) begin
                if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                    && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) begin
                    pixel_data <= BLACK; // 绘制方块为黑色
                    found_match = 1; // 标记找到匹配，防止将pixel_data设置为WHITE
                end
            end
            if (!found_match) begin
                pixel_data <= WHITE; // 如果没有找到匹配，则绘制背景为白色
            end
        end
    end
end



endmodule 