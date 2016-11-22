module MCM_pack (
	input				clk,
	input				reset,
	input				iDone,		// done from coordinator (start reading)
	input		[7:0]	iData,		// data from RAM
	output	reg	[7:0]	oRdAddr,	// address to RAM
	output	reg			oRdEn,		// rden from RAM
	
	input				iBusy,		// busy signal from lcb's
	output	reg	[11:0]	oData,		// data to GROUP distributor(orbit words)
	output	reg	[9:0]	oAddr,		// address to group distributor (orbit addresses)
	output	reg			oWren,		// wren & busy to distributor
	
	output	reg			oBusy		// packer is busy writing to memory
);

reg		[2:0]	syncBusy;		// busy signal syncronizer
wire			rearBusy;		// busy signal rear
assign rearBusy		=	(!syncBusy[2] & syncBusy[1]);	// rear finder
always@(negedge reset or posedge clk) begin				// double dff on "busy" signal
	if (~reset) begin
		syncBusy <= 0;
	end else begin
		syncBusy <= {syncBusy[1:0], iBusy}; 
	end
end

// if done receiving and not busy from lcb's then read from MCMram and write to group rams. 
// set own busy signal

localparam IDLE = 0, WAITMEM = 1, ACT = 2, CHECK = 3, DONE = 4;

reg		[2:0]	state;
reg		[4:0]	stepAct;
reg		[11:0]	word;
reg		[4:0]	cntStream;
reg		[1:0]	numStream;
always@(posedge clk or negedge reset)
begin
	if(~reset) begin
		oData <= 12'b0;
		oAddr <= 10'b0;
		oWren <= 1'b0;
		oBusy <= 1'b0;
		word <= 12'b0;
		stepAct <= 5'b0;
	end else begin
		case (state)
			IDLE: begin						// wait for MCM data to fill in
				if(iDone)
					state <= WAITMEM;
			end
			WAITMEM: begin					// wait for group mems to be available
				if(rearBusy) begin
					state <= ACT;
					oBusy <= 1'b1;
				end
			end
			ACT: begin						// start reading and writing
				stepAct <= stepAct + 1'b1;
				case(stepAct)
					0: oRdEn <= 1'b1;
					3: word[11:4] <= iData[7:0];
					4: begin
						oRdEn <= 1'b0;
						oRdAddr <= oRdAddr + 1'b1;
						oData <= word;
						oWren <= 1'b1;
					end
					5: oRdEn <= 1'b1;
					8: word[11:4] <= iData[7:0];
					9: begin
						oWren <= 1'b0;
						oAddr <= oAddr + 10'd32;
						oRdEn <= 1'b0;
						oRdAddr <= oRdAddr + 1'b1;
						cntStream <= cntStream + 1'b1;
					end
					10: oRdEn <= 1'b1;
					13: word[3:2] <= iData[1:0];
					14: begin
						oRdEn <= 1'b0;
						oRdAddr <= oRdAddr + 1'b1;
						oData <= word;
						oWren <= 1'b1;
					end
					17: begin
						oWren <= 1'b0;
						oAddr <= oAddr + 10'd32;
						cntStream <= cntStream + 1'b1;
						stepAct <= 5'b0;
						state <= CHECK;
					end
				endcase
			end
			CHECK: begin
				if(cntStream < 16) begin
					state <= ACT;
				end else begin
					oAddr <= oAddr + 10'd8;
					numStream <= numStream + 1'b1;
					if(numStream == 2'd3) begin
						numStream <= 2'b0;
						oAddr <= 10'b0;
						state <= DONE;
						oBusy <= 1'b0;
					end else begin
						state <= ACT;
					end
				end
			end
			DONE: begin
				if(~iDone)
					state <= IDLE;
			end
		endcase
	end
end
endmodule
