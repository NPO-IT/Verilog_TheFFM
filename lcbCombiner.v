module lcbCombiner(
	input clk,
	input reset,
	input [7:0]rawData,
	input rxValid,
	input [4:0]LCBrqNumber,
	output reg [8:0]addrROMaddr,
	input [14:0]dataROMaddr,
	output reg [11:0]wrdOut,
	output reg [9:0]wrdAddr,
	output reg wren,
	output test
);

reg [1:0]state;
reg [3:0]cntBytes;
reg [9:0]measure1, measure2, measure3, measure4;
reg [8:0]romAddress;

assign test = cntBytes[3];

always@(posedge clk or negedge reset) begin
	if (!reset)begin
		cntBytes <= 0;
		cntBytes <= 0;
		state <= 0;
		wren <= 0;
		romAddress <= 0;
		measure1 <= 0;
		measure2 <= 0;
		measure3 <= 0;
		measure4 <= 0;
	end else begin
		case (state)
			0: begin
				addrROMaddr <= romAddress;
				wren <= 0;
				if (rxValid) begin
					wrdAddr <= dataROMaddr[13:4];
					
					cntBytes <= cntBytes + 1'b1; 
					if (cntBytes == 14) cntBytes <= 0; 
					
					case (cntBytes)
						0,5,10:begin
							measure1[9:8] <= rawData[7:6];
							measure2[9:8] <= rawData[5:4];
							measure3[9:8] <= rawData[3:2];
							measure4[9:8] <= rawData[1:0];
							state <= 2'd2;
						end
						1,6,11:begin
							measure1[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure1, 1'b0};
							state <= 2'd1;

						end
						2,7,12:begin
							measure2[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure2, 1'b0}; 
							state <= 2'd1;
							
						end
						3,8,13:begin
							measure3[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure3, 1'b0}; 
							state <= 2'd1;
							
						end
						4,9,14:begin
							measure4[7:0] = rawData[7:0];
							wrdOut <= {1'b0, measure4, 1'b0}; 
							state <= 2'd1;
						end
					endcase
					
				end
			end
			1: begin
				wren <= 1;
				state <= 2;
				romAddress <= romAddress + 1'b1;
			end
			2: begin
				if (!rxValid) begin
					if (romAddress == 384) romAddress <= 0;
					state <= 1'b0;
				end
			end
		endcase
	end
end
endmodule
