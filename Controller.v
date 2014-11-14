module controller(clk, rst, start, i_lte_j, data_lt_min, data_lt_max, max_diff, start_addr_out, i_sel, i_ld, i_clr, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, max_diff_ld, max_diff_clr, busy, data_reg_ld_wire_in, scl, sda);

input clk, rst, start, i_lte_j, data_lt_min, data_lt_max;
input [7:0] max_diff;
input [7:0] start_addr_out;
output reg i_sel, i_ld, i_clr, j_ld, j_clr, data_reg_ld, data_reg_clr, sel_def_max_min, min_ld, min_clr, max_ld, max_clr, max_diff_ld, max_diff_clr, busy;
output reg [7:0] data_reg_ld_wire_in;
output scl, sda;

parameter S_init = 0, 
	  S_wait_for_reg_load = 1, 
	  S_setup_signal_generate = 2, 
  	  S_start_signal_generate = 3, 
	  S_data_signal_generate0 = 4, 
	  S_data_signal_generate1 = 5,
	  S_send_write_bit0 = 6,
	  S_send_write_bit1 = 7,
	  S_release_sda_device_addr = 8,
	  S_wait_for_ack_device_addr0 = 9,
	  S_wait_for_ack_device_addr1 = 10,
	  S_dummy_device_addr = 11,
	  S_send_word_addr0 = 12,
	  S_send_word_addr1 = 13,
	  S_release_sda_word_addr = 14,
	  S_wait_for_ack_word_addr0 = 15,
	  S_wait_for_ack_word_addr1 = 16,
	  S_dummy_word_addr = 17,
	  S_start_signal_generate_read0 = 18,
	  S_start_signal_generate_read1 = 19,
	  S_device_addr_generate0 = 20,
	  S_device_addr_generate1 = 21,
	  S_send_read_bit0 = 22,
	  S_send_read_bit1 = 23,
	  S_release_sda_device_addr2 = 24,
	  S_wait_for_ack_device_addr2_0 = 25,
	  S_wait_for_ack_device_addr2_1 = 26,
	  S_dummy_device_addr1 = 27,
	  S_send_ack_mem = 28,
	  S_send_ack_mem1 = 29,
	  S_send_ack_mem2 = 30,
	  S_receive_data_from_mem = 31,
	  S_get_compare_ij_result = 32,
  	  S_wait_for_ltmin_ltmax_signal = 33,
	  S_get_ltmin_ltmax_signal = 34,
	  S_wait_for_min_max_update = 35,
	  S_incr_addr = 36,
	  S_ld_max_diff = 37,
	  S_wait_for_max_diff_update = 38,
	  S_send_stop_signal = 39,
	  S_send_stop_signal1 = 40,
	  S_send_stop_signal2 = 41,
	  S_send_stop_signal3 = 42,
	  S_send_stop_signal4 = 43,
	  S_send_stop_signal5 = 44,
	  S_update_reg_write = 45,
	  S_send_data_mem = 46,
	  S_stop = 47;
	  
reg [5:0] State;
parameter [6:0]DEVICE_ID = 7'b1010001;
parameter WRITE_BIT = 1'b0;
parameter READ_BIT = 1'b1;


// temporary register counters
reg reg_load_ctr, reg_ctr_wait_for_ltmin_ltmax, reg_ctr_wait_for_min_max_update, reg_ctr_wait_for_max_diff_update;

reg [1:0] start_ctr_reg, data_ctr_reg0, data_ctr_reg1, data_rw_reg0, data_rw_reg1, release_ctr_device_reg, release_ctr_word_reg, deviceaddr_ack_ctr_reg, send_word_ctr_reg0, send_word_ctr_reg1, wordaddr_ack_ctr_reg, start_ctr_read_reg, data_ctr_reg2, data_ctr_reg3, data_rw_reg2, data_rw_reg3, release_ctr_device_reg2, deviceaddr_ack_ctr_reg2, dummy_ctr_device_addr_reg, dummy_ctr_word_addr_reg, dummy_ctr_device_addr1_reg;

