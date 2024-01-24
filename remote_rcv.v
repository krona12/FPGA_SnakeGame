
module remote_rcv(
    input                  sys_clk   ,  //系统时钟
    input                  sys_rst_n ,  //系统复位信号，低电平有效
    
    input                  remote_in ,  //红外接收信号
    output    reg          repeat_en ,  //重复码有效信号
    output    reg          data_en   ,  //数据有效信号
    output    reg  [7:0]   data         //红外控制码
    );

//parameter define
parameter  st_idle           = 5'b0_0001;  //空闲状态
parameter  st_start_low_9ms  = 5'b0_0010;  //监测同步码低电平
parameter  st_start_judge    = 5'b0_0100;  //判断重复码和同步码高电平(空闲信号)
parameter  st_rec_data       = 5'b0_1000;  //接收数据
parameter  st_repeat_code    = 5'b1_0000;  //重复码

//reg define
reg    [4:0]    cur_state      ;
reg    [4:0]    next_state     ;

reg    [12:0]   div_cnt        ;  //分频计数器
reg             div_clk        ;  //分频时钟
reg             remote_in_d0   ;  //对输入的红外信号延时打拍
reg             remote_in_d1   ;
reg    [7:0]    time_cnt       ;  //对红外的各个状态进行计数

reg             time_cnt_clr   ;  //计数器清零信号
reg             time_done      ;  //计时完成信号
reg             error_en       ;  //错误信号
reg             judge_flag     ;  //检测出的标志信号 0:同步码高电平(空闲信号)  1:重复码
reg    [15:0]   data_temp      ;  //暂存收到的控制码和控制反码
reg    [5:0]    data_cnt       ;  //对接收的数据进行计数       

//wire define
wire            pos_remote_in  ;  //输入红外信号的上升沿
wire            neg_remote_in  ;  //输入红外信号的下降沿

//*****************************************************
//**                    main code
//*****************************************************

assign  pos_remote_in = (~remote_in_d1) & remote_in_d0;
assign  neg_remote_in = remote_in_d1 & (~remote_in_d0);

//时钟分频,50Mhz/(2*(3124+1))=8khz,T=0.125ms
//75Mhz/(8k*2)-1=4686.5
always @(posedge sys_clk or negedge sys_rst_n  ) begin
    if (!sys_rst_n) begin
        div_cnt <= 12'd0;
        div_clk <= 1'b0;
    end    
    else if(div_cnt == 13'd4686) begin
        div_cnt <= 12'd0;
        div_clk <= ~div_clk;
    end    
    else
        div_cnt <= div_cnt + 12'b1;
end

//对红外的各个状态进行计数
always @(posedge div_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        time_cnt <= 8'b0;
    else if(time_cnt_clr)
        time_cnt <= 8'b0;
    else 
        time_cnt <= time_cnt + 8'b1;
end 

//对输入的remote_in信号延时打拍
always @(posedge div_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        remote_in_d0 <= 1'b0;
        remote_in_d1 <= 1'b0;
    end
    else begin
        remote_in_d0 <= remote_in;
        remote_in_d1 <= remote_in_d0;
    end
end

//状态机
always @ (posedge div_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cur_state <= st_idle;
    else
        cur_state <= next_state ;
end

always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle : begin                           //空闲状态
            if(remote_in_d0 == 1'b0)
                next_state = st_start_low_9ms;
            else
                next_state = st_idle;            
        end
        st_start_low_9ms : begin                  //监测同步码低电平
            if(time_done)
                next_state = st_start_judge;
            else if(error_en)
                next_state = st_idle;
            else
                next_state = st_start_low_9ms;
        end
        st_start_judge : begin                    //判断重复码和同步码高电平(空闲信号)
            if(time_done) begin
                if(judge_flag == 1'b0)
                    next_state = st_rec_data;
                else 
                    next_state = st_repeat_code;
            end
            else if(error_en)
                next_state = st_idle;
            else
                next_state = st_start_judge;
        end
        st_rec_data : begin                       //接收数据
            if(pos_remote_in && data_cnt == 6'd32) 
                next_state = st_idle;
            else
                next_state = st_rec_data;                
        end
        st_repeat_code : begin                    //重复码
            if(pos_remote_in)
                next_state = st_idle;
            else
                next_state = st_repeat_code;    
        end    
        default : next_state = st_idle;
    endcase
end

always @(posedge div_clk or negedge sys_rst_n ) begin 
    if (!sys_rst_n) begin  
        time_cnt_clr <= 1'b0;
        time_done <= 1'b0;
        error_en <= 1'b0;
        judge_flag <= 1'b0;
        data_en <= 1'b0;
        data <= 8'd0;
        repeat_en <= 1'b0;
        data_cnt <= 6'd0;
        data_temp <= 32'd0;
    end
    else begin
        time_cnt_clr <= 1'b0;
        time_done <= 1'b0;
        error_en <= 1'b0;
        repeat_en <= 1'b0;
        data_en <= 1'b0;
        case(cur_state)
            st_idle           : begin
                time_cnt_clr <= 1'b1;
                if(remote_in_d0 == 1'b0)
                    time_cnt_clr <= 1'b0;
            end   
            st_start_low_9ms  : begin                             //9ms/0.125ms = 72
                if(pos_remote_in) begin  
                    time_cnt_clr <= 1'b1;                  
                    if(time_cnt >= 69 && time_cnt <= 75)
                        time_done <= 1'b1;  
                    else 
                        error_en <= 1'b1;
                end   
            end
            st_start_judge : begin
                if(neg_remote_in) begin   
                    time_cnt_clr <= 1'b1;   
                    //重复码高电平2.25ms 2.25/0.125 = 18      
                    if(time_cnt >= 15 && time_cnt <= 20) begin
                        time_done <= 1'b1;
                        judge_flag <= 1'b1;
                    end    
                    //同步码高电平4.5ms 4.5/0.125 = 36
                    else if(time_cnt >= 33 && time_cnt <= 38) begin
                        time_done <= 1'b1;
                        judge_flag <= 1'b0;                        
                    end
                    else
                        error_en <= 1'b1;
                end                       
            end
            st_rec_data : begin                                  
                if(pos_remote_in) begin
                    time_cnt_clr <= 1'b1;
                    if(data_cnt == 6'd32) begin
                        data_en <= 1'b1;
                        data_cnt <= 6'd0;
                        data_temp <= 16'd0;
                        if(data_temp[7:0] == ~data_temp[15:8])    //校验控制码和控制反码
                            data <= data_temp[7:0];
                    end
                end
                else if(neg_remote_in) begin
                    time_cnt_clr <= 1'b1;
                    data_cnt <= data_cnt + 1'b1;    
                    //解析控制码和控制反码        
                    if(data_cnt >= 6'd16 && data_cnt <= 6'd31) begin 
                        if(time_cnt >= 2 && time_cnt <= 6) begin  //0.565/0.125 = 4.52
                            data_temp <= {1'b0,data_temp[15:1]};  //逻辑"0"
                        end
                        else if(time_cnt >= 10 && time_cnt <= 15) //1.69/0.125 = 13.52
                            data_temp <= {1'b1,data_temp[15:1]};  //逻辑"1"
                    end
                end
            end
            st_repeat_code : begin                                
                if(pos_remote_in) begin                           
                    time_cnt_clr <= 1'b1;
                    repeat_en <= 1'b1;
                end
            end
            default : ;
        endcase
    end
end

endmodule