
//红外线解码模块
//最开始用的是持续高电平，导致按键冲突，比如按下左，其他就按不了
module decode_rcv(
    input sys_clk,
    input sys_rst_n,
    input [7:0]data,
    output reg [6:0]key2
);

reg [12:0] counter; // 
reg pulse_start; // 标记是否开始计数

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        key2 <= 7'b0;
        counter <= 0;
        pulse_start <= 0;
    end else begin
        // 检测data并启动脉冲
        if (pulse_start == 0) begin
            case (data)
                8'h46: begin key2 <= 7'b0000001; pulse_start <= 1; end
                8'h15: begin key2 <= 7'b0000010; pulse_start <= 1; end
                8'h44: begin key2 <= 7'b0000100; pulse_start <= 1; end
                8'h43: begin key2 <= 7'b0001000; pulse_start <= 1; end
                8'h42: begin key2 <= 7'b0010000; pulse_start <= 1; end
                8'h4a: begin key2 <= 7'b0100000; pulse_start <= 1; end
                8'h40: begin key2 <= 7'b1000000; pulse_start <= 1; end
                default: begin key2 <= 7'b0; end
            endcase
        end
        
        // 计数保持脉冲
        if (pulse_start) begin//1ms脉冲
            if (counter < 5000) begin
                counter <= counter + 1;
            end else begin
                pulse_start <= 0;
                counter <= 0;
                key2 <= 7'b0; // 保持时间结束后清零key2
            end
        end
    end
end

endmodule

