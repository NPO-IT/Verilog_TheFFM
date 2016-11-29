module TheFFM (
	input clk80, clk100,								// generators 80MHz and 100'663'296Hz
	// LCB 1-4
	input UART1_RX, UART3_RX, UART4_RX, UART5_RX,		// rs-485 rx
	output UART1_dRX, UART3_dRX, UART4_dRX,	UART5_dRX,	// rs-485 dirRX
	output UART1_dTX, UART3_dTX, UART4_dTX,	UART5_dTX,	// rs-485 dirTX
	output UART1_TX, UART3_TX, UART4_TX, UART5_TX,		// rs-485 tx
	// something wrong with device on uart 2
	input UART2_RX,
	output UART2_dRX,
	output UART2_dTX,
	output UART2_TX,
	// MCM UARTs
	input UART6_RX, UART7_RX,
	output UART6_dRX, UART7_dRX,
	output UART6_dTX, UART7_dTX,
	output UART6_TX, UART7_TX,
	// 
	output Orb_serial,
	output Orb_wordValid,
	
	input rt7, rt8,
	output testYellow,
	output testBlue,
	output testGreen,
	output testRed
);

//-------------------------------------------------------------------------------------------------------
// FFM connections
wire			clk12, clk5;
wire			reset;

//-------------------------------------------------------------------------------------------------------
// Orbit group buffers
wire	[9:0]	FF_RADR, LCB_RADR, LCB_OADDR; 
reg		[9:0]	MEM2_RADR, MEM1_RADR;
wire	[11:0]	MEM1_DATA, MEM2_DATA, LCB_ODATA; 
reg		[11:0]	FF_DATA, LCB_IDATA;
wire			FF_RDEN, FF_SWCH, LCB_WREN, LCB_RDEN;
reg				MEM1_RE, MEM2_RE, FF_M2_RE, FF_M1_RE, LCB_M1_RE, LCB_M2_RE;
reg				MEM1_WE, MEM2_WE;

//---------------------------------------------------------------------------------------------------------
// LCB connections
wire	[4:0]	LCB_RQ_Number;
wire 			LCB1_RQ_Signal, LCB2_RQ_Signal, LCB3_RQ_Signal, LCB4_RQ_Signal;
// inner
wire	[7:0]	LCB_rq_data3, LCB_rq_data1, LCB_rq_data2, LCB_rq_data4;
wire	[8:0]	LCB_rq_addr3, LCB_rq_addr1, LCB_rq_addr2, LCB_rq_addr4;
wire	[7:0]	LCB_rx_wire3, LCB_rx_wire1, LCB_rx_wire2, LCB_rx_wire4;
wire 			LCB_rx_val3, LCB_rx_val1, LCB_rx_val2, LCB_rx_val4;
wire	[8:0]	LCB3_ROM_addr, LCB1_ROM_addr, LCB2_ROM_addr, LCB4_ROM_addr;
wire	[14:0]	LCB3_ROM_data, LCB1_ROM_data, LCB2_ROM_data, LCB4_ROM_data;
// outer
wire	[11:0]	LCB3_ODATA, LCB1_ODATA, LCB2_ODATA, LCB4_ODATA;
wire	[9:0]	LCB3_OADDR, LCB1_OADDR, LCB2_OADDR, LCB4_OADDR;
wire			LCB3_WREN, LCB1_WREN, LCB2_WREN, LCB4_WREN;
wire	[11:0]	LCB3_IDATA, LCB1_IDATA, LCB2_IDATA, LCB4_IDATA;
wire	[9:0]	LCB3_RADR, LCB1_RADR, LCB2_RADR, LCB4_RADR;
wire			LCB3_RDEN, LCB1_RDEN, LCB2_RDEN, LCB4_RDEN;
wire			LC3_busy, LC1_busy, LC2_busy, LC4_busy;
wire			LC3_over, LC1_over, LC2_over, LC4_over;

//---------------------------------------------------------------------------------------------------------
// LCB connections
wire 			MCM_RQ_Signal;

//---------------------------------------------------------------------------------------------------------
// common
globalReset aClear(.clk(clk80), .rst(reset));	// global uber aclr imitation
defparam aClear.delayInSec = 1;
divReg clk80Divider(.reset(reset), .iClkIN(clk80), .Outdiv16(clk5)); 	// clk generator 80MHz (5MHz for UART transmissions)
divReg clk100Divider(.reset(reset), .iClkIN(clk100), .Outdiv8(clk12)); 	// clk generator 100'663'296Hz (~12,5MHz for M8-former. "Orbita Frame")

