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
assign rearBusy		=	(syncBusy[2] & !syncBusy[1]);	// rear finder
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
		cntStream <= 5'b0;
		numStream <= 2'b0;
	end else begin
		case (state)
			IDLE: begin						// wait for MCM data to fill in
				if(iDone)
					state <= WAITMEM;
			end
			WAITMEM: begin					// wait for group mems to be available
				if(rearBusy) begin			// if lcbs are done 
					state <= ACT;
					oBusy <= 1'b1;			// assert business signal
				end
			end
			ACT: begin								// start reading and writing
				stepAct <= stepAct + 1'b1;			// make a sequence of actions
				case(stepAct)
					0: oRdEn <= 1'b1;				// read from memory + wait 3 clocks for memory to respond
					3: word[11:4] <= iData[7:0];	// write a word
					4: begin
						oRdEn <= 1'b0;				// stop reading
						oRdAddr <= oRdAddr + 1'b1;	// prepare to read next word from buffer
						oData <= word;				// set word to output
						oWren <= 1'b1;				// enable writing to group memory
					end
					5: oRdEn <= 1'b1;				// read another word from buffer + wait 3 clocks for memory to respond
					8: word[11:4] <= iData[7:0];	// write LSB to word
					9: begin
						oWren <= 1'b0;				// stop writing previous word
						oAddr <= oAddr + 10'd32;	// prepare next group writing address
						oRdEn <= 1'b0;				// stop reading
						oRdAddr <= oRdAddr + 1'b1;	// prepare to read next word from buffer
					end
					10: oRdEn <= 1'b1;				// read another word from buffer + wait 3 clocks for memory to respond
					13: word[3:2] <= iData[1:0];	// write MSB to word
					14: begin
						oRdEn <= 1'b0;				// stop reading
						oRdAddr <= oRdAddr + 1'b1;	// prepare to read next word from buffer
						oData <= word;				// set word to output
						oWren <= 1'b1;				// enable writing to group memory and wait 3 clocks
					end
					17: begin
						oWren <= 1'b0;					// stop writing previous word
						oAddr <= oAddr + 10'd32;		// prepare next group writing address
						cntStream <= cntStream + 1'b1;	// count iterations inside one stream
						stepAct <= 5'b0;				// drop sequencer
						state <= CHECK;					// check where we are
					end
				endcase
			end
			CHECK: begin
				if(cntStream < 16) begin				// if we are still writing a stream
					state <= ACT;						// go and write it
				end else begin							// otherwise 
					oAddr <= oAddr + 10'd8;				// prepare to write next stream
					cntStream <= 5'b0;					// drop the inner stream counter
					numStream <= numStream + 1'b1;		// proceed to next stream
					if(numStream == 2'd2) begin			// if it's already third stream
						numStream <= 2'b0;				// drop the stream number
						oAddr <= 10'b0;					// drop address
						oBusy <= 1'b0;					// drop business signal
						state <= DONE;					// go and wait for outer driver signals
					end else begin
						state <= WAITMEM;				// otherwise go and wait for next time memory will be free to write
						oBusy <= 1'b0;					// anyway drop business signal
					end
				end
			end
			DONE: begin							// when done everything
				if(~iDone) begin				// and when outer driver started requesting next data
					state <= IDLE;				// drop everything and go wait next portion of data
					oData <= 12'b0;
					oAddr <= 10'b0;
					oWren <= 1'b0;
					oBusy <= 1'b0;
					word <= 12'b0;
					stepAct <= 5'b0;
					cntStream <= 5'b0;
					numStream <= 2'b0;
				end
			end
		endcase
	end
end
endmodule
