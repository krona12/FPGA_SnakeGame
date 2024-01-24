/*******************************************************
 * FPGA-Based 贪吃蛇
  * School:CSU
 * Class: 自动化 T2101
 * Students: 刘凯-8210211913, 吴森林-8212211224
 * Instructor: 罗旗舞
 *******************************************************/



module  video_display(
    input             pixel_clk,                  //VGA驱动时钟
    input             sys_rst_n,                //复位信号
    input      [5:0]   speed_change,
    input      [10:0] pixel_xpos,               //像素点横坐标
    input      [10:0] pixel_ypos,               //像素点纵坐标   
    input       [5:0]key,//控制上下左右
    input	 [2:0]	state_1,//菜单状态
    output reg [23:0] pixel_data                //像素点数据
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //分辨率--行
parameter  V_DISP  = 11'd720;                   //分辨率--列

localparam SIDE_W  = 11'd40;                    //屏幕边框宽度
localparam BLOCK_W = 11'd20;                    //方块宽度
localparam BLUE    = 24'b00000000_00000000_11111111;    // 蓝色
localparam WHITE   = 24'b11111111_11111111_11111111;    // 白色
localparam BLACK   = 24'b00000000_00000000_00000000;    // 黑色
localparam RED    = 24'b11111111_00000000_00000000; // 红色
localparam GREEN  = 24'b00000000_11111111_00000000; // 绿色
localparam Crimson = 24'hDC143C;//赤红色
//定义各种实例化颜色
localparam FOOD_COLOR =Crimson ;
localparam SNAKE_COLOR =GREEN ;
localparam CHAR_COLOR =BLACK ;
localparam BACKGROUND_COLOR =WHITE ;
//定义初始位置，汉字大小
localparam INI_X =11'd640 ;//初始位置
localparam INI_Y =11'd320 ;
localparam StandardF =20'd742500;
localparam HanZiSize =32 ;


//定义图片              
localparam PIC_X_START = 11'd1;      //图片起始点横坐标
localparam PIC_Y_START = 11'd1;      //图片起始点纵坐标
localparam PIC_WIDTH   = 11'd100;    //图片宽度
localparam PIC_HEIGHT  = 11'd100;    //图片高度

//定义食物
localparam FOOD_W =11'd20 ;//食物大小
localparam FOOD_X=11'd360 ;
localparam FOOD_Y=11'd400 ;
reg [10:0]Food_Array[1:0];
reg FoodGene;
    //定义食物随机数
wire  [9:0]RandomX;
wire [9:0]RandomY;

//定义三个状态
parameter game_start	= 3'b001;  //游戏界面的开始选项
parameter game_back		= 3'b010;  //游戏界面的返回选项
parameter game			= 3'b100;  //游戏中
//reg define
reg   [13:0]  rom_addr  ;  //ROM地址
reg [10:0] block_x = INI_X ;                             //方块左上角横坐标
reg [10:0] block_y = INI_Y ;                             //方块左上角纵坐标

//定义蛇
reg [3:0] SnakeSize=3;//定义蛇长度
localparam MaxSize =10 ;//16
reg [10:0] Snake_Array[MaxSize-1:0][1:0]; // 定义蛇的每节的坐标数组
reg [1:0]speed=1;

//定义计数，用于更改蛇的速度
reg [22:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：右移
reg [1:0]direction;

//定义ROM
wire          rom_rd_en ;  //ROM读使能信号
wire  [23:0]  rom_rd_data ;//ROM数据

//定义使能端
wire move_en;                                   //方块移动使能信号，频率为100hz
reg MOEN;                                       //按键移动是能
reg GAME_EN=0;//游戏使能
assign move_en = (div_cnt == StandardF*10/speed) ? 1'b1 : 1'b0;//移动速度使能标志
assign  rom_rd_en = 1'b1;                  //读使能拉高，即一直读ROM数据

//随机数生成
//rng_custom_range Ran1(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd1000,RandomX);
//rng_custom_range Ran2(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd600,RandomY);

//随机数生成2

// 随机数生成器作为随机种子
reg  [10:0] random_seed_x=11'd135;
reg  [10:0] random_seed_y=11'd246;
reg generate_food_signal=0;
// 每次需要生成食物时更新随机种子
always @(posedge pixel_clk) begin
    random_seed_x <= (random_seed_x + 1'b1) ^ {3'b101, random_seed_x[10:3]}; // LFSR逻辑
    random_seed_y <= (random_seed_y + 1'b1) ^ {3'b010, random_seed_y[10:3]}; // 
end
// 使用随机种子生成食物位置


//按键切换
always @(posedge pixel_clk) 
begin
        if (!sys_rst_n||dead) begin
            MOEN=0;direction=0;
        end
        if(GAME_EN==1)//游戏进入才能进行更改方向，防止游戏进入之前就有初速以及方向
        begin
            if (key[0] == 1) 
                begin  // 上
                    if(!(direction==1))
                        begin
                            direction=0;
                        end
                    if(direction==1)
                        begin   
                            direction=direction;
                        end
                    if(Snake_Array[0][1]==Snake_Array[1][1]+BLOCK_W)//蛇头在下，不允许向上
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
            else if (key[1] == 1) 
                begin  // 下
                    if(!(direction==0))
                        begin
                            direction=1;
                        end
                    if(direction==0)
                        begin
                            direction=direction;
                        end
                    if(Snake_Array[0][1]==Snake_Array[1][1]-BLOCK_W)//蛇头在上，不允许向下
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
            else if (key[2] == 1) 
                begin  // 左
                    if(MOEN==0)//初始不能往左
                    begin
                        direction=3;
                    end
                    else
                    begin
                        if(!(direction==3))
                            begin
                                direction=2;
                            end
                        if(direction==3)
                            begin
                                direction=direction;
                            end
                        if(Snake_Array[0][0]==Snake_Array[1][0]+BLOCK_W)//蛇头在右，不允许向左
                            begin
                                direction=direction;
                            end
                    end
                    MOEN=1;
                end
            else if (key[3] == 1) 
                begin  // 右
                    if(!(direction==2'd2))
                    begin
                       direction=2'd3;
                    end
                    if(direction==2'd2)
                    begin
                        direction=2'd2;
                    end
                    if(Snake_Array[0][0]==Snake_Array[1][0]-BLOCK_W)//蛇头在左，不允许向右
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
        end
end

//通过对vga驱动时钟计数，实现时钟分频，从而实现速度定义
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 0;
    else begin
        if(div_cnt < StandardF*10/speed) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 0;                   //计数达上限后清零
    end
end

//切换速度
always @(posedge speed_change[0]) begin
    if(speed<3)
    begin
        speed=speed+1;
    end
    else if(speed)
    begin
        speed=1;
    end
    else begin
        speed=speed;
    end
end

//定义一堆临时变量，珍妮天的verilog，不能直接创建
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
integer index5;//判断相撞死亡标志
reg dead=0;//死亡标志

//蛇移动模块，根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk ) begin  
    //    应该放到EN外面，否则会导致跳转不出死亡界面之外
    //切换则死亡逻辑变0
    if(state_1==game_start)
        begin
            dead=0;
        end
    if(!dead)  
        begin
            if (!sys_rst_n||!GAME_EN) 
                begin
                    SnakeSize=3;
                    for(index0=0; index0<MaxSize; index0=index0+1) //因为for循环的上限不能设为变量（不可综合），只能用定值，可对下标进行判断是否符合界限，从而实现扫描
                        begin
                            if(index0<SnakeSize)
                                begin
                                    Snake_Array[index0][0] = INI_X - index0 * BLOCK_W;
                                    Snake_Array[index0][1] = INI_Y;
                                end
                            else
                            begin
                                Snake_Array[index0][0] = 0;
                                Snake_Array[index0][1] = 0;
                            end
                        end
                    Food_Array[0] <= 11'd360; // 假设的初始X坐标
                    Food_Array[1] <= 11'd400; // 假设的初始Y坐标
                end
            if (move_en&&MOEN&&GAME_EN) 
                begin
                    case (direction)//根据方向的不同，进行不同的移位策略
                        2'd0:
                        begin
                            for(index1=MaxSize-1; index1>0; index1=index1-1) begin//采用for循环的形式，从后面往前面递进
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
                    //相撞死亡逻辑
                    for(index5=1;index5<MaxSize&&dead==0; index5=index5+1) begin
                                if(index5<SnakeSize)
                                    begin
                                        if(Snake_Array[0][0]==Snake_Array[index5][0]&&Snake_Array[0][1]==Snake_Array[index5][1])                                  
                                        //if((Snake_Array[0][0]>=Snake_Array[index5][0])&&(Snake_Array[0][0]<Snake_Array[index5][0]+SnakeSize)&&(Snake_Array[0][1]>=Snake_Array[index5][1])&&(Snake_Array[0][1]<Snake_Array[index5][1]+SnakeSize))
                                            dead=1;
                                    end
                                end
                    if(((Snake_Array[0][0] < SIDE_W) || (Snake_Array[0][0] >= H_DISP - SIDE_W)|| (Snake_Array[0][1] < SIDE_W) || (Snake_Array[0][1] >= V_DISP - SIDE_W))&&dead==0)
                        begin
                            dead=1;
                        // GAME_EN=0;
                        end
                    //吃到食物,食物更新逻辑        
                    if((Snake_Array[0][0]>=Food_Array[0])&&(Snake_Array[0][0]<Food_Array[0]+FOOD_W)&&(Snake_Array[0][1]>=Food_Array[1])&&(Snake_Array[0][1]<Food_Array[1]+FOOD_W))
                        begin
                            if(SnakeSize<MaxSize)
                            begin
                                SnakeSize=SnakeSize+1;
                            end
                            else 
                            begin
                                SnakeSize=MaxSize;
                            end
                            //     // 生成新的食物位置
                            // Food_Array[0]=100+((Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2+234)%((1200-100)/20))*20;
                            // Food_Array[1]=100+((Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+Food_Array[0]+123)%((600-100)/20))*20;
                        
                            Food_Array[0] <= 40 + ((Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2+random_seed_x + 234) % ((1240 - 40) / 20)) * 20;
                            Food_Array[1] <= 40 + ((Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+random_seed_y + 123) % ((680 - 40) / 20)) * 20;
                        end
                end
        end
end

//游戏结束字符
localparam array_gameover_x = 640-2*HanZiSize;//字符x坐标
localparam array_gameover_y = 360-1*HanZiSize;//字符y坐标
localparam size_gameover =4 ;
reg     [159:0] array_gameover    [31:0]  ;   //字符宽160 ，高32
//字符“游戏结束”
always@(posedge pixel_clk)
    begin
        array_gameover[0] <= 128'h00000000000000000000000000000000;
        array_gameover[1] <= 128'h00000000000000000000000000000000;
        array_gameover[2] <= 128'h003007000000e0000003c00000003c00;
        array_gameover[3] <= 128'h1e3c0f800000f0000003e00000003e00;
        array_gameover[4] <= 128'h0f1e0f000000f7000183c000381c3c00;
        array_gameover[5] <= 128'h0f9f0e000000f7c001e3c0003ffe7800;
        array_gameover[6] <= 128'h078f1e180018f3e001e3c0003c1e7800;
        array_gameover[7] <= 128'h078e1c3c003cf1f003c3c1c03c1c7018;
        array_gameover[8] <= 128'h03c7dffe7ffef0f003c3c3e03dfc703c;
        array_gameover[9] <= 128'h00fff800383cf07803fffff03dfcfffe;
        array_gameover[10] <= 128'h71fc38380038703c0383c0003ddce0e0;
        array_gameover[11] <= 128'h7d9c7ffc00787ffe0703c0003dddf0e0;
        array_gameover[12] <= 128'h3d9c7e7c307fffc0070380003dddf1e0;
        array_gameover[13] <= 128'h1f9cc0f03c7ff8600e0380003dddf1e0;
        array_gameover[14] <= 128'h1f9fe3e01e7078700e0380383ddfb1c0;
        array_gameover[15] <= 128'h031de3c00ff078f80c03807c3ddf31c0;
        array_gameover[16] <= 128'h073dc3c007f038f83ffffffe3ddf39c0;
        array_gameover[17] <= 128'h073dc3c003e039f03c07e0003ddc3bc0;
        array_gameover[18] <= 128'h0739c3dc01e03fe00007e0003fdc3b80;
        array_gameover[19] <= 128'h0e39fffe01f03fc0000770003f9c1f80;
        array_gameover[20] <= 128'h7e39fbc003f83f80000f78003f9c1f80;
        array_gameover[21] <= 128'h7e39c3c003f81f0c000f38003ff81f00;
        array_gameover[22] <= 128'h3e71c3c007fc1e0c001e3c003ff80f00;
        array_gameover[23] <= 128'h1e71c3c0073c3f0c001e1e00373e1f00;
        array_gameover[24] <= 128'h1ef1c3c00e1c7f8c003c0f000f1e3f80;
        array_gameover[25] <= 128'h1ee3c3c01e1df7cc00780f800e0e3fc0;
        array_gameover[26] <= 128'h1de383c01c03e3fc00f007e01e0efbf0;
        array_gameover[27] <= 128'h1dff83c0380783fc03e003f83c05e1f8;
        array_gameover[28] <= 128'h1f9f9fc0701f01fc078001fe7803c0fe;
        array_gameover[29] <= 128'h070f0780e03c007e1f0000fe700f807e;
        array_gameover[30] <= 128'h060c03800030001e78000038401e0018;
        array_gameover[31] <= 128'h00000000000000000000000000000000;
    end
 
integer index_draw;
reg found_match = 0; // 添加一个标志来指示是否找到匹配

// 给不同的区域绘制不同的颜色
always @(posedge pixel_clk) 
begin
    case (state_1)
        game_start: begin
            GAME_EN=0;
                // 绘制图片
            if((pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH)&& (pixel_ypos >= PIC_Y_START)&&(pixel_ypos < PIC_Y_START + PIC_HEIGHT))
                pixel_data <= rom_rd_data ;  //显示图片
            else
                begin
                    pixel_data <= BACKGROUND_COLOR; // 其他区域显示背景颜色
                end
        end
        // game_back: begin
        //     GAME_EN=0;
        //   if(pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22&& char[char_y][159-char_x] == 1'b1) begin
        // 			pixel_data<= BLACK; end//显示“请选择难度” 字符
                    
        // 		  else if(pixel_xpos[9:4] >=42 && pixel_xpos[9:4] < 43 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41) begin
        // 			pixel_data<= GREEN;end//显示“容易”的绿方块
                    
        // 		  else if(pixel_xpos[9:4] >=44 && pixel_xpos[9:4] < 45 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
        // 			pixel_data<= BLUE;end//显示“中等”的黄方块
                    
        // 	   	else if(pixel_xpos[9:4] >=46 && pixel_xpos[9:4] < 47 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
        // 			pixel_data<= RED;end//显示“困难”的红方块
        // else begin
        //       pixel_data <= BACKGROUND_COLOR; // 其他区域显示背景颜色
        //   end 
        // end

        game: begin
            GAME_EN=1;
            if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
                || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) 
                begin
                    pixel_data <= BLUE; // 绘制屏幕边框为蓝色
                end 
            else 
                begin 
                    found_match = 0; // 在每次像素时钟的边缘重置标志
                    for (index_draw =MaxSize-1; index_draw>=0 && !found_match; index_draw = index_draw-1)
                        begin
                            if(index_draw<SnakeSize)
                            begin
                                if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                                    && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) 
                                    begin
                                        pixel_data <= SNAKE_COLOR; // 绘制蛇
                                        found_match = 1; // 标记找到匹配，防止将pixel_data设置为WHITE
                                    end
                                    
                                    //绘制背景
                            end
                        end
                    //绘制食物
                    if(!found_match)
                    begin
                        if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                        begin
                            pixel_data<=FOOD_COLOR;
                            found_match = 1;
                        end
                         else
                            pixel_data <= BACKGROUND_COLOR; // 如果没有找到匹配，则绘制背景为白色
                    end
                end

                    // if (!found_match) 
                    //    begin
                    //         if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                    //             begin
                    //                 pixel_data<=FOOD_COLOR;
                    //             end
                    //         else
                    //             pixel_data <= BACKGROUND_COLOR; // 如果没有找到匹配，则绘制背景为白色
                    //     end

            //死亡提示
            if(dead==1)
                begin
                    if(pixel_ypos-array_gameover_y>=0&&pixel_ypos-array_gameover_y<32&&size_gameover*HanZiSize-pixel_xpos+array_gameover_x-1>=0&&size_gameover*HanZiSize-pixel_xpos+array_gameover_x-1<size_gameover*HanZiSize)
                    begin
                    
                    if(array_gameover[pixel_ypos-array_gameover_y][size_gameover*HanZiSize-pixel_xpos+array_gameover_x-1])
                    begin
                        pixel_data<=CHAR_COLOR;
                    end
                    end
                    // GAME_EN=0;
                end
        end
    endcase
end

//根据当前扫描点的横纵坐标为ROM地址赋值

always @(posedge pixel_clk)
begin
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