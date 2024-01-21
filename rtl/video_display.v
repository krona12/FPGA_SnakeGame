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
localparam BLOCK_W = 11'd40;                    //������
localparam BLUE    = 24'b00000000_00000000_11111111;    //��Ļ�߿���ɫ ��ɫ
localparam WHITE   = 24'b11111111_11111111_11111111;    //������ɫ ��ɫ
localparam BLACK   = 24'b00000000_00000000_00000000;    //������ɫ ��ɫ

//reg define
reg [10:0] block_x = SIDE_W ;                             //�������ϽǺ�����
reg [10:0] block_y = SIDE_W ;                             //�������Ͻ�������
reg [21:0] div_cnt;                             //ʱ�ӷ�Ƶ������
reg        h_direct;                            //����ˮƽ�ƶ�����1�����ƣ�0������
reg        v_direct;                            //������ֱ�ƶ�����1�����£�0��
reg [1:0]direction;
//wire define   
wire move_en;                                   //�����ƶ�ʹ���źţ�Ƶ��Ϊ100hz
assign move_en = (div_cnt == 22'd742500) ? 1'b1 : 1'b0;
//*****************************************************
//**                    main code
//*****************************************************

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
    end
    else if (key[0] == 0) begin  // ��
        if(!(direction==2'd1))
            direction=2'd0;
    end
    else if (key[1] == 0) begin  // ��
        if(!(direction==2'd0))
             direction=2'd1;
    end
    else if (key[2] == 0) begin  // ��
        if(!(direction==2'd3))
            direction=2'd2;
    end
    else if (key[3] == 0) begin  // ��
        if(!(direction==2'd2))
            direction=2'd3;
    end
    // ʡ�Կյ�else����
end

//ͨ����vga����ʱ�Ӽ�����ʵ��ʱ�ӷ�Ƶ
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 22'd0;
    else begin
        if(div_cnt < 22'd742500) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;                   //������10ms������
    end
end

//�������ƶ����߽�ʱ���ı��ƶ�����
// always @(posedge pixel_clk ) begin         
//     if (!sys_rst_n) begin
//         h_direct <= 1'b1;                       //�����ʼˮƽ�����ƶ�
//         v_direct <= 1'b1;                       //�����ʼ��ֱ�����ƶ�
//     end
//     else begin
//         if(block_x == SIDE_W - 1'b1)            //������߽�ʱ��ˮƽ����
//             h_direct <= 1'b1;               
//         else                                    //�����ұ߽�ʱ��ˮƽ����
//         if(block_x == H_DISP - SIDE_W - BLOCK_W)
//             h_direct <= 1'b0;               
//         else
//             h_direct <= h_direct;
            
//         if(block_y == SIDE_W - 1'b1)            //�����ϱ߽�ʱ����ֱ����
//             v_direct <= 1'b1;                
//         else                                    //�����±߽�ʱ����ֱ����
//         if(block_y == V_DISP - SIDE_W - BLOCK_W)
//             v_direct <= 1'b0;               
//         else
//             v_direct <= v_direct;
//     end
// end

//���ݷ����ƶ����򣬸ı����ݺ�����
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        block_x <= SIDE_W;                     // �����ʼλ�ú�����
        block_y <= SIDE_W;                     // �����ʼλ��������
    end
    else if (move_en) begin
        case (direction)
            2'd0: block_y <= block_y - 1'b1;   // ���������ƶ�
            2'd1: block_y <= block_y + 1'b1;   // ���������ƶ�
            2'd2: block_x <= block_x - 1'b1;   // ���������ƶ�
            2'd3: block_x <= block_x + 1'b1;   // ���������ƶ�
        endcase
    end
end


//����ͬ��������Ʋ�ͬ����ɫ
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) 
        pixel_data <= BLACK;
    else begin
        if(  (pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
          || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W))
            pixel_data <= BLUE;                 //������Ļ�߿�Ϊ��ɫ
        else
        if(  (pixel_xpos >= block_x) && (pixel_xpos < block_x + BLOCK_W)
          && (pixel_ypos >= block_y) && (pixel_ypos < block_y + BLOCK_W))
            pixel_data <= BLACK;                //���Ʒ���Ϊ��ɫ
        else
            pixel_data <= WHITE;                //���Ʊ���Ϊ��ɫ
    end
end

endmodule 