//---------------------------------------------------------------------------------------------------------
// distributor-buffer-former connectivity
always@(*)begin
	case(FF_SWCH)
		0: begin
			FF_DATA = MEM1_DATA;		//mem-to-m8 mux
			LCB_IDATA = MEM2_DATA;		//mem-to-blk mux + n0 not
			MEM1_WE = 0;				//m1w and2
			MEM2_WE = LCB_WREN;			//m2w and2 + n1 not
			MEM1_RADR = FF_RADR;		//mem1-radr mux + n2 not
			MEM2_RADR = LCB_RADR;		//mem2-radr mux
			FF_M1_RE = FF_RDEN;			//fr1 and2 + n4 not
			FF_M2_RE = 0;				//fr2 and2
			LCB_M1_RE = 0;				//lr1 and2
			LCB_M2_RE = LCB_RDEN;		//lr2 and2 + n3 not
		end
		1: begin
			FF_DATA = MEM2_DATA;		//mem-to-m8 mux
			LCB_IDATA = MEM1_DATA;		//mem-to-blk mux + n0 not
			MEM2_WE = 0;				//m2w and2 + n1 not
			MEM1_WE = LCB_WREN;			//m1w and2
			MEM2_RADR = FF_RADR;		//mem2-radr mux
			MEM1_RADR = LCB_RADR;		//mem1-radr mux + n2 not
			FF_M2_RE = FF_RDEN;			//fr2 and2
			FF_M1_RE = 0;				//fr1 and2 + n4 not
			LCB_M2_RE = 0;				//lr2 and2 + n3 not
			LCB_M1_RE = LCB_RDEN;		//lr1 and2
		end
	endcase
	MEM1_RE = FF_M1_RE | LCB_M1_RE;		//m1r or2
	MEM2_RE = FF_M2_RE | LCB_M2_RE;		//m2r or2
end

//---------------------------------------------------------------------------------------------------------
// group buffers and former
memGrp groupBuf0(.clock(clk80), .data(LCB_ODATA), .rdaddress(MEM1_RADR), .rden(MEM1_RE), .wraddress(LCB_OADDR), .wren(MEM1_WE), .q(MEM1_DATA));
memGrp groupBuf1(.clock(clk80), .data(LCB_ODATA), .rdaddress(MEM2_RADR), .rden(MEM2_RE), .wraddress(LCB_OADDR), .wren(MEM2_WE), .q(MEM2_DATA));
M8 frameFormer( .reset(reset), .clk(clk12),	// 12'582'912
	.iData(FF_DATA),						// orbWord [11:0]
	.oSwitch(FF_SWCH),						// global Mem Switcher
	.oRdEn(FF_RDEN),						// read from mem
	.oAddr(FF_RADR),						// [9:0] global read address
	.oSerial(Orb_serial),					// OUTPUT SIGNAL
	.oParallel(Orb_parallel),				// [11:0] OUTPUT PARALLEL
	.oValid(Orb_wordValid),					// output VALID
	.oLCB1_rq(LCB1_RQ_Signal),				// request signal for UARTTX
	.oLCB2_rq(LCB2_RQ_Signal),				// request signal for UARTTX
	.oLCB3_rq(LCB3_RQ_Signal),				// request signal for UARTTX
	.oLCB4_rq(LCB4_RQ_Signal),				// request signal for UARTTX
	.oLCB_num(LCB_RQ_Number),				// [4:0]NumRQ
	.oMCM_rq(MCM_RQ_Signal),
);

