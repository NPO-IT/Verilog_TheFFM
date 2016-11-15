module MCM_coord (
	input clk,
	input reset,
	input iRQ,
	input iVal,
	output reg [7:0] oAddr,
	output oDone
);

reg [7:0]	cntVal;			// valid signals counter
reg [2:0]	syncVal;		// valid signals syncronizer
reg 		frontVal;		// valid signal fronts
reg 		rearVal;		// valid signal fronts

assign frontVal = ((syncVal[2]) & !syncVal[1]);		// front finder
assign rearVal = (!(syncVal[2]) & syncVal[1]);		// rear finder
always@(negedge reset or posedge clk) begin			// double dff on "valid" signal
	if (~reset) begin
		syncVal <= 0;
	end else begin
		syncVal <= {syncVal[1:0], iVal}; 
	end
end


always@(posedge clk or negedge reset)
begin
	if(~reset) begin
		oAddr <= 0;								// on start reset address
		cntVal <= 0;							// on start reset bytes counter
	end else begin
		if(iRQ) begin							// if requesting data from MCM
			oAddr <= 0;							// syncronously reset address
			cntVal <= 0;						// syncronously reset counter
			oDone <= 0;							// drop "done receiving" signal
		end else begin							// when waiting for the answer
			if(frontVal) begin					// if found valid front
				cntVal <= cntVal + 1'b1;		// count the byte received
			end else
			if(rearVal) begin					// if ended writing byte to memory
				oAddr <= oAddr + 1'b1;			// increment address
				if(cntVal == 143) begin			// if received 144 bytes of data
					oDone <= 1'b1;				// say we are done receiving
				end
			end
		end
	end
end

endmodule
