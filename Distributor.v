module Distributor(
	//basic
	input clk,
	input reset,
	//busy
	input busy_1,
	input busy_2,
	input busy_3,
	input busy_4,
	//common inouts
	output reg [11:0]commWrdOut,
	output reg [9:0]commWrdAddr,
	output reg commWren,
	input [11:0]commOldWrd,
	output reg [9:0]commOldWrdAddr,
	output reg commOldRdEn,
	//individual inouts
	input [11:0]wrdOut_1,
	input [9:0]wrdAddr_1,
	input wren_1,
	output reg[11:0]oldWrd_1,
	input [9:0]oldWrdAddr_1,
	input oldRdEn_1,
	//individual inouts
	input [11:0]wrdOut_2,
	input [9:0]wrdAddr_2,
	input wren_2,
	output reg[11:0]oldWrd_2,
	input [9:0]oldWrdAddr_2,
	input oldRdEn_2,
	//individual inouts
	input [11:0]wrdOut_3,
	input [9:0]wrdAddr_3,
	input wren_3,
	output reg[11:0]oldWrd_3,
	input [9:0]oldWrdAddr_3,
	input oldRdEn_3,
	//individual inouts
	input [11:0]wrdOut_4,
	input [9:0]wrdAddr_4,
	input wren_4,
	output reg[11:0]oldWrd_4,
	input [9:0]oldWrdAddr_4,
	input oldRdEn_4
);

wire [3:0]trigger;
assign trigger[0] = busy_1;
assign trigger[1] = busy_2;
assign trigger[2] = busy_3;
assign trigger[3] = busy_4;

always@(posedge clk or negedge reset)
begin
	if(~reset) begin
		commWrdOut <= 0;
		commWrdAddr <= 0;
		commWren <= 0;
		commOldWrdAddr <= 0;
		commOldRdEn <= 0;
		oldWrd_1 <= 0;
		oldWrd_2 <= 0;
		oldWrd_3 <= 0;
		oldWrd_4 <= 0;
	end else begin
		case(trigger)
			3'd1: begin	
				commWrdOut <= wrdOut_1;
				commWrdAddr <= wrdAddr_1;
				commWren <= wren_1;
				oldWrd_1 <= commOldWrd;
				commOldWrdAddr <= oldWrdAddr_1;
				commOldRdEn <= oldRdEn_1;
			end
			3'd2: begin
				commWrdOut <= wrdOut_2;
				commWrdAddr <= wrdAddr_2;
				commWren <= wren_2;
				oldWrd_2 <= commOldWrd;
				commOldWrdAddr <= oldWrdAddr_2;
				commOldRdEn <= oldRdEn_2;
			end
			3'd4: begin
				commWrdOut <= wrdOut_3;
				commWrdAddr <= wrdAddr_3;
				commWren <= wren_3;
				oldWrd_3 <= commOldWrd;
				commOldWrdAddr <= oldWrdAddr_3;
				commOldRdEn <= oldRdEn_3;
			end
			3'd8: begin
				commWrdOut <= wrdOut_4;
				commWrdAddr <= wrdAddr_4;
				commWren <= wren_4;
				oldWrd_4 <= commOldWrd;
				commOldWrdAddr <= oldWrdAddr_4;
				commOldRdEn <= oldRdEn_4;
			end
			default: begin
				commWrdOut <= 0;
				commWrdAddr <= 0;
				commWren <= 0;
				commOldWrdAddr <= 0;
				commOldRdEn <= 0;
				oldWrd_1 <= 0;
				oldWrd_2 <= 0;
				oldWrd_3 <= 0;
			end
		endcase
	end
end
endmodule