//---------------------------------------------------------------------------------------------------------
// LOCAL COMMUTATION BLOCKS
UARTTXBIG rqLCB1(.reset(reset), .clk(clk5), .RQ(LCB1_RQ_Signal), .cycle(LCB_RQ_Number + 1'b1), .data(LCB_rq_data1), .addr(LCB_rq_addr1), .tx(UART1_TX), .dirTX(UART1_dTX), .dirRX(UART1_dRX));
defparam rqLCB1.BYTES = 5'd14;
ROMr1 r1(.address(LCB_rq_addr1), .inclock(clk80), .outclock(clk80), .q(LCB_rq_data1));
UARTRX rxLCB1(.clk(clk80), .reset(reset), .RX(UART1_RX), .oData(LCB_rx_wire1), .oValid(LCB_rx_val1));
lcbFull lc1(
	.clk(clk80), .reset(reset),
	.rawData(LCB_rx_wire1), .rxValid(LCB_rx_val1), .LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB1_ODATA), .wrdAddr(LCB1_OADDR), .wren(LCB1_WREN),
	.oldWrd(LCB1_IDATA), .oldWrdAddr(LCB1_RADR), .oldRdEn(LCB1_RDEN),
	.overallBusy(LC1_over), .busy(LC1_busy),
	.addrROMaddr(LCB1_ROM_addr), .dataROMaddr(LCB1_ROM_data)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr1 a1(.address(LCB1_ROM_addr), .inclock(clk80), .outclock(clk80), .q(LCB1_ROM_data));

//---------------------------------------------------------------------------------------------------------
UARTTXBIG rqLCB2(.reset(reset), .clk(clk5), .RQ(LCB2_RQ_Signal), .cycle(LCB_RQ_Number + 1'b1), .data(LCB_rq_data2), .addr(LCB_rq_addr2), .tx(UART3_TX), .dirTX(UART3_dTX), .dirRX(UART3_dRX));
defparam rqLCB2.BYTES = 5'd14;
ROMr2 r2(.address(LCB_rq_addr2), .inclock(clk80), .outclock(clk80), .q(LCB_rq_data2));
UARTRX rxLCB2(.clk(clk80), .reset(reset), .RX(UART3_RX), .oData(LCB_rx_wire2), .oValid(LCB_rx_val2));
lcbFull lc2(
	.clk(clk80), .reset(reset),
	.rawData(LCB_rx_wire2), .rxValid(LCB_rx_val2), .LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB2_ODATA), .wrdAddr(LCB2_OADDR), .wren(LCB2_WREN),
	.oldWrd(LCB2_IDATA), .oldWrdAddr(LCB2_RADR), .oldRdEn(LCB2_RDEN),
	.overallBusy(LC2_over), .busy(LC2_busy),
	.addrROMaddr(LCB2_ROM_addr), .dataROMaddr(LCB2_ROM_data)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr2 a2(.address(LCB2_ROM_addr), .inclock(clk80), .outclock(clk80), .q(LCB2_ROM_data));

//---------------------------------------------------------------------------------------------------------
UARTTXBIG rqLCB3(.reset(reset), .clk(clk5), .RQ(LCB3_RQ_Signal), .cycle(LCB_RQ_Number + 1'b1), .data(LCB_rq_data3), .addr(LCB_rq_addr3), .tx(UART4_TX), .dirTX(UART4_dTX), .dirRX(UART4_dRX));
defparam rqLCB3.BYTES = 5'd14;
ROMr3 r3(.address(LCB_rq_addr3), .inclock(clk80), .outclock(clk80), .q(LCB_rq_data3));
UARTRX rxLCB3(.clk(clk80), .reset(reset), .RX(UART4_RX), .oData(LCB_rx_wire3), .oValid(LCB_rx_val3));
lcbFull lc3(
	.clk(clk80), .reset(reset),
	.rawData(LCB_rx_wire3), .rxValid(LCB_rx_val3), .LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB3_ODATA), .wrdAddr(LCB3_OADDR), .wren(LCB3_WREN),
	.oldWrd(LCB3_IDATA), .oldWrdAddr(LCB3_RADR), .oldRdEn(LCB3_RDEN),
	.overallBusy(LC3_over), .busy(LC3_busy),
	.addrROMaddr(LCB3_ROM_addr), .dataROMaddr(LCB3_ROM_data)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr3 a3(.address(LCB3_ROM_addr), .inclock(clk80), .outclock(clk80), .q(LCB3_ROM_data));

//---------------------------------------------------------------------------------------------------------
UARTTXBIG rqLCB4(.reset(reset), .clk(clk5), .RQ(LCB4_RQ_Signal), .cycle(LCB_RQ_Number + 1'b1), .data(LCB_rq_data4), .addr(LCB_rq_addr4), .tx(UART5_TX), .dirTX(UART5_dTX), .dirRX(UART5_dRX));
defparam rqLCB4.BYTES = 5'd14;
ROMr4 r4(.address(LCB_rq_addr4), .inclock(clk80), .outclock(clk80), .q(LCB_rq_data4));
UARTRX rxLCB4(.clk(clk80), .reset(reset), .RX(UART5_RX), .oData(LCB_rx_wire4), .oValid(LCB_rx_val4));
lcbFull lc4(
	.clk(clk80), .reset(reset),
	.rawData(LCB_rx_wire4), .rxValid(LCB_rx_val4), .LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB4_ODATA), .wrdAddr(LCB4_OADDR), .wren(LCB4_WREN),
	.oldWrd(LCB4_IDATA), .oldWrdAddr(LCB4_RADR), .oldRdEn(LCB4_RDEN),
	.overallBusy(LC4_over), .busy(LC4_busy),
	.addrROMaddr(LCB4_ROM_addr), .dataROMaddr(LCB4_ROM_data)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr4 a4(.address(LCB4_ROM_addr), .inclock(clk80), .outclock(clk80), .q(LCB4_ROM_data));

//---------------------------------------------------------------------------------------------------------
// on-board calculating Machine Coordination Module
wire			LCB_busy;
wire			MCM_busy;
wire	[7:0]	MCM_rq_data;
wire	[3:0]	MCM_rq_addr;
wire 			MCM_rx_valid;
wire	[7:0]	MCM_rx_data;
wire	[7:0]	MCM_rx_addr;
wire			MCM_rx_done;
wire	[7:0]	MCM_dat;
wire	[11:0]	MCM_ODATA;
wire	[9:0]	MCM_OADDR;
wire			MCM_WREN;
wire	[7:0]	MCM_buf_addr;
wire			MCM_buf_rden;

assign LCB_busy = LC1_over | LC2_over | LC3_over | LC4_over;

UARTTXBIG rqMCM(.reset(reset), .clk(clk5), .RQ(MCM_RQ_Signal), .cycle(0), .data(MCM_rq_data), .addr(MCM_rq_addr), .tx(UART7_TX), .dirTX(UART7_dTX), .dirRX(UART7_dRX));
defparam rqMCM.BYTES = 5'd8;
ROMmcm mcm(.address(MCM_rq_addr), .inclock(clk80), .outclock(clk80), .q(MCM_rq_data));
UARTRX rxMCM(.clk(clk80), .reset(reset), .RX(UART7_RX), .oData(MCM_rx_data), .oValid(MCM_rx_valid));
MCM_coord mcmc(
	.clk(clk80),
	.reset(reset),
	.iRQ(MCM_RQ_Signal),
	.iVal(MCM_rx_valid),
	.oAddr(MCM_rx_addr),
	.oDone(MCM_rx_done)
);

MCM_rx_RAM (
	.clock(clk80),
	.data(MCM_rx_data),
	.rdaddress(MCM_buf_addr),
	.rden(MCM_buf_rden),
	.wraddress(MCM_rx_addr),
	.wren(MCM_rx_valid),
	.q(MCM_dat)
);

MCM_pack mcmp(
	.clk(clk80),
	.reset(reset),
	.iDone(MCM_rx_done),
	.iData(MCM_dat),
	.oRdAddr(MCM_buf_addr),
	.oRdEn(MCM_buf_rden),
	
	.iBusy(LCB_busy),				// busy signal from lcb's
	.oData(MCM_ODATA),				// [11:0]
	.oAddr(MCM_OADDR),				// [9:0]
	.oWren(MCM_WREN),			// wren & busy to distributor
	
	.oBusy(MCM_busy)			// packer is busy writing to memory
);

//---------------------------------------------------------------------------------------------------------
Distributor modelsim_9(
	//basic
	.clk(clk80),
	.reset(reset),
	//busy signals
	.busy_1(LC1_busy), .busy_2(LC2_busy), .busy_3(LC3_busy), .busy_4(LC4_busy),
	.busy_5(MCM_busy),
	//common inouts
	.commWrdOut(LCB_ODATA), .commWrdAddr(LCB_OADDR), .commWren(LCB_WREN), .commOldWrd(LCB_IDATA), .commOldWrdAddr(LCB_RADR), .commOldRdEn(LCB_RDEN),
	//LCB 1-4 inouts
	.wrdOut_1(LCB1_ODATA), .wrdAddr_1(LCB1_OADDR), .wren_1(LCB1_WREN), .oldWrd_1(LCB1_IDATA), .oldWrdAddr_1(LCB1_RADR), .oldRdEn_1(LCB1_RDEN),
	.wrdOut_2(LCB2_ODATA), .wrdAddr_2(LCB2_OADDR), .wren_2(LCB2_WREN), .oldWrd_2(LCB2_IDATA), .oldWrdAddr_2(LCB2_RADR), .oldRdEn_2(LCB2_RDEN),
	.wrdOut_3(LCB3_ODATA), .wrdAddr_3(LCB3_OADDR), .wren_3(LCB3_WREN), .oldWrd_3(LCB3_IDATA), .oldWrdAddr_3(LCB3_RADR), .oldRdEn_3(LCB3_RDEN),
	.wrdOut_4(LCB4_ODATA), .wrdAddr_4(LCB4_OADDR), .wren_4(LCB4_WREN), .oldWrd_4(LCB4_IDATA), .oldWrdAddr_4(LCB4_RADR), .oldRdEn_4(LCB4_RDEN),
	//MCM inouts
	.wrdOut_m(MCM_ODATA), .wrdAddr_m(MCM_OADDR), .wren_m(MCM_WREN)
);


assign testGreen = LC3_over;			//ch2
assign testBlue = MCM_busy;			//ch3
assign testYellow = MCM_buf_rden;		//ch1
assign testRed = MCM_RQ_Signal;			//ch4


endmodule
