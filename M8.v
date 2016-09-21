module M8(
/*???????? ?????????, ???????????? ? ?????????? ??????*/
	input reset,
	input clk,										// 12'582'912
	input [11:0]iData,
/*?????????? ??????? ? ??????????? (?????? ?8)*/
	output reg oSwitch,
	output reg oRdEn,
	output reg [9:0]oAddr,
/*????? ???????????????? ????? ?????? ?8 ? ???????????????? ? ???????????? ?????*/	
	output reg oSerial,
	output reg [11:0]oParallel,
	output reg oValid,
/*??????? ???????? ??? ???*/	
	output reg oLCB1_rq,
	output reg oLCB2_rq,
	output reg oLCB3_rq,
	output reg oLCB4_rq,
	output reg [4:0]oLCB_num
);
reg [23:0]outWrd;
reg [1:0]cntDiv;
reg [4:0]cntBit;
reg [2:0]cntWrd;
reg [6:0]cntPhr;
reg [4:0]cntGrp;
reg [9:0]cntMem;
reg [1:0]cntCcl;
wire [23:0]iDoubled;
reg [3:0]cnt1Sec;
reg [3:0]cnt10Sec;
reg [3:0]cnt100Sec;
reg [3:0]cnt1000Sec;
reg [11:0]cntLCBrq;
wire [11:0]oSingled;

assign iDoubled = {iData[11],iData[11],iData[10],iData[10],iData[9],iData[9],iData[8],iData[8],iData[7],iData[7],iData[6],iData[6],iData[5],iData[5],iData[4],iData[4],iData[3],iData[3],iData[2],iData[2],iData[1],iData[1],iData[0],iData[0]};
assign oSingled = {outWrd[22], outWrd[20], outWrd[18], outWrd[16], outWrd[14], outWrd[12], outWrd[10], outWrd[8], outWrd[6], outWrd[4], outWrd[2], outWrd[0]};

always@(posedge clk or negedge reset) begin



if (~reset) begin // initial
	cntDiv <= 1;
	cntBit <= 0;
	cntWrd <= 0;
	cntPhr <= 0;
	cntGrp <= 0;
	cntMem <= 1;
	cntCcl <= 0;
	cnt1Sec <= 0;
	cnt10Sec <= 0;
	cnt100Sec <= 0;
	cnt1000Sec <= 0;
	cntLCBrq <= 0;
	oLCB_num <= 0;
	oLCB1_rq <= 0;
	oLCB2_rq <= 0;
	oLCB3_rq <= 0;
	oLCB4_rq <= 0;
	oSwitch <= 0;
	oParallel <= 0;
	oSerial <= 0;
	oValid <= 0;
end else begin	// main
	cntDiv <= cntDiv + 1'b1;
	case (cntDiv)									// ???? ? ?????????
		0: 	begin
			oSerial <= outWrd[(23-cntBit)];			// set out digit
			if (cntBit == 0) begin
				oParallel <= oSingled;
				oValid <= 1;
			end else oValid <= 0;
		end
		1:	begin
			if (cntBit == 23) begin					// on last bit
				oAddr <= cntMem;
				oRdEn <= 1;							// prepare to read next word
				outWrd <= 24'd0;					// clear the word
			end
			cntBit <= cntBit + 1'b1;				// count to next bit
		end
		2:	if (cntBit == 24) begin					// on last bit of word
				cntBit <= 0;						// reset the bit counter
				outWrd <= iDoubled;					// change the word
			
								/*count address for reading*/
				if (cntMem == 0) begin oSwitch <= ~oSwitch; end 
				cntMem <= cntMem + 1'b1;			// count 1024 words of memory
				
								/*count all markers*/
				cntWrd <= cntWrd + 1'b1;
				if (cntWrd == 7) begin		// 8 ???? = 1 ?????
					cntPhr <= cntPhr + 1'b1;
					if (cntPhr == 127) begin		// 128 ???? = 1 ??????
						cntGrp <= cntGrp + 1'b1;
						if (cntGrp == 31) begin		// 32 ?????? = 1 ????
							cntCcl <= cntCcl + 1'b1;
							if (cntCcl == 3) begin		// 4 ????? = 1 ???? = 1 ???????
								cnt1Sec <= cnt1Sec + 1'b1;
								if (cnt1Sec == 9) begin		// ??????? ??????? ??????
									cnt1Sec <= 0;
									if (cnt10Sec == 9) begin	// ??????? ????? ??????
										cnt10Sec <= 0;
										if (cnt100Sec == 9) begin		// ??????? ?????? ??????
											cnt100Sec <= 0;
											if (cnt1000Sec == 9) begin
												cnt1000Sec <= 0; 
											end else begin cnt1000Sec <= cnt1000Sec + 1'b1; end
										end else begin cnt100Sec <= cnt100Sec + 1'b1; end
									end else begin cnt10Sec <= cnt10Sec + 1'b1; end
								end 
							end 
						end 
					end 
				end 
			end
		3: begin
			oRdEn <= 0;
								/*all marker conditions here*/
			if (cntBit == 0) begin					
				case (cntPhr)							// ??????? ?????
					0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102,104,106,108,110,112,114,116,118,120,122,124,126:
					if (cntWrd == 0) begin outWrd <= (outWrd | 24'b100000000000000000000000); end
				endcase
				case (cntGrp)
					31:	begin							// ?????? ?????

						case (cntPhr)
							113,121,123,127: if (cntWrd == 0) begin outWrd <= (outWrd | 24'b110000000000000000000000); 	end
						endcase
					end
					default: begin						// ??????? ??????
			
						case (cntPhr)
							115,117,119,125: if (cntWrd == 0) begin outWrd <= (outWrd | 24'b110000000000000000000000); end
						endcase
					end
				endcase
				case (cntCcl)							// ?????? ?????
					0:	if (cntGrp == 0)
							if (cntPhr == 15)
								if (cntWrd == 0) begin outWrd <= (outWrd | 24'b110000000000000000000000); end
				endcase
			end
			cntDiv <= 0;
		end
	endcase

/*LCB request*/
	cntLCBrq <= cntLCBrq + 1'b1;
	case (cntLCBrq)
		0: oLCB1_rq <= 1;
		20: oLCB1_rq <= 0;
		600: oLCB2_rq <= 1;
		620: oLCB2_rq <= 0;
		1200: oLCB3_rq <= 1;
		1220: oLCB3_rq <= 0;
		1800: oLCB4_rq <= 1;
		1820: oLCB4_rq <= 0;
		3021: oLCB_num <= oLCB_num + 1'b1;
		3071: cntLCBrq <= 0;
	endcase


end
end
endmodule
