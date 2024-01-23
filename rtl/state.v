module state(
  input             pixel_clk,                  //VGA驱动时钟
  input             sys_rst_n,                //复位信号
  input       [5:0]key,//控制上下左右
	input   wire flag,
	output	reg[2:0]		state_1,
	output	reg[1:0]		state_2
);	   

parameter one	= 2'b01;			//难度为1
parameter two 	= 2'b10;			//难度为2
parameter three = 2'b11;			//难度为3

parameter face_start 	= 3'b001;	//初始界面的开始选项
parameter face_options 	= 3'b010;  //初始界面的设置选项
parameter options		= 3'b011;  //难度设置界面
parameter game_start	= 3'b100;  //游戏界面的开始选项
parameter game_back		= 3'b101;  //游戏界面的返回选项
parameter game			= 3'b111;  //游戏中
//state_1
always@(posedge pixel_clk or negedge sys_rst_n)
if(sys_rst_n==0)
	state_1<=game_start;
else     
  case(state_1)
    game_start:	if(key[4] ==1)//进入游戏
          state_1<=game;
        else if(key[5] == 1)//退出游戏
          state_1<=game_back;
        else
          state_1<=game_start;
    game_back:	if(key[4] == 1)//主菜单
          state_1<=game_start;
			 else if(key[5] == 1)//返回游戏
          state_1<=game;
        else
          state_1<=game_back;
    game:		if(key[4] == 1)//主菜单
          state_1<=game_start;
			 else if(key[5] == 1||flag==1)//退出游戏
          state_1<=game_back;
        else  
          state_1<=game;
  endcase
endmodule