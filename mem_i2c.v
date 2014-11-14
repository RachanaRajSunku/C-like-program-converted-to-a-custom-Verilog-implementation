// mem_i2c.v
// I2C Memory Module

// -------------------------------------------------------------------------------------------------
// Copyright (c) 2012 Susan Lysecky, University of Arizona
// Permission to copy is granted provided that this header remains
// intact. This software is provided with no warranties.
// -------------------------------------------------------------------------------------------------

module mem_i2c(rst, clk, SCL, SDA);

	// memory i/o
	input rst, clk, SCL;
	inout SDA;

	// constants
	parameter 	DEVICE_ID 	= 8'b01010001; 	// memory's device id (bit 8 is a don't care)
	parameter	READ_BIT 	= 1'b1;        	// indicates read operation
	parameter	WRITE_BIT 	= 1'b0; 	// indicates write operation
	parameter	ACK_COND 	= 1'b0;
	parameter	NO_ACK_COND 	= 1'b1;

	// declare memory, memory parameters, initialize memory
	parameter	MemSize 	= 256;
	parameter	MemWidth 	= 8;
	parameter	FileName 	= "MemA.txt";

	reg [MemWidth-1:0] MEMORY [0:MemSize-1];

	initial begin
		$readmemh(FileName, MEMORY);
	end
	
	// setup databus (SDA)
	assign SDA = SDA_oe ? SDA_data : 1'bz;

	// internal variables
	reg [7:0] addr;
	reg [MemWidth-1:0] data;
	reg [5:0] State;	
	reg [5:0] ReturnState;	
	reg [3:0] Index;
	reg SDA_data;
	reg SDA_oe;
	reg SDA_DFF;

	   
	// switch stmt constants 
	parameter START1_WAIT		= 0;
	parameter START1_FIND		= 1;
	parameter GET_ID1		= 2;
	parameter GET_WRITE_BIT   	= 3;
	parameter SEND_ACK1		= 4;
	parameter SEND_ACK1B		= 5;
	parameter GET_WORD_ADDR		= 6;
	parameter SEND_ACK2		= 7;
	parameter SEND_ACK2B		= 8;
	parameter START2_WAIT		= 9;
	parameter GET_ID2		= 10;
	parameter GET_WRITE_DATA	= 11;
	parameter SEND_ACK3		= 12;
	parameter SEND_ACK3B		= 13;
	parameter GET_READ_BIT		= 14;
	parameter SEND_ACK4 		= 15;
	parameter SEND_MEM_DATA		= 16;
	parameter MASTER_ACK		= 17;
	parameter MASTER_ACK2		= 18;
	parameter STOP_WAIT   		= 19;
	parameter STOP_FIND		= 20;
	parameter N2P_SCL_NEGEDGE	= 21;
	parameter N2P_SCL_POSEDGE	= 22;
	parameter P2N_SCL_NEGEDGE	= 23;
	parameter P2N_SCL_POSEDGE	= 24;
	
	// -----------------------------------------------------     
	// 1 process memory implemenation
	// -----------------------------------------------------     

	always@( posedge rst, posedge clk ) begin
		if( rst == 1 ) begin
			State <= START1_WAIT;
			Index <= 0;
			SDA_oe <= 0;
			SDA_data <= 0;
		end
		else begin
		
			case( State )

				START1_WAIT: begin				
					SDA_oe <= 0;
					SDA_data <= 0;

					if( SCL == 1 && SDA == 1 ) begin
						State <= START1_FIND;
					end
					else begin
						State <= START1_WAIT;
					end
				end

				START1_FIND: begin
					SDA_oe <= 0;
					SDA_data <= 0;

					if( SCL == 1 && SDA == 0 ) begin
						Index <= 6;
						ReturnState <= GET_ID1;
						State <= N2P_SCL_NEGEDGE;
					end
					else if (SCL == 1 && SDA == 1 ) 
						State <= START1_FIND;
					else
						State <= START1_WAIT;
					end

				N2P_SCL_NEGEDGE: begin
					if( SCL == 0 ) begin
						State <= N2P_SCL_POSEDGE;
					end
					else begin
						State <= N2P_SCL_NEGEDGE;
					end
				end

				N2P_SCL_POSEDGE: begin
					if( SCL == 1 ) begin
						SDA_DFF <= SDA;
						State <= ReturnState;
					end
					else begin
						State <= N2P_SCL_POSEDGE;
					end
				end

				GET_ID1: begin	
					SDA_oe <= 0;
					SDA_data <= 0;
					Index <= Index - 1;

					if( SDA == DEVICE_ID[Index] ) begin
						if( Index == 0 ) begin
							ReturnState <= GET_WRITE_BIT;
							State <= N2P_SCL_NEGEDGE;
						end
						else begin
							ReturnState <= GET_ID1;										
							State <= N2P_SCL_NEGEDGE;
						end
					end
					else begin
						State <= STOP_WAIT;
					end

				end

				GET_WRITE_BIT: begin	
					SDA_oe <= 0;
					SDA_data <= 0;

					if( SDA == WRITE_BIT ) begin
						ReturnState <= SEND_ACK1;
						State <= P2N_SCL_NEGEDGE;
					end					
					else begin
						State <= STOP_WAIT;
					end

				end

				SEND_ACK1: begin	
					SDA_oe <= 1;
					SDA_data <= ACK_COND;
					ReturnState <= SEND_ACK1B;
					State <= P2N_SCL_POSEDGE;
				end
				
				SEND_ACK1B: begin	
					SDA_oe <= 0;
					SDA_data <= 0;
					Index <= 7;
					ReturnState <= GET_WORD_ADDR;
					State <= N2P_SCL_POSEDGE;
				end

				P2N_SCL_POSEDGE: begin
					if( SCL == 0 ) begin
						State <= P2N_SCL_POSEDGE;
					end
					else begin
						State <= P2N_SCL_NEGEDGE;
					end
				end

				P2N_SCL_NEGEDGE: begin
					if( SCL == 0) begin
						State <= ReturnState;
					end
					else begin
						State <= P2N_SCL_NEGEDGE;
					end
				end

				GET_WORD_ADDR: begin	
					SDA_oe <= 0;
					SDA_data <= 0;
					addr[Index] <= SDA;
					Index <= Index - 1;

					if( Index == 0) begin
						ReturnState <= SEND_ACK2;
						State <= P2N_SCL_NEGEDGE;
					end
					else begin
						ReturnState <= GET_WORD_ADDR;
						State <= N2P_SCL_NEGEDGE;
					end
				end
				
				SEND_ACK2:  begin	
					SDA_oe <= 1;
					SDA_data <= ACK_COND;
					ReturnState <= SEND_ACK2B;
					State <= P2N_SCL_POSEDGE;
				end

				SEND_ACK2B:  begin	
					SDA_oe <= 0;
					SDA_data <= 0;
					Index <= 7;
					ReturnState <= START2_WAIT;
					State <= N2P_SCL_POSEDGE;
				end
			
				START2_WAIT: begin  
					SDA_oe <= 0;
					SDA_data <= 0;
					SDA_DFF <= SDA;

					if( SCL == 1 && SDA == SDA_DFF ) begin
						data[7] <= SDA;
						Index <= 6;
						State <= START2_WAIT;					
					end
					else if( SCL == 1 && SDA != SDA_DFF ) begin
						if(SDA == 0) begin
							Index <= 6;
							ReturnState <= GET_ID2;
							State <= N2P_SCL_NEGEDGE;
						end
						else begin
							State <= START1_WAIT;
						end
					end
					else begin
						ReturnState <= GET_WRITE_DATA;
						State <= N2P_SCL_POSEDGE;
					end
				end				

				GET_WRITE_DATA: begin	
					SDA_oe <= 0;
					SDA_data <= 0;
					data[Index] <= SDA;
					Index <= Index - 1;

					if( Index == 0 ) begin
						ReturnState <= SEND_ACK3;
						State <= P2N_SCL_NEGEDGE;
					end
					else begin
						ReturnState <= GET_WRITE_DATA;
						State <= N2P_SCL_NEGEDGE;
					end
				end
				
				SEND_ACK3: begin	
					MEMORY[addr] <= data;
					SDA_oe <= 1;
					SDA_data <= ACK_COND;
					ReturnState <= SEND_ACK3B;
					State <= P2N_SCL_POSEDGE;
				end
				
				SEND_ACK3B: begin	
					SDA_oe <= 0;
					SDA_data <= 0;
					ReturnState <= STOP_WAIT;
					State <= N2P_SCL_POSEDGE;
				end

				GET_ID2: begin
					SDA_oe <= 0;
					SDA_data <= 0;
					Index <= Index - 1;					

					if( SDA == DEVICE_ID[Index] ) begin
						if( Index == 0 ) begin
							ReturnState <= GET_READ_BIT;					                     
							State <= N2P_SCL_NEGEDGE;
						end
						else begin
							ReturnState <= GET_ID2;
							State <= N2P_SCL_NEGEDGE;
						end
					end
					else begin
							State <= STOP_WAIT;
					end
				end
				
				GET_READ_BIT: begin	
					SDA_oe <= 0;
					SDA_data <= 0;

					if( SDA == READ_BIT ) begin
						ReturnState <= SEND_ACK4;					
						State <= P2N_SCL_NEGEDGE;
					end
					else begin
						ReturnState <= STOP_WAIT;
						State <= N2P_SCL_NEGEDGE;
					end

				end

				SEND_ACK4: begin	
					SDA_oe <= 1;
					SDA_data <= ACK_COND;

					Index <= 7;
					ReturnState <= SEND_MEM_DATA;
					State <= P2N_SCL_POSEDGE;
				end
				
				SEND_MEM_DATA: begin	
					SDA_oe <= 1;
					SDA_data <= MEMORY[addr][Index];
					Index <= Index - 1;
					
					if( Index == 0 )begin
						ReturnState <= MASTER_ACK;					
						State <= P2N_SCL_NEGEDGE;
					end
					else begin
						ReturnState <= SEND_MEM_DATA;
						State <= P2N_SCL_NEGEDGE;
					end
				end
				
				// memory transmitted data, master controller is the reciever in this case
				// if the master sends NO ACK we are done and need to look for STOP 
				// if the master sends ACK then we are in sequential read mode
				MASTER_ACK: begin
					SDA_oe <= 0;
					SDA_data <= 0;
					ReturnState <= MASTER_ACK2;
					State <= N2P_SCL_POSEDGE;

				end

				MASTER_ACK2: begin
					SDA_oe <= 0;
					SDA_data <= 0;

					if(SDA == NO_ACK_COND) begin
						ReturnState <= STOP_WAIT;
						State <= N2P_SCL_NEGEDGE;
					end
					else begin
						Index <= 7;
						addr <= addr + 1;
						ReturnState <= SEND_MEM_DATA;
						State <= P2N_SCL_NEGEDGE;					

					end
				end

				STOP_WAIT: begin					
					SDA_oe <= 0;
					SDA_data <= 0;

					if( SCL == 1 && SDA == 0 ) begin
						State <= STOP_FIND;					
					end
					else begin
						State <= STOP_WAIT; 
					end
				end

				STOP_FIND: begin
					SDA_oe <= 0;
					SDA_data <= 0;

					if( SCL == 1 && SDA == 1 ) begin
						State <= START1_WAIT;					
					end
					else begin
						State <= STOP_FIND;
					end
				end

				default: begin
					$display("I2C Memory Module: Entered Default Switch Stmt.");
					State <= START1_WAIT;
				end
			endcase
		end
	end
endmodule