reg [2:0] index1, index2;
reg [3:0] index_word_addr;
reg [4:0] read_data_ctr_reg;
reg sda_oe, scl_oe, sda_data; 
reg [2:0] read_value_ctr_reg;
reg [7:0] read_ctr_cont_reg, write_addr_reg;
reg flag_write_reg, flag_data_write_reg;
reg [2:0] setup_ctr_reg;
reg [7:0] tmp_addr_reg;
reg [7:0] MAX_DIFF;
reg FIRSTTIME;

assign sda = sda_oe ? sda_data : 1'bz;
assign scl = scl_oe ? 1'b1 : 1'b0;

	always @(posedge clk)
	begin
		if(rst == 1)
		begin
			State <= S_init;
			// values that go to datapath
			busy <= 1'b0;
			i_sel <= 1'b0; i_ld <= 1'b0;
			i_clr <= 1'b1; j_ld <= 1'b0; j_clr <= 1'b1;
			sel_def_max_min <= 1'b0; min_ld <= 1'b0; 
			min_clr <= 1'b1; max_clr <= 1'b1;
			max_diff_ld <= 1'b0; max_diff_clr <= 1'b1;
			data_reg_ld <= 1'b0; data_reg_clr <= 1'b1;

			// local controller registers
			reg_load_ctr <= 1;
			reg_ctr_wait_for_ltmin_ltmax <= 1;
			reg_ctr_wait_for_min_max_update <= 1;
			reg_ctr_wait_for_max_diff_update <= 1;
			
			scl_oe <= 1'b1;
			sda_oe <= 1'b1;
			sda_data <= 1'b1;
			setup_ctr_reg <= 3;
			start_ctr_reg <= 1;
			data_ctr_reg0 <= 1;
			data_ctr_reg1 <= 1;
			data_ctr_reg2 <= 1;
			data_ctr_reg3 <= 1;
			data_rw_reg0 <= 1;
			data_rw_reg1 <= 1;
			data_rw_reg2 <= 1;
			data_rw_reg3 <= 1;
			release_ctr_device_reg <= 1;
			release_ctr_device_reg2 <= 1;
			release_ctr_word_reg <= 1;
			deviceaddr_ack_ctr_reg <= 1;
			deviceaddr_ack_ctr_reg2 <= 1;
			wordaddr_ack_ctr_reg <= 1;
			send_word_ctr_reg0 <= 1;
			send_word_ctr_reg1 <= 1;
			start_ctr_read_reg <= 1;
			read_data_ctr_reg <= 17;
			dummy_ctr_device_addr_reg <= 1;
			dummy_ctr_word_addr_reg <= 1;
			dummy_ctr_device_addr1_reg <= 1;
			index1 <= 7;
			index2 <= 7;
			index_word_addr <= 8;
			read_value_ctr_reg <= 7;
			flag_write_reg <= 0;
			flag_data_write_reg <= 0;
			write_addr_reg <= 255;			
			FIRSTTIME <= 1'b1;
		end
		else
		begin
			case(State)
				S_init:
				begin
					busy <= 1'b0;
					i_ld <= 1'b1;
					i_clr <= 1'b0;
					j_ld <= 1'b1;
					j_clr <= 1'b0;
					i_sel <= 1'b0;
					sel_def_max_min <= 1'b0;
					min_clr <= 1'b0; max_clr <= 1'b0;
					min_ld <= 1'b1; max_ld <= 1'b1;
					scl_oe <= 1'b1;
					sda_oe <= 1'b1;
					sda_data <= 1'b1;

					if(start == 1'b1)
					begin
						State <= S_wait_for_reg_load;
						busy <= 1'b1;
					end
					else
					begin
						State <= S_init;
					end
				end

				S_wait_for_reg_load:
				begin
					if(reg_load_ctr != 0)
					begin
						tmp_addr_reg <= start_addr_out;
						reg_load_ctr <= reg_load_ctr - 1;
						State <= S_wait_for_reg_load;
						i_ld <= 1'b0; i_clr <= 1'b0;
						min_ld <= 1'b0; min_clr <= 1'b0;
						max_ld <= 1'b0; max_clr <= 1'b0;

					end
					else
					begin
			
						if(FIRSTTIME == 1'b1)
						begin
							State <= S_setup_signal_generate;
						end
						else
						begin
							State <= S_send_ack_mem;
						end	
					end
				end

				S_setup_signal_generate:
				begin
					if(setup_ctr_reg != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= 1'b1;
						State <= S_setup_signal_generate;
						setup_ctr_reg <= setup_ctr_reg - 1;		
					end
					else
					begin
						State <= S_start_signal_generate;
					end
				end	
				
				S_start_signal_generate:
				begin
					if(start_ctr_reg != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= 1'b0;
						State <= S_start_signal_generate;
						start_ctr_reg <= start_ctr_reg - 1;		
					end
					else
					begin
						State <= S_data_signal_generate0;
					end
				end

				S_data_signal_generate0:
				begin
					if(data_ctr_reg0 != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b1;
						sda_data <= DEVICE_ID[index1-1];
						State <= S_data_signal_generate0;
						data_ctr_reg0 <= data_ctr_reg0 - 1;
					end
					else
					begin
						State <= S_data_signal_generate1;
					end
				end
				
				S_data_signal_generate1:
				begin
					if(data_ctr_reg1 != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= DEVICE_ID[index1-1];
						data_ctr_reg1 <= data_ctr_reg1 - 1;
						index1 <= index1 - 1;	
					end
					else
					begin
						if(index1 == 0)
						begin
							State <= S_send_write_bit0;
						end
						else
						begin
							State <= S_data_signal_generate0;
							data_ctr_reg0 <= 1;
							data_ctr_reg1 <= 1;
						end
					end
				end

				S_send_write_bit0:
				begin
					if(data_rw_reg0 != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b1;
						sda_data <= WRITE_BIT;
						data_rw_reg0 <= data_rw_reg0 - 1;
					end
					else
					begin
						State <= S_send_write_bit1;
					end
				end

				S_send_write_bit1:
				begin
					if(data_rw_reg1 != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= WRITE_BIT;
						data_rw_reg1 <= data_rw_reg1 - 1;
					end
					else
					begin
						State <= S_release_sda_device_addr;
					end
				end

				S_release_sda_device_addr:
				begin
					if(release_ctr_device_reg != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b0;
						release_ctr_device_reg <= release_ctr_device_reg - 1;
					end
					else
					begin
						State <= S_wait_for_ack_device_addr0;
					end	
				end

				S_wait_for_ack_device_addr0:
				begin
					State <= S_wait_for_ack_device_addr1;
				end

				S_wait_for_ack_device_addr1:
				begin
					scl_oe <= 1'b1;
					if(deviceaddr_ack_ctr_reg != 0)
					begin
						//Provide delay
						deviceaddr_ack_ctr_reg <= deviceaddr_ack_ctr_reg - 1;
					end
					else
					begin
						State <= S_dummy_device_addr;
					
					end
				end

				S_dummy_device_addr:
				begin
					if(dummy_ctr_device_addr_reg != 0)
					begin
						scl_oe <= 1'b0;
						State <= S_dummy_device_addr;
						dummy_ctr_device_addr_reg <= dummy_ctr_device_addr_reg - 1;
					end
					else
					begin
						State <= S_send_word_addr0;
					end
				end

				S_send_word_addr0:
				begin
					if(send_word_ctr_reg0 != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b1;
						if( (flag_write_reg == 0) && (flag_data_write_reg == 0) )
						begin
							sda_data <= tmp_addr_reg[index_word_addr-1];
						end
						else if( (flag_write_reg == 1) && (flag_data_write_reg == 0) )
						begin
							sda_data <= write_addr_reg[index_word_addr-1];
						end
						else if( (flag_write_reg == 1) && (flag_data_write_reg == 1) )
						begin
							sda_data <= MAX_DIFF[index_word_addr-1];
						end
						
						State <= S_send_word_addr0;
						send_word_ctr_reg0 <= send_word_ctr_reg0 - 1;
					end
					else
					begin
						State <= S_send_word_addr1;
					end
				end	

				S_send_word_addr1:
				begin
					if(send_word_ctr_reg1 != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						if( (flag_write_reg == 0) && (flag_data_write_reg == 0) )
						begin
							sda_data <= tmp_addr_reg[index_word_addr-1];
						end
						else if( (flag_write_reg == 1) && (flag_data_write_reg == 0) )
						begin
							sda_data <= write_addr_reg[index_word_addr-1];
						end
						else if( (flag_write_reg == 1) && (flag_data_write_reg == 1) )
						begin
							sda_data <= MAX_DIFF[index_word_addr-1];
						end
						
						State <= S_send_word_addr1;
						send_word_ctr_reg1 <= send_word_ctr_reg1 - 1;
						index_word_addr <= index_word_addr - 1;	
					end
					else
					begin
						if(index_word_addr == 0)
						begin
							State <= S_release_sda_word_addr;
						end
						else
						begin
							State <= S_send_word_addr0;
							send_word_ctr_reg0 <= 1;
							send_word_ctr_reg1 <= 1;
						end
					end
				end
	
				S_release_sda_word_addr:
				begin
					if(release_ctr_word_reg != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b0;
						release_ctr_word_reg <= release_ctr_word_reg - 1;
					end
					else
					begin
						State <= S_wait_for_ack_word_addr0;
					end	
				end

				S_wait_for_ack_word_addr0:
				begin
					State <= S_wait_for_ack_word_addr1; 
				end
		
				S_wait_for_ack_word_addr1:
				begin
					scl_oe <= 1'b1;
					if(wordaddr_ack_ctr_reg != 0)
					begin
						//Provide delay
						wordaddr_ack_ctr_reg <= wordaddr_ack_ctr_reg - 1;
					end
					else
					begin
						State <= S_dummy_word_addr;
					end

				end

				S_dummy_word_addr:
				begin
					if(dummy_ctr_word_addr_reg != 0)
					begin
						scl_oe <= 1'b0;
						State <= S_dummy_word_addr;
						dummy_ctr_word_addr_reg <= dummy_ctr_word_addr_reg - 1;
					end
					else
					begin
						if( (flag_write_reg == 0) && (flag_data_write_reg == 0) )
						begin
							State <= S_start_signal_generate_read0;
						end
						else if( (flag_write_reg == 1) && (flag_data_write_reg == 0) )
						begin
							State <= S_send_data_mem;	
						end
						else if((flag_write_reg == 1) && (flag_data_write_reg == 1))
						begin
							State <= S_send_stop_signal;
						end
					end
				end	
			
				S_start_signal_generate_read0:
				begin
					scl_oe <= 1'b1;
					sda_oe <= 1'b1;
					sda_data <= 1'b1;
					State <= S_start_signal_generate_read1;
				end				

				S_start_signal_generate_read1:
				begin
					if(start_ctr_read_reg != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= 1'b0;
						State <= S_start_signal_generate_read1;
						start_ctr_read_reg <= start_ctr_read_reg - 1;		
					end
					else
					begin
						State <= S_device_addr_generate0;
					end
				end
	
				S_device_addr_generate0:
				begin
					if(data_ctr_reg2 != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b1;
						sda_data <= DEVICE_ID[index2-1];
						State <= S_device_addr_generate0;
						data_ctr_reg2 <= data_ctr_reg2 - 1;
					end
					else
					begin
						State <= S_device_addr_generate1;
					end
				end
			
				S_device_addr_generate1:
				begin
					if(data_ctr_reg3 != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= DEVICE_ID[index2-1];
						data_ctr_reg3 <= data_ctr_reg3 - 1;
						index2 <= index2 - 1;	
					end
					else
					begin
						if(index2 == 0)
						begin
							State <= S_send_read_bit0;
						end
						else
						begin
							State <= S_device_addr_generate0;
							data_ctr_reg2 <= 1;
							data_ctr_reg3 <= 1;
						end
					end
				end
				
				S_send_read_bit0:
				begin
					if(data_rw_reg2 != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b1;
						sda_data <= READ_BIT;
						data_rw_reg2 <= data_rw_reg2 - 1;
					end
					else
					begin
						State <= S_send_read_bit1;
					end
				end
			
				S_send_read_bit1:
				begin
					if(data_rw_reg3 != 0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= READ_BIT;
						data_rw_reg3 <= data_rw_reg3 - 1;
					end
					else
					begin
						State <= S_release_sda_device_addr2;
					end
				end

				S_release_sda_device_addr2:
				begin
					if(release_ctr_device_reg2 != 0)
					begin
						scl_oe <= 1'b0;
						sda_oe <= 1'b0;
						release_ctr_device_reg2 <= release_ctr_device_reg2 - 1;
					end
					else
					begin
						State <= S_wait_for_ack_device_addr2_0;
					end	
				end
				
				S_wait_for_ack_device_addr2_0:
				begin
					State <= S_wait_for_ack_device_addr2_1;
				end
			
				S_wait_for_ack_device_addr2_1:
				begin
					scl_oe <= 1'b1;
					if(deviceaddr_ack_ctr_reg2 != 0)
					begin
						//Provide delay
						deviceaddr_ack_ctr_reg2 <= deviceaddr_ack_ctr_reg2 - 1;
					end
					else
					begin
						State <= S_dummy_device_addr1;
					end
				end	

				S_dummy_device_addr1:
				begin
					if(dummy_ctr_device_addr1_reg != 0)
					begin
						scl_oe <= 1'b1;
						State <= S_dummy_device_addr1;
						dummy_ctr_device_addr1_reg <= dummy_ctr_device_addr1_reg - 1;
					end
					else
					begin
						scl_oe <= 1'b0;
						State <= S_receive_data_from_mem;
					end
				end

				S_send_ack_mem:
				begin
					scl_oe <= 1'b1;
					sda_oe <= 1'b1;
					sda_data <= 1'b0;
					State <= S_send_ack_mem1;
				end	

				S_send_ack_mem1:
				begin
					scl_oe <= 1'b0;
					sda_oe <= 1'b0;
					read_data_ctr_reg <= 17;
					read_value_ctr_reg <= 7;
					read_ctr_cont_reg <= read_ctr_cont_reg - 1;
					State <= S_send_ack_mem2;
				end

				S_send_ack_mem2:
				begin
					State <= S_receive_data_from_mem;
				end
				
				S_receive_data_from_mem:
				begin
					if(read_data_ctr_reg != 0)
					begin	
						read_data_ctr_reg <= read_data_ctr_reg - 1;
						if((read_data_ctr_reg != 17) && (read_data_ctr_reg%2 == 1))
						begin
							data_reg_ld_wire_in[read_value_ctr_reg] <= sda;
							read_value_ctr_reg <= read_value_ctr_reg - 1;
						end
					end
					else
					begin
						State <= S_get_compare_ij_result;
					end
				end			

	
				S_get_compare_ij_result:
				begin
					if(i_lte_j == 1'b1)
					begin
						data_reg_ld <= 1'b1; data_reg_clr <= 1'b0;
						State <= S_wait_for_ltmin_ltmax_signal;
					end
					else if(i_lte_j == 1'b0)
					begin
						scl_oe <= 1'b1;
						sda_oe <= 1'b1;
						sda_data <= 1'b1;
						State <= S_ld_max_diff;
						i_ld <= 1'b0; i_clr <= 1'b0;	
					end

				end

				S_wait_for_ltmin_ltmax_signal:
				begin
					if(reg_ctr_wait_for_ltmin_ltmax != 0)
					begin
						reg_ctr_wait_for_ltmin_ltmax = reg_ctr_wait_for_ltmin_ltmax - 1;	
						State <= S_wait_for_ltmin_ltmax_signal;
					end	
					else
					begin
						State <= S_get_ltmin_ltmax_signal;
					end
				end

				S_get_ltmin_ltmax_signal:
				begin
					data_reg_ld <= 1'b0; data_reg_clr <= 1'b0;
					if(data_lt_min == 1'b1)
					begin
						sel_def_max_min <= 1'b1;
						min_ld <= 1'b1; min_clr <= 1'b0;
					end
					else if(data_lt_min == 1'b0)
					begin
						sel_def_max_min <= 1'b1;
						min_ld <= 1'b0; min_clr <= 1'b0;
					end
					if(data_lt_max == 1'b1)
					begin
						sel_def_max_min <= 1'b1;
						max_ld <= 1'b1; max_clr <= 1'b0;
					end
					else if(data_lt_max == 1'b0)
					begin
						sel_def_max_min <= 1'b1;
						max_ld <= 1'b0; max_clr <= 1'b0;
					end
					State <= S_wait_for_min_max_update;
					
				end

				S_wait_for_min_max_update:
				begin
					if(reg_ctr_wait_for_min_max_update != 0)
					begin
						reg_ctr_wait_for_min_max_update = reg_ctr_wait_for_min_max_update - 1;
						State <= S_wait_for_min_max_update;
					end
					else
					begin
						min_ld <= 1'b0; max_ld <= 1'b0;
						State <= S_incr_addr;
					end
				end

				S_incr_addr:
				begin
					i_ld <= 1'b1; i_clr <= 1'b0;
					i_sel <= 1'b1;	
					State <= S_wait_for_reg_load;
					FIRSTTIME <= 1'b0;
					reg_load_ctr <= 1;
					reg_ctr_wait_for_ltmin_ltmax <= 1;
					reg_ctr_wait_for_min_max_update <= 1;
					 

				end
	
				S_ld_max_diff:
				begin
					max_diff_ld <= 1'b1; max_diff_clr <= 1'b0;
					State <= S_wait_for_max_diff_update;
				end
				
				S_wait_for_max_diff_update:
				begin
					if(reg_ctr_wait_for_max_diff_update != 0)
					begin
						reg_ctr_wait_for_max_diff_update <= reg_ctr_wait_for_max_diff_update - 1;
						State <= S_wait_for_max_diff_update;
					end
					else
					begin
						State <= S_send_stop_signal;
					end
				end

				S_send_stop_signal:
				begin
					scl_oe <= 1'b1;
					sda_oe <= 1'b1;
					sda_data <= 1'b0;
					State <= S_send_stop_signal1;
				end
			
				S_send_stop_signal1:
				begin
					sda_oe <= 1'b1;
					sda_data <= 1'b1;
					State <= S_send_stop_signal2;
				end

				S_send_stop_signal2:
				begin
					scl_oe <= 1'b0;
					State <= S_send_stop_signal3;
				end

				S_send_stop_signal3:
				begin
					scl_oe <= 1'b1;
					State <= S_send_stop_signal4;
				end
				
				S_send_stop_signal4:
				begin
					scl_oe <= 1'b1;
					sda_oe <= 1'b1;
					sda_data <= 1'b0;
					State <= S_send_stop_signal5;	
				end

				S_send_stop_signal5:
				begin
					scl_oe <= 1'b1;
					sda_oe <= 1'b1;
					sda_data <= 1'b1;
					if(flag_data_write_reg == 0)
					begin
						State <= S_update_reg_write;
					end
					else if(flag_data_write_reg == 1) 
					begin
						busy <= 0;
						State <= S_stop;
					end
				end

				S_update_reg_write:
				begin
					start_ctr_reg <= 1;
					data_ctr_reg0 <= 1;
					data_ctr_reg1 <= 1;
					index1 <= 7;
					data_rw_reg0 <= 1;
					data_rw_reg1 <= 1;
					release_ctr_device_reg <= 1;
					deviceaddr_ack_ctr_reg <= 1;
					dummy_ctr_device_addr_reg <= 1;
					send_word_ctr_reg0 <= 1;
					send_word_ctr_reg1 <= 1;
					release_ctr_word_reg <= 1;
					wordaddr_ack_ctr_reg <= 1;
					dummy_ctr_word_addr_reg <= 1;
					index_word_addr <= 8;
					flag_write_reg <= 1;
					MAX_DIFF <= max_diff;
					State <= S_start_signal_generate;
				end

				S_send_data_mem:
				begin
					send_word_ctr_reg0 <= 1;
					send_word_ctr_reg1 <= 1;
					release_ctr_word_reg <= 1;
					wordaddr_ack_ctr_reg <= 1;
					dummy_ctr_word_addr_reg <= 1;
					index_word_addr <= 8;
					flag_data_write_reg <= 1;
					State <= S_send_word_addr0;
				end

				S_stop:
				begin
				end
				
	
			endcase	
		end
	end  

endmodule
