module debounce(
  input             pixel_clk,                  //VGA????
  input             sys_rst_n,                //????
  input       [5:0]key_in,//??????
  output reg [5:0] key_out // ????????
);

parameter DEBOUNCE_TIME = 1000000; // ?????00MHz????????10ms
reg [19:0] counter[5:0]; // ????????
reg [5:0] key_state; // ????????

// ????
integer i;
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        key_out <= 6'b111111; // ???????????
        for (i = 0; i < 6; i = i + 1) begin
            counter[i] <= 0;
            key_state[i] <= 1'b1;
        end
    end else begin
        for (i = 0; i < 6; i = i + 1) begin
            if (key_in[i] != key_state[i]) begin
                // ???????????
                counter[i] <= counter[i] + 1'b1;
                if (counter[i] >= DEBOUNCE_TIME) begin
                    // ?????????????????
                    key_state[i] <= key_in[i];
                    key_out[i] <= key_in[i];
                    counter[i] <= 0; // ?????
                end
            end else begin
                // ?????????????
                counter[i] <= 0;
            end
        end
    end
end

endmodule
