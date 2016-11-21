module MCM_pack (
	input clk,
	input reset,
	input iDone,				// done from coordinator (start reading)
	input [7:0]iData,			// data from RAM
	output reg [7:0]oRdAddr,	// address to RAM
	output reg oRdEn,			// rden from RAM
	
	input iBusy,				// busy signal from lcb's
	output reg [11:0]oData,		// data to GROUP distributor(orbit words)
	output reg [9:0]oAddr,		// address to group distributor (orbit addresses)
	output reg oWren,			// wren & busy to distributor
	
	output reg oBusy			// packer is busy writing to memory
);

// if done receiving and not busy from lcb's then read from MCMram and write to group rams. 
// set own busy signal



endmodule
