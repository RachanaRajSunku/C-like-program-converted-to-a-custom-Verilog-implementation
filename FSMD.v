module fsmd(clk, rst, start, start_addr, end_addr, busy, max_diff, scl, sda);

	input clk, rst, start;
	input [7:0] start_addr, end_addr;
	output busy;
	output [7:0] max_diff;

	wire i_sel, i_ld, i_clr, i_lte_j, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, data_lt_min, data_lt_max, max_diff_ld, max_diff_clr;

	wire [7:0] max_diff, data_reg_ld_wire_in, start_addr_out;
	output scl, sda;

	controller C1 (clk, rst, start, i_lte_j, data_lt_min, data_lt_max, max_diff, start_addr_out, i_sel, i_ld, i_clr, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, max_diff_ld, max_diff_clr, busy, data_reg_ld_wire_in, scl, sda);

	datapath D1 (clk, rst, start_addr, end_addr, data_reg_ld_wire_in, i_sel, i_ld, i_clr, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, max_diff_ld, max_diff_clr, i_lte_j, data_lt_min, data_lt_max,  max_diff, start_addr_out);

endmodule
