module Top_Circuit_tb();

reg clk, rst, start;
reg [7:0] start_addr, end_addr;
wire [7:0] max_diff;
wire busy;
wire scl, sda;

	Top_Circuit T1 (clk, rst, start, start_addr, end_addr, max_diff, busy);

	initial
	begin
		clk = 1'b0;
		rst = 1'b1;
		start = 1'b1;
		#100
		rst = 1'b0;
		start = 1'b1;
		start_addr = 0;
		end_addr = 4;
	end
	
	always #10 clk = ~clk;

endmodule