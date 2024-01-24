gui_open_window Wave
gui_sg_create pll2_group
gui_list_add_group -id Wave.1 {pll2_group}
gui_sg_addsignal -group pll2_group {pll2_tb.test_phase}
gui_set_radix -radix {ascii} -signals {pll2_tb.test_phase}
gui_sg_addsignal -group pll2_group {{Input_clocks}} -divider
gui_sg_addsignal -group pll2_group {pll2_tb.CLK_IN1}
gui_sg_addsignal -group pll2_group {{Output_clocks}} -divider
gui_sg_addsignal -group pll2_group {pll2_tb.dut.clk}
gui_list_expand -id Wave.1 pll2_tb.dut.clk
gui_sg_addsignal -group pll2_group {{Status_control}} -divider
gui_sg_addsignal -group pll2_group {pll2_tb.RESET}
gui_sg_addsignal -group pll2_group {pll2_tb.LOCKED}
gui_sg_addsignal -group pll2_group {{Counters}} -divider
gui_sg_addsignal -group pll2_group {pll2_tb.COUNT}
gui_sg_addsignal -group pll2_group {pll2_tb.dut.counter}
gui_list_expand -id Wave.1 pll2_tb.dut.counter
gui_zoom -window Wave.1 -full
