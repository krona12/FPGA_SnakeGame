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
    input       [5:0]key,//控制上下左右
    input	wire[2:0]	state_1,//菜单状态
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
localparam RED    = 24'b11111111_00000000_00000000; // 红色
localparam GREEN  = 24'b00000000_11111111_00000000; // 绿色
localparam Crimson = 24'hDC143C;
localparam FOOD_COLOR =Crimson ;
localparam INI_X =11'd640 ;//初始位置
localparam INI_Y =11'd360 ;
localparam StandardF =30'd742500;
localparam speed =1 ;


//parameter define                  

localparam PIC_X_START = 11'd1;      //图片起始点横坐标

localparam PIC_Y_START = 11'd1;      //图片起始点纵坐标

localparam PIC_WIDTH   = 11'd100;    //图片宽度

localparam PIC_HEIGHT  = 11'd100;    //图片高度


localparam FOOD_W =11'd20 ;//食物大小
localparam FOOD_X=11'd360 ;
localparam FOOD_Y=11'd460 ;
parameter game_start	= 3'b100;  //游戏界面的开始选项
parameter game_back		= 3'b101;  //游戏界面的返回选项
parameter game			= 3'b111;  //游戏中
//reg define
reg   [13:0]  rom_addr  ;  //ROM地址
reg [10:0] block_x = INI_X ;                             //方块左上角横坐标
reg [10:0] block_y = INI_Y ;                             //方块左上角纵坐标
reg [3:0] SnakeSize=3;//定义蛇长度
localparam MaxSize =16 ;
reg [10:0] Snake_Array[MaxSize:0][1:0]; // 定义蛇的每节的坐标数组
//food
reg [10:0]Food_Array[1:0];
reg FoodGene;
wire  [9:0]RandomX;
wire [9:0]RandomY;

