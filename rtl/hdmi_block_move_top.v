/*******************************************************
 * FPGA-Based 贪吃蛇
  * School:CSU
 * Class: 自动化 T2101
 * Students: 刘凯-8210211913, 吴森林-8212211224
 * Instructor: 罗旗舞
 *******************************************************/
//hdmi显示模块

module  hdmi_block_move_top(
    input        sys_clk,
    input        sys_rst_n,
    input       speed_change,
    input       [5:0]key_in,//控制上下左右
 	 
    output       tmds_clk_p,    // TMDS 时钟通道
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS 数据通道
    output [2:0] tmds_data_n,
    output    [5:0]  seg_sel,       // 数码管位选信号
    output    [7:0]  seg_led          // 数码管段选信号
);

//wire define
wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;
wire[2:0]	state_1;//菜单状态
wire [5:0]key;
wire [4:0]speed_useless;
wire [5:0]speed_use;
//数码管部分
wire [5:0]Score;
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
    .speed_change   (speed_use),
    .key            (key),
    .state_1        (state_1),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w),
    .Score          (Score)
    );

//菜单状态
state u_state(
   .pixel_clk      (tx_pclk),
   .sys_rst_n      (sys_rst_n), 
   .key            (key),
   .state_1        (state_1),
   .state_2        (state_2)
   );	  

debounce u_debounce(
   .pixel_clk      (tx_pclk),
   .sys_rst_n      (sys_rst_n), 
   .key_in            (key_in),
   .key_out            (key)
);
debounce speed_debounce(
   .pixel_clk      (tx_pclk),
   .sys_rst_n      (sys_rst_n), 
   .key_in            ({speed_useless,speed_change}),
   .key_out            ({speed_use})
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
 //数码管动态显示模块
seg_led u_seg_led(
    .clk           (tx_pclk),       // 时钟信号
    .rst_n         (sys_rst_n),       // 复位信号

    .data          (Score     ),       // 显示的数值
    .point         (6'b000000),       // 小数点具体显示的位置,高电平有效
    .en            (1),       // 数码管使能信号
    .sign          (0),       // 符号位，高电平显示负号(-)
    
    .seg_sel       (seg_sel),       // 位选
    .seg_led       (seg_led)        // 段选
);
endmodule 