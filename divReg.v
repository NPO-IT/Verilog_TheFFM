/*
	Ivan I. Ovchinnikov
	last upd.: 2016.02.10
*/

module divReg
(
	input reset,
	input iClkIN,			// whatever clock
	output reg Outdiv2,			// divided by 2 
	output reg Outdiv4,			// divided by 4
	output reg Outdiv8,			// divided by 8
	output reg Outdiv16			// divided by 16
);

reg [3:0] clk=0;

always @(negedge iClkIN or negedge reset)
if (~reset)
	clk <= 0;
else 
	clk<=clk+1'b1;				// always count 4-digit binary: 0..15

always @(posedge iClkIN or negedge reset) begin
	if (~reset) begin
		Outdiv2<=0;
		Outdiv4<=0;
		Outdiv8<=0;
		Outdiv16<=0;
	end else begin
		Outdiv2 <= clk[0];	// syncronous outputs
		Outdiv4 <= clk[1];
		Outdiv8 <= clk[2];
		Outdiv16 <= clk[3];
	end
end
endmodule 