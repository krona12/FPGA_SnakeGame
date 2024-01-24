/*******************************************************
 * FPGA-Based 贪吃蛇
  * School:CSU
 * Class: 自动化 T2101
 * Students: 刘凯-8210211913, 吴森林-8212211224
 * Instructor: 罗旗舞
 *******************************************************/
//随机数生成器模块
module rng_custom_range (
    input clk,
    input reset,
    input enable,//使能信号
    input [9:0] min_value,
    input [9:0] max_value, // 假设最大值不超过1023
    output reg [9:0] random_num // 输出随机数，范围0到max_value-1
);

reg [9:0] raw_random; // 内部10位随机数
wire feedback = raw_random[8] ^ raw_random[5]; // LFSR反馈

always @(posedge clk or posedge reset) begin
    if (reset) begin
        raw_random <= 10'd1; // 避免初始全0状态
    end else if(enable)begin
        raw_random <= {raw_random[9:0], feedback}; // 更新LFSR
    end
end

// 映射到指定范围
always @(posedge clk) begin
    if (random_num<=min_value||random_num>=max_value) begin
        //raw_ <= {raw_random[9:0], feedback}; // 更新LFSR
    end else if(enable)begin
        // 调整随机数到指定范围
        random_num <=min_value+ (raw_random % (max_value-min_value));//这里注意限制num范围
    end
end

endmodule
