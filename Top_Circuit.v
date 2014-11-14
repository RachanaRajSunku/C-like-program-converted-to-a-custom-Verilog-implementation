module Top_Circuit(clk, rst, start, start_addr, end_addr, max_diff, busy);

input clk, rst, start;
input [7:0] start_addr, end_addr;
output reg [7:0] max_diff;
output reg busy;

wire [7:0] wire_max_diff;
wire wire_busy;
wire wire_scl, wire_sda;

	fsmd F1(clk, rst, start, start_addr, end_addr, wire_busy, wire_max_diff, wire_scl, wire_sda);
	mem_i2c S1(rst, clk, wire_scl, wire_sda);

	always @(posedge clk)
	begin
		max_diff <= wire_max_diff;
		busy <= wire_busy;
	end
endmodule