reg [25:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：
reg [1:0]direction;
//wire define   

wire  [10:0]  x_cnt;       //横坐标计数器

wire  [10:0]  y_cnt;       //纵坐标计数器

wire          rom_rd_en ;  //ROM读使能信号

wire  [23:0]  rom_rd_data ;//ROM数据

wire move_en;                                   //方块移动使能信号，频率为100hz
reg MOEN;                                       //按键移动是能
assign move_en = (div_cnt == StandardF*10/speed) ? 1'b1 : 1'b0;
assign  rom_rd_en = 1'b1;                  //读使能拉高，即一直读ROM数据
//*****************************************************
//**                    main code
//*****************************************************

//rng_custom_range Ran1(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd1000,RandomX);
//rng_custom_range Ran2(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd600,RandomY);

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        MOEN=0;
    end
    else if (key[0] == 1) begin  // 上
        if(!(direction==2'd1))
            direction=2'd0;
            MOEN=1;
    end
    else if (key[1] == 1) begin  // 下
        if(!(direction==2'd0))
             direction=2'd1;
            MOEN=1;            
    end
    else if (key[2] == 1) begin  // 左
        if(!(direction==2'd3))
            direction=2'd2;
            MOEN=1;
    end
    else if (key[3] == 1) begin  // 右
        if(!(direction==2'd2))
            direction=2'd3;
            MOEN=1;
    end
    // 省略空的else部分
end

//通过对vga驱动时钟计数，实现时钟分频
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 0;
    else begin
        if(div_cnt < StandardF*10/speed) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 0;                   //计数达10ms后清零
    end
end
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
//根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) begin
        for(index0=0; index0<MaxSize; index0=index0+1) begin
            if(index0<SnakeSize)begin
            Snake_Array[index0][0] = INI_X - index0 * BLOCK_W;
            Snake_Array[index0][1] = INI_Y;
            end
        end
        Food_Array[0]=FOOD_X;
        Food_Array[1]=FOOD_Y;
    end
    else if (move_en&&MOEN) begin
        case (direction)
            2'd0:
            begin
                for(index1=MaxSize-1; index1>0; index1=index1-1) begin
                      if(index1<SnakeSize)begin
                    Snake_Array[index1][0] = Snake_Array[index1-1][0];
                    Snake_Array[index1][1] = Snake_Array[index1-1][1];
                      end
                end
                Snake_Array[0][1] = Snake_Array[0][1] -BLOCK_W;//这里要注意是加BLOCK_W,之前设为1，导致蛇重合成一个方块了。还以为是蛇移动和draw频率的问题
            end
            2'b1:
            begin
                for(index2=MaxSize-1; index2>0; index2=index2-1) begin
                      if(index2<SnakeSize)begin
                    Snake_Array[index2][0] = Snake_Array[index2-1][0];
                    Snake_Array[index2][1] = Snake_Array[index2-1][1];
                      end
                end
                Snake_Array[0][1] = Snake_Array[0][1] + BLOCK_W;
            end
            2'd2:
            begin
                for(index3=MaxSize-1; index3>0; index3=index3-1) begin
                      if(index3<SnakeSize)begin
                    Snake_Array[index3][0] = Snake_Array[index3-1][0];
                    Snake_Array[index3][1] = Snake_Array[index3-1][1];
                      end
                end
                Snake_Array[0][0] = Snake_Array[0][0] -BLOCK_W; // 修正为x坐标
            end
            2'd3:
            begin
                for(index4=MaxSize-1; index4>0; index4=index4-1) begin
                      if(index4<SnakeSize)begin
                    Snake_Array[index4][0] = Snake_Array[index4-1][0]; // 修正变量名称
                    Snake_Array[index4][1] = Snake_Array[index4-1][1];
                      end
                end
                Snake_Array[0][0] = Snake_Array[0][0] + BLOCK_W; // 修正为x坐标
            end
        endcase
        //吃到食物,食物更新逻辑        
		  if((Snake_Array[0][0]>=Food_Array[0])&&(Snake_Array[0][0]<Food_Array[0]+FOOD_W)&&(Snake_Array[0][1]>=Food_Array[1])&&(Snake_Array[0][1]<Food_Array[1]+FOOD_W))

        begin
            SnakeSize=SnakeSize+1;
				// 生成新的食物位置
            Food_Array[0]=100+(Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2)%(1200-100);
            Food_Array[1]=100+(Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+Food_Array[0])%(600-100);
        end
    end
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//字符“请选择难度”
//字符将显示在pixel_xpos[9:4] >=15 && pixel_xpos[9:4] < 25 && pixel_ypos[9:4] >= 8 && pixel_ypos[9:4] < 10范围内，
//在该范围内char[char_y][159-char_x] == 1'b1的像素点将被显示成黑色
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire    [9:0]   char_x  ;   //字符显示X轴坐标
wire    [9:0]   char_y  ;   //字符显示Y轴坐标

reg     [159:0] char    [31:0]  ;   //字符宽160 ，高32
 
assign  char_x  =   (pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22)? (pixel_xpos - 40*16) : 0;
assign  char_y  =   (pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22)? (pixel_ypos - 20*16) : 0;
 
//字符“请选择难度”
always@(posedge pixel_clk)
    begin
        char[0]     <=  160'h0000000000000000000000000000000000000000;
        char[1]     <=  160'h0000000000000000000000000000000000000000; 
        char[2]     <=  160'h00003c000000380001c000000000ee000003c000; 
        char[3]     <=  160'h0e003c000c063c0001e000f00000ff000003e000; 
        char[4]     <=  160'h0f003c180f07b80001cffff80000f7800001e038;
        char[5]     <=  160'h07803c3c0787b80001c7c0f00000f7800e00e07c; 
        char[6]     <=  160'h07bffffc078738c001c0c1e0003de3980ffffffe; 
        char[7]     <=  160'h079c3c60078f39e001c0e3c03fffe33c0f0e0700; 
        char[8]     <=  160'h07003cf0038ffff001de77c01c3dfffc0f0f0780; 
        char[9]     <=  160'h000ffff8030e38007fff7f800039c7000f0e0730; 
        char[10]     <=  160'h00073c00001c380039c03f00303bc7000f0e0778;
        char[11]     <=  160'h07003c18001c380001c03f00387bc7000ffffffc; 
        char[12]     <=  160'hff803c3c03b8383001c07fc01c7fc7300fce0700; 
        char[13]     <=  160'h77fffffe7ff0387801dffffe0e77c7780f0e0700; 
        char[14]     <=  160'h0738000077fffffc01ffdffe0f7ffffc0f0e0700; 
        char[15]     <=  160'h070600e007b9ce0001ff9e7807ffc7000f0e0700; 
        char[16]     <=  160'h0707fff00781ce0007fc1c3003fdc7000e0fff00; 
        char[17]     <=  160'h070700f00781ce003fc01c7801f9c7000e0e0700; 
        char[18]     <=  160'h070700e00781ce007fcffffc01e1c7000e0c0380; 
        char[19]     <=  160'h070700e00783ce187dc71c0003f1c7300e7fffc0; 
        char[20]     <=  160'h071fffe007838e1831c01c0003f1c7780e3e07c0; 
        char[21]     <=  160'h073f00e007878e1801c01c1807f9fffc0e070f80;
        char[22]     <=  160'h077700e007870e1801c01c3c0739c7001e078f00; 
        char[23]     <=  160'h07e7ffe0078f0e3c01dffffe0e3dc7001c03de00; 
        char[24]     <=  160'h07e700e00f9e0ffc01de1c001e3dc7001c01fc00; 
        char[25]     <=  160'h07c700e03ff80ffc01c01c003c19c7181c00f800; 
        char[26]     <=  160'h078700e07cf0000001c01c007819c73c3801fc00; 
        char[27]     <=  160'h070700e0f87fc0ff3fc01c00f001fffe3807ffc0; 
        char[28]     <=  160'h03070fe0701ffffe3fc01c00c001c000703f0ffe; 
        char[29]     <=  160'h000703e00007fff807c01c000001c00071fc03fe; 
        char[30]     <=  160'h000701c00000000003801c000001c000e7e00078; 
        char[31]     <=  160'h0000000000000000000000000000000000000000;
    end
 
integer index_draw;
reg found_match = 0; // 添加一个标志来指示是否找到匹配

// 给不同的区域绘制不同的颜色
always @(posedge pixel_clk) begin
    if (!sys_rst_n) begin
        pixel_data <= BLACK; // 默认黑色背景
    end else begin
      case (state_1)
            game_start: begin
              if(pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22&& char[char_y][159-char_x] == 1'b1) begin
						pixel_data<= BLACK; end//显示“请选择难度” 字符
						
					  else if(pixel_xpos[9:4] >=42 && pixel_xpos[9:4] < 43 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41) begin
						pixel_data<= GREEN;end//显示“容易”的绿方块
						
					  else if(pixel_xpos[9:4] >=44 && pixel_xpos[9:4] < 45 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
						pixel_data<= BLUE;end//显示“中等”的黄方块
						
				   	else if(pixel_xpos[9:4] >=46 && pixel_xpos[9:4] < 47 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
						pixel_data<= RED;end//显示“困难”的红方块
            else begin
                  pixel_data <= WHITE; // 其他区域显示背景颜色
              end 
            end
            game_back: begin
                    // 绘制图片
               if((pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH)&& (pixel_ypos >= PIC_Y_START)&&(pixel_ypos < PIC_Y_START + PIC_HEIGHT))
                pixel_data <= rom_rd_data ;  //显示图片
              else begin
                  pixel_data <= WHITE; // 其他区域显示背景颜色
              end
            end
            game: begin
              if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
                  || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) begin
                  pixel_data <= BLUE; // 绘制屏幕边框为蓝色
              end else begin
                //  
                  found_match = 0; // 在每次像素时钟的边缘重置标志
                  for (index_draw = 0; index_draw < MaxSize && !found_match; index_draw = index_draw + 1) begin
                        if(index_draw<SnakeSize)begin
                      if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                          && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) begin
                          pixel_data <= BLACK; // 绘制方块为黑色
                          found_match = 1; // 标记找到匹配，防止将pixel_data设置为WHITE
                      end
                          end
                  end
                  if (!found_match) begin
                      if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                          begin
                              pixel_data<=FOOD_COLOR;
                          end
                      else
                          pixel_data <= WHITE; // 如果没有找到匹配，则绘制背景为白色
                  end
              end
            end
            default: begin
                pixel_data <= BLACK; // 默认背景
            end
      endcase
    end
end

//根据当前扫描点的横纵坐标为ROM地址赋值

always @(posedge pixel_clk)  begin
   if(!sys_rst_n)

         rom_addr <= 14'd0;

     //当横纵坐标位于图片显示区域时，累加ROM地址   

     else if((pixel_ypos >= PIC_Y_START) && (pixel_ypos < PIC_Y_START + PIC_HEIGHT)

         && (pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH))

         rom_addr <= rom_addr + 1'b1;

     //当横纵坐标位于图片区域最后一个像素点时，ROM地址清零   

     else if((pixel_ypos >= PIC_Y_START + PIC_HEIGHT))

         rom_addr <= 14'd0;

 end


 //ROM：存储图片

 blk_mem_gen u_blk_mem_gen (

   .clka(pixel_clk), // input clka

   .ena(rom_rd_en), // input ena

   .wea(wea), // input [3 : 0] wea

   .addra(rom_addr), // input [31 : 0] addra

   .dina(dina), // input [31 : 0] dina

   .douta(rom_rd_data) // output [31 : 0] douta

 );

endmodule 
//gittest