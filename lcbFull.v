module lcbFull(
	input clk,
	input reset,
	input [7:0]rawData,
	input rxValid,
	input [4:0]LCBrqNumber,
	output reg [11:0]wrdOut,
	output reg [9:0]wrdAddr,
	output reg wren,
	output reg busy,

	output reg [8:0]addrROMaddr,
	input [14:0]dataROMaddr,
	
	input [11:0]oldWrd,
	output reg [9:0]oldWrdAddr,
	output reg oldRdEn,
	
	output test
);

reg [4:0]state;
reg [3:0]cnt_bytes;
reg [9:0]measure1, measure2, measure3, measure4;
reg [8:0]rom_address;
reg [11:0]old_word;
reg is_contact;
reg [3:0]bit_contact;
reg measure_contact;
reg [14:0]full_addr;
assign test = cnt_bytes[3];

always@(posedge clk or negedge reset) begin
	if (!reset)begin
		busy <= 0;
		cnt_bytes <= 0;
		state <= 0;
		wren <= 0;
		rom_address <= 0;
		measure1 <= 0;
		measure2 <= 0;
		measure3 <= 0;
		measure4 <= 0;
		addrROMaddr <= 0;
		oldWrdAddr <= 0;
		oldRdEn <= 0;
		wrdOut <= 0;
		is_contact <= 0;
		bit_contact <= 0;
		old_word <= 0;
		full_addr <= 0;
	end else begin
		case (state)
			0: begin
				addrROMaddr <= rom_address;					// always get fresh orb address
				wren <= 0;							// drop the write-enable signal
				
// need to add completeness check here, to avoid signal failures

				if (rxValid) begin							// if got valid data from receiver
					wrdAddr <= dataROMaddr[13:4];			// set orb word write address
					oldWrdAddr <= dataROMaddr[13:4];		// set orb word read address (same) if we will need to add contact parameter later
					is_contact <= ~dataROMaddr[14];			// 1 is analog, 0 is contact
					bit_contact <= dataROMaddr[3:0] - 1'b1;	// bit of the word to write contact parameter
					full_addr <= dataROMaddr;
					
					cnt_bytes <= cnt_bytes + 1'b1; 		// counting received bytes
					if (cnt_bytes == 14) cnt_bytes <= 0; 	// resetting byte counter
					
					case (cnt_bytes)							// depending on a received byte number, handle the input
						0,5,10:begin						// 1, 6, 11 bytes contain only MSB's of next four measures
							measure1[9:8] <= rawData[7:6];
							measure2[9:8] <= rawData[5:4];
							measure3[9:8] <= rawData[3:2];
							measure4[9:8] <= rawData[1:0];
							state <= 5'd11;					// do nothing when get first bytes, go wait for valid signal to drop down
						end
						1,6,11:begin
							measure1[7:0] = rawData[7:0];		// at this moment we got the full first measure
							wrdOut <= {1'b0, measure1, 1'b0};	// and set it to output (will overwrite, if needed)
							state <= 5'd1;						// go handle the measure (check whether it's analog or contact)
						end
						2,7,12:begin
							measure2[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure2, 1'b0}; 
							state <= 5'd1;
						end
						3,8,13:begin
							measure3[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure3, 1'b0}; 
							state <= 5'd1;
						end
						4,9,14:begin
							measure4[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure4, 1'b0}; 
							state <= 5'd1;
						end
					endcase
					measure_contact <= rawData[0];
				end
			end
			1, 2: begin
busy <= 1;			// master signal, when got a byte here - write it to memory
			end	
			3: begin
				rom_address <= rom_address + 1'b1;			//start writing next address to a variable
				if (full_addr == 15) begin 
						state <= 5'd13;
				end else begin
					if (is_contact == 1) begin				//if received measure is contact
							oldRdEn <= 1;						//go read the old value
							state <= 5'd4;							//and proceed to the next step
					end else begin						//otherwise
						state <= 5'd10;							//skip few steps
					end
				end
			end
			4, 5, 6: state <= state + 1'b1;				//wait for old word to set to input
			7: begin
				old_word <= oldWrd;						//latch an old word
				oldRdEn <= 0;						//drop the read-enable signal
				state <= state + 1'b1;
			end
			8: begin
				old_word[bit_contact] <= measure_contact;	//set new bit to old word
				state <= state + 1'b1;
			end
			9: begin
				wrdOut <= old_word;						// set the edited word to output, overwriting previous value
				state <= state + 1'b1;
			end
			10, 11, 12: begin						//came here with the output word and address buses set (first step else links here)
				wren <= 1;								// activate the write-enable and wait for group memory to react on it
				state <= state + 1'b1;
			end
			13: begin								// final checks and moving to the start
busy <= 0;			
				oldRdEn <= 0;
				if (!rxValid) begin
					if (rom_address == 384) rom_address <= 0;
					state <= 1'b0;
				end
			end
		endcase
	end
end
endmodule
