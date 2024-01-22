//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           rgb_display
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:         vga�����ƶ���ʾģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  video_display(
    input             pixel_clk,                  //VGA����ʱ��
    input             sys_rst_n,                //��λ�ź�
    
    input      [10:0] pixel_xpos,               //���ص������
    input      [10:0] pixel_ypos,               //���ص�������   
    input       [3:0]key,//������������
    output reg [23:0] pixel_data                //���ص�����
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //�ֱ���--��
parameter  V_DISP  = 11'd720;                   //�ֱ���--��

localparam SIDE_W  = 11'd40;                    //��Ļ�߿���
localparam BLOCK_W = 11'd20;                    //������
localparam BLUE    = 24'b00000000_00000000_11111111;    //��Ļ�߿���ɫ ��ɫ
localparam WHITE   = 24'b11111111_11111111_11111111;    //������ɫ ��ɫ
localparam BLACK   = 24'b00000000_00000000_00000000;    //������ɫ ��ɫ
localparam GREEN =24'h006400 ;
localparam Crimson = 24'hDC143C;
localparam FOOD_COLOR =Crimson ;
localparam INI_X =11'd640 ;//��ʼλ��
localparam INI_Y =11'd360 ;
localparam StandardF =30'd742500;
localparam speed =1 ;

localparam FOOD_W =11'd20 ;//ʳ���С
localparam FOOD_X=11'd400 ;
localparam FOOD_Y=11'd400 ;

//reg define
reg [10:0] block_x = INI_X ;                             //�������ϽǺ�����
reg [10:0] block_y = INI_Y ;                             //�������Ͻ�������
reg [3:0] SnakeSize=3;//�����߳���
localparam MaxSize =16 ;
reg [10:0] Snake_Array[MaxSize:0][1:0]; // �����ߵ�ÿ�ڵ���������
//food
reg [10:0]Food_Array[1:0];


reg [25:0] div_cnt;                             //ʱ�ӷ�Ƶ������
reg        h_direct;                            //����ˮƽ�ƶ�����1�����ƣ�0������
reg        v_direct;                            //������ֱ�ƶ�����1�����£�0��
reg [1:0]direction;
//wire define   
wire move_en;                                   //�����ƶ�ʹ���źţ�Ƶ��Ϊ100hz
reg MOEN;                                       //�����ƶ�����
assign move_en = (div_cnt == StandardF*10/speed) ? 1'b1 : 1'b0;
//*****************************************************
//**                    main code
//*****************************************************

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        MOEN=0;
    end
    else if (key[0] == 0) begin  // ��
        if(!(direction==2'd1))
            direction=2'd0;
            MOEN=1;
    end
    else if (key[1] == 0) begin  // ��
        if(!(direction==2'd0))
             direction=2'd1;
            MOEN=1;            
    end
    else if (key[2] == 0) begin  // ��
        if(!(direction==2'd3))
            direction=2'd2;
            MOEN=1;
    end
    else if (key[3] == 0) begin  // ��
        if(!(direction==2'd2))
            direction=2'd3;
            MOEN=1;
    end
    // ʡ�Կյ�else����
end

//ͨ����vga����ʱ�Ӽ�����ʵ��ʱ�ӷ�Ƶ
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 22'd0;
    else begin
        if(div_cnt < StandardF*10/speed) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;                   //������10ms������
    end
end
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
//���ݷ����ƶ����򣬸ı����ݺ�����
always @(posedge pixel_clk or negedge sys_rst_n) begin         
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
                Snake_Array[0][1] = Snake_Array[0][1] -BLOCK_W;//����Ҫע���Ǽ�BLOCK_W,֮ǰ��Ϊ1���������غϳ�һ�������ˡ�����Ϊ�����ƶ���drawƵ�ʵ�����
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
                Snake_Array[0][0] = Snake_Array[0][0] -BLOCK_W; // ����Ϊx����
            end
            2'd3:
            begin
                for(index4=MaxSize-1; index4>0; index4=index4-1) begin
                      if(index4<SnakeSize)begin
                    Snake_Array[index4][0] = Snake_Array[index4-1][0]; // ������������
                    Snake_Array[index4][1] = Snake_Array[index4-1][1];
                      end
                end
                Snake_Array[0][0] = Snake_Array[0][0] + BLOCK_W; // ����Ϊx����
            end
        endcase
        //�Ե�ʳ��
        if(Snake_Array[0][0]==Food_Array[0]&&Snake_Array[0][1]==Food_Array[1])
        begin
            SnakeSize=SnakeSize+1;
        end
    end
end


integer index_draw;
reg found_match = 0; // ���һ����־��ָʾ�Ƿ��ҵ�ƥ��

// ����ͬ��������Ʋ�ͬ����ɫ
always @(posedge pixel_clk) begin
    if (!sys_rst_n) begin
        pixel_data <= BLACK;
    end else begin
        if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
            || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) begin
            pixel_data <= BLUE; // ������Ļ�߿�Ϊ��ɫ
        end else begin
          //  
            found_match = 0; // ��ÿ������ʱ�ӵı�Ե���ñ�־
            for (index_draw = 0; index_draw < MaxSize && !found_match; index_draw = index_draw + 1) begin
                  if(index_draw<SnakeSize)begin
                if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                    && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) begin
                    pixel_data <= BLACK; // ���Ʒ���Ϊ��ɫ
                    found_match = 1; // ����ҵ�ƥ�䣬��ֹ��pixel_data����ΪWHITE
                end
                    end
            end
            if (!found_match) begin
                 if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                    begin
                        pixel_data<=FOOD_COLOR;
                    end
                else
                    pixel_data <= WHITE; // ���û���ҵ�ƥ�䣬����Ʊ���Ϊ��ɫ
            end
        end
    end
end



endmodule 