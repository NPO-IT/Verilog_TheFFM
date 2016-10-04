module Distributor(
	//basic
	input clk,
	input reset,
	//busy
	input busy_1,
	input busy_2,
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
	input oldRdEn_2
);

wire [1:0]trigger;
assign trigger[0] = busy_1;
assign trigger[1] = busy_2;

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
	end else begin
		case(trigger)
			2'd1: begin	
				commWrdOut <= wrdOut_1;
				commWrdAddr <= wrdAddr_1;
				commWren <= wren_1;
				oldWrd_1 <= commOldWrd;
				commOldWrdAddr <= oldWrdAddr_1;
				commOldRdEn <= oldRdEn_1;
			end
			2'd2: begin
				commWrdOut <= wrdOut_2;
				commWrdAddr <= wrdAddr_2;
				commWren <= wren_2;
				oldWrd_2 <= commOldWrd;
				commOldWrdAddr <= oldWrdAddr_2;
				commOldRdEn <= oldRdEn_2;
			end
			default: begin
		//		commWren <= 0;
				commWrdOut <= 0;
				commWrdAddr <= 0;
				commWren <= 0;
				commOldWrdAddr <= 0;
				commOldRdEn <= 0;
				oldWrd_1 <= 0;
				oldWrd_2 <= 0;
			end
		endcase
	end
end
endmodule
