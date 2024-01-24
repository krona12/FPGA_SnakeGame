/*******************************************************
 * FPGA-Based 贪吃蛇
  * School:CSU
 * Class: 自动化 T2101
 * Students: 刘凯-8210211913, 吴森林-8212211224
 * Instructor: 罗旗舞
 *******************************************************/
//状态机切换
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

parameter game_start	= 3'b001;  //游戏界面的开始选项
parameter game_back		= 3'b010;  //游戏界面的返回选项
parameter game			= 3'b100;  //游戏中
reg [2:0]ls;
reg [2:0]ns;
//state_1
always@(posedge pixel_clk or negedge sys_rst_n)begin//之前没写Begin，end
if(sys_rst_n==0)
	ns<=game_start;
else  begin
     
  case(state_1)
    game_start:	if(key[4] ==1)//进入游戏
          ns<=game;
        else if(key[5] == 1)//退出游戏
          ns<=game_start;
        else
          ns<=game_start;
    // game_back:	if(key[4] == 1)//进入游戏
    //       ns<=game;
		// 	 else if(key[5] == 1)//返回菜单
    //       ns<=game_start;
    //     else
    //       ns<=game_back;
    game:		if(key[4] == 1)//游戏
          ns<=game;
        else if(key[5]==1)
          ns<=game_start;
        else
          ns<=game;
    default:
    ns<=game_start;
  endcase
      end
end

always@(posedge pixel_clk )
begin
  state_1<=ns;
end

endmodule