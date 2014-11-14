module datapath(clk, rst, start_addr, end_addr, data_reg_ld_wire_in, i_sel, i_ld, i_clr, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, max_diff_ld, max_diff_clr, i_lte_j, data_lt_min, data_lt_max, max_diff, start_addr_out);


input clk, rst;
input [7:0] start_addr, end_addr, data_reg_ld_wire_in;
input i_sel, i_ld, i_clr, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, max_diff_ld, max_diff_clr;
output i_lte_j, data_lt_min, data_lt_max; 
output [7:0] max_diff;
output [7:0] start_addr_out;

wire [7:0] i_ld_wire_in, i_add_wire, i_wire_out;
wire [7:0] j_wire_out;
wire [7:0] data_reg_wire_out;
wire [7:0] min_mux_wire_out, max_mux_wire_out;
wire [7:0] min_wire_out, max_wire_out;
wire [7:0] sub_wire_out;
	

	// MUX for I
	Mux I_MUX(start_addr, i_add_wire, i_sel, i_ld_wire_in);

	// Register for I
	Register I_REG(clk, rst, i_clr, i_ld, i_ld_wire_in, i_wire_out);

	// Register for Start Address
	Register START_REG(clk, rst, 0, 1, start_addr, start_addr_out);
	
	// Register for J
	Register J_REG(clk, rst, j_clr, j_ld, end_addr, j_wire_out);

	// Adder for I
	Adder I_ADDER(i_wire_out, 8'b00000001, i_add_wire);

	// Compare I & J
	Compare_LTE IJ_COMP(i_wire_out, j_wire_out, i_lte_j);

	// Register for DATA
	Register DATA_REG(clk, rst, data_reg_clr, data_reg_ld, data_reg_ld_wire_in, data_reg_wire_out);

	// MUX for min
	Mux MIN_MUX(8'b11111111, data_reg_wire_out, sel_def_max_min, min_mux_wire_out);

	// MUX for max
	Mux MAX_MUX(8'b00000000, data_reg_wire_out, sel_def_max_min, max_mux_wire_out);
	
	// Register for min
	Register MIN_REG(clk, rst, min_clr, min_ld, min_mux_wire_out, min_wire_out);

	// Register for max
	Register MAX_REG(clk, rst, max_clr, max_ld, max_mux_wire_out, max_wire_out);

	// Comparator for min
	Compare_LTE MIN_COMP(data_reg_wire_out, min_wire_out, data_lt_min);

	// Comparator for max
	Compare_LTE MAX_COMP(max_wire_out, data_reg_wire_out, data_lt_max);

	// Subtractor
	Subtractor MAXMIN_SUB(max_wire_out, min_wire_out, sub_wire_out);

	// Register for max_diff
	Register MAX_DIFF_REG(clk, rst, max_diff_clr, max_diff_ld, sub_wire_out, max_diff); 
	
endmodule


// Mux module
module Mux(Input0, Input1, Sel, Data_out);
	parameter input_size = 8;

	input [input_size-1:0] Input0;
	input [input_size-1:0] Input1;
	input Sel;
	output reg [7:0] Data_out;

	always @ (Sel, Input0, Input1) begin
		if( Sel == 0) begin
			Data_out <= Input0;
		end
		else  begin
			Data_out <= Input1;
		end
	end
endmodule

// Register module
module Register(clk, rst, clr, ld, I, Q);
	parameter reg_width = 8;

	input clk, rst, clr, ld;
	input [reg_width-1:0] I;
	output reg [reg_width-1:0] Q;

	always @ (posedge clk) begin
		if( rst == 1 ) begin
			Q <= 0;		
		end
		else begin
			if( clr == 1 ) begin
				Q <= 0;
			end
			else if( ld == 1 ) begin
				Q <= I;
			end
		end
	end   
endmodule

// Adder module
module Adder(A, B, Result);
	parameter adder_size = 8;
	
	input [adder_size-1:0] A;
	input [adder_size-1:0] B;
	output reg [adder_size-1:0] Result;

	always @ (A, B) begin
		Result <= A + B;
	end
endmodule

// Subtractor module
module Subtractor(A, B, Result);
	parameter sub_size = 8;
	
	input [sub_size-1:0] A;
	input [sub_size-1:0] B;
	output reg [sub_size-1:0] Result;
	always @ (A, B) begin	
		Result <= A - B;
	end
endmodule


// Comparator module
module Compare_LTE(A, B, LTE);
	parameter adder_size = 8;
	
	input [adder_size - 1:0] A;
	input [adder_size-1:0] B;
	output reg LTE;

	always @ (A, B) begin
		
		if(A <= B) begin
			LTE <= 1;
		end
		else begin
			LTE <=0;
		end
	end
endmodule
