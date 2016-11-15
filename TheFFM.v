module TheFFM (
	input clk80, clk100,								// generators 80MHz and 100'663'296Hz
	// LCB
	input UART1_RX, UART3_RX, UART4_RX,			// rs-485 rx
	output UART1_dRX, UART3_dRX, UART4_dRX,		// rs-485 dirRX
	output UART1_dTX, UART3_dTX, UART4_dTX,		// rs-485 dirTX
	output UART1_TX, UART3_TX, UART4_TX,		// rs-485 tx
	input UART2_RX,
	output UART2_dRX,
	output UART2_dTX,
	output UART2_TX,
	// other UARTs
	input UART5_RX,
	output UART5_dRX,
	output UART5_dTX,
	output UART5_TX,
	// MCM UARTs
	input UART6_RX,
	output UART6_dRX,
	output UART6_dTX,
	output UART6_TX,
	//
	output Orb_serial,
	output Orb_wordValid,
	
	input rt7, rt8,
	output testYellow,
	output testBlue,
	output testGreen,
	output testRed
);
wire clk12, clk5;
wire reset;

globalReset aClear(.clk(clk80), .rst(reset));	// global uber aclr imitation
defparam aClear.delayInSec = 1;
defparam aClear.clockFreq = 8;//80000000;//8;		//super-fast-reset-for-simulation

divReg clk80Divider(.reset(reset), .iClkIN(clk80), .Outdiv16(clk5)); 	// clk generator 80MHz (5MHz for UART transmissions)
divReg clk100Divider(.reset(reset), .iClkIN(clk100), .Outdiv8(clk12)); 	// clk generator 100'663'296Hz (~12,5MHz for M8-former. "Orbita Frame")

//-------------------------------------------------------------------------------------------------------
wire [4:0]LCB_RQ_Number;
wire [9:0]FF_RADR, LCB_RADR, LCB_OADDR; 
reg [9:0]MEM2_RADR, MEM1_RADR;
wire [11:0]MEM1_DATA, MEM2_DATA, LCB_ODATA; 
reg [11:0]FF_DATA, LCB_IDATA;
wire FF_RDEN, FF_SWCH, LCB_WREN, LCB_RDEN;
reg MEM1_RE, MEM2_RE, FF_M2_RE, FF_M1_RE, LCB_M1_RE, LCB_M2_RE;
reg MEM1_WE, MEM2_WE;

wire LC1_BUSY, LC3_BUSY;
wire[9:0]LCB1_RADR, LCB2_RADR, LCB3_RADR, LCB4_RADR;
wire[9:0]LCB1_OADDR, LCB2_OADDR, LCB3_OADDR, LCB4_OADDR;
wire[11:0]LCB1_ODATA, LCB2_ODATA, LCB3_ODATA, LCB4_ODATA; 
wire[11:0]LCB1_IDATA, LCB2_IDATA, LCB3_IDATA, LCB4_IDATA;
wire LCB1_WREN, LCB2_WREN, LCB3_WREN, LCB4_WREN;
wire LCB1_RDEN, LCB2_RDEN, LCB3_RDEN, LCB4_RDEN;
wire MCM_RQ;

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

memGrp groupBuf0(.clock(clk80), .data(LCB_ODATA), .rdaddress(MEM1_RADR), .rden(MEM1_RE), .wraddress(LCB_OADDR), .wren(MEM1_WE), .q(MEM1_DATA));
memGrp groupBuf1(.clock(clk80), .data(LCB_ODATA), .rdaddress(MEM2_RADR), .rden(MEM2_RE), .wraddress(LCB_OADDR), .wren(MEM2_WE), .q(MEM2_DATA));
M8 frameFormer( .reset(reset), .clk(clk12),	// 12'582'912
	.iData(/*12'd340*/FF_DATA),						// orbWord [11:0]
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
	.oMCM_rq(MCM_RQ),
	.oLCB_num(LCB_RQ_Number)				// [4:0]NumRQ
);
//---------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
// LCB-3 FULL IN/OUT

wire [7:0]LCB_rq_data3;
wire [8:0]LCB_rq_addr3;
wire [7:0]LCB_rx_wire3;
wire LCB_rx_val3;
wire [8:0]LCB_ROM_addr3;
wire [14:0]LCB_ROM_data3;
wire combinetest;

UARTTXBIG rqLCB3(
	.reset(reset),					// global reset and enable signal
	.clk(clk5),						// actual needed baudrate
	.RQ(LCB3_RQ_Signal),			// start transfer signal
	.cycle(LCB_RQ_Number + 1'b1),	// number of the request (from m8) + shift, to give LCB time to respond
	.data(LCB_rq_data3),			// data to transmit (from ROM)
	.addr(LCB_rq_addr3),			// address to read (to ROM)
	.tx(UART4_TX),					// serial transmitted data
	.dirTX(UART4_dTX),				// rs485 TX dir controller 
	.dirRX(UART4_dRX)				// rs485 RX dir controller
);
defparam rqLCB3.BYTES = 5'd14;

ROMr3 modelsim_1( 
	.address(LCB_rq_addr3),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_rq_data3)
);

UARTRX rxLCB3(
	.clk(clk80), 			
	.reset(reset),
	.RX(UART4_RX),				// serial wire
	.oData(LCB_rx_wire3),		// parallel data
	.oValid(LCB_rx_val3)		// data is valid while this signal is 1
);

lcbFull lc3(
	.clk(clk80),
	.reset(reset),
	.rawData(LCB_rx_wire3),
	.rxValid(LCB_rx_val3),
	.LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB3_ODATA),
	.wrdAddr(LCB3_OADDR),
	.wren(LCB3_WREN),
	.busy(LC3_BUSY),
	.addrROMaddr(LCB_ROM_addr3),
	.dataROMaddr(LCB_ROM_data3),
	.oldWrd(LCB3_IDATA),
	.oldWrdAddr(LCB3_RADR),
	.oldRdEn(LCB3_RDEN)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr3 modelsim_2(
	.address(LCB_ROM_addr3),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_ROM_data3)
);

//---------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
// LCB-1 FULL IN/OUT
wire [7:0]LCB_rq_data1;
wire [8:0]LCB_rq_addr1;
wire [7:0]LCB_rx_wire1;
wire LCB_rx_val1;
wire [8:0]LCB_ROM_addr1;
wire [14:0]LCB_ROM_data1;

UARTTXBIG rqLCB1(
	.reset(reset),					// global reset and enable signal
	.clk(clk5),						// actual needed baudrate
	.RQ(LCB1_RQ_Signal),			// start transfer signal
	.cycle(LCB_RQ_Number + 1'b1),	// number of the request (from m8) + shift, to give LCB time to respond
	.data(LCB_rq_data1),			// data to transmit (from ROM)
	.addr(LCB_rq_addr1),			// address to read (to ROM)
	.tx(UART1_TX),					// serial transmitted data
	.dirTX(UART1_dTX),				// rs485 TX dir controller 
	.dirRX(UART1_dRX)				// rs485 RX dir controller
);
defparam rqLCB1.BYTES = 5'd14;

ROMr1 modelsim_3( 
	.address(LCB_rq_addr1),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_rq_data1)
);

UARTRX rxLCB1(
	.clk(clk80), 			
	.reset(reset),
	.RX(UART1_RX),				// serial wire
	.oData(LCB_rx_wire1),		// parallel data
	.oValid(LCB_rx_val1)		// data is valid while this signal is 1
);

lcbFull lc1(
	.clk(clk80),
	.reset(reset),
	.rawData(LCB_rx_wire1),
	.rxValid(LCB_rx_val1),
	.LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB1_ODATA),
	.wrdAddr(LCB1_OADDR),
	.wren(LCB1_WREN),
	.busy(LC1_BUSY),
	.addrROMaddr(LCB_ROM_addr1),
	.dataROMaddr(LCB_ROM_data1),
	.oldWrd(LCB1_IDATA),
	.oldWrdAddr(LCB1_RADR),
	.oldRdEn(LCB1_RDEN)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr1 modelsim_4(
	.address(LCB_ROM_addr1),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_ROM_data1)
);

//---------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
// LCB-1 FULL IN/OUT
wire [7:0]LCB_rq_data4;
wire [8:0]LCB_rq_addr4;
wire [7:0]LCB_rx_wire4;
wire LCB_rx_val4;
wire [8:0]LCB_ROM_addr4;
wire [14:0]LCB_ROM_data4;

UARTTXBIG rqLCB4(
	.reset(reset),					// global reset and enable signal
	.clk(clk5),						// actual needed baudrate
	.RQ(LCB4_RQ_Signal),			// start transfer signal
	.cycle(LCB_RQ_Number + 1'b1),	// number of the request (from m8) + shift, to give LCB time to respond
	.data(LCB_rq_data4),			// data to transmit (from ROM)
	.addr(LCB_rq_addr4),			// address to read (to ROM)
	.tx(UART5_TX),					// serial transmitted data
	.dirTX(UART5_dTX),				// rs485 TX dir controller 
	.dirRX(UART5_dRX)				// rs485 RX dir controller
);
defparam rqLCB4.BYTES = 5'd14;

ROMr4 modelsim_5( 
	.address(LCB_rq_addr4),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_rq_data4)
);

UARTRX rxLCB4(
	.clk(clk80), 			
	.reset(reset),
	.RX(UART5_RX),				// serial wire
	.oData(LCB_rx_wire4),		// parallel data
	.oValid(LCB_rx_val4)		// data is valid while this signal is 1
);

lcbFull lc4(
	.clk(clk80),
	.reset(reset),
	.rawData(LCB_rx_wire4),
	.rxValid(LCB_rx_val4),
	.LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB4_ODATA),
	.wrdAddr(LCB4_OADDR),
	.wren(LCB4_WREN),
	.busy(LC4_BUSY),
	.addrROMaddr(LCB_ROM_addr4),
	.dataROMaddr(LCB_ROM_data4),
	.oldWrd(LCB4_IDATA),
	.oldWrdAddr(LCB4_RADR),
	.oldRdEn(LCB4_RDEN)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr4 modelsim_6(
	.address(LCB_ROM_addr4),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_ROM_data4)
);

//---------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
// LCB-2 FULL IN/OUT
wire [7:0]LCB_rq_data2;
wire [8:0]LCB_rq_addr2;
wire [7:0]LCB_rx_wire2;
wire LCB_rx_val2;
wire [8:0]LCB_ROM_addr2;
wire [14:0]LCB_ROM_data2;

UARTTXBIG rqLCB2(
	.reset(reset),					// global reset and enable signal
	.clk(clk5),						// actual needed baudrate
	.RQ(LCB2_RQ_Signal),			// start transfer signal
	.cycle(LCB_RQ_Number + 1'b1),	// number of the request (from m8) + shift, to give LCB time to respond
	.data(LCB_rq_data2),			// data to transmit (from ROM)
	.addr(LCB_rq_addr2),			// address to read (to ROM)
	.tx(UART3_TX),					// serial transmitted data
	.dirTX(UART3_dTX),				// rs485 TX dir controller 
	.dirRX(UART3_dRX)				// rs485 RX dir controller
);
defparam rqLCB2.BYTES = 5'd14;

ROMr2 modelsim_7( 
	.address(LCB_rq_addr2),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_rq_data2)
);

UARTRX rxLCB2(
	.clk(clk80), 			
	.reset(reset),
	.RX(UART3_RX),				// serial wire
	.oData(LCB_rx_wire2),		// parallel data
	.oValid(LCB_rx_val2)		// data is valid while this signal is 1
);

lcbFull lc2(
	.clk(clk80),
	.reset(reset),
	.rawData(LCB_rx_wire2),
	.rxValid(LCB_rx_val2),
	.LCBrqNumber(LCB_RQ_Number),
	.wrdOut(LCB2_ODATA),
	.wrdAddr(LCB2_OADDR),
	.wren(LCB2_WREN),
	.busy(LC2_BUSY),
	.addrROMaddr(LCB_ROM_addr2),
	.dataROMaddr(LCB_ROM_data2),
	.oldWrd(LCB2_IDATA),
	.oldWrdAddr(LCB2_RADR),
	.oldRdEn(LCB2_RDEN)
);
// this memory knows, where to put received from UART data: 14 a/c, 13..3 orbAddr, 3..0 if (~14) place in orbit Word
LCBaddr2 modelsim_8(
	.address(LCB_ROM_addr2),
	.inclock(clk80),
	.outclock(clk80),
	.q(LCB_ROM_data2)
);

//-----------------------03.10.2016 update-vvvvvvvv--------------
Distributor modelsim_9(
	//basic
	.clk(clk80),
	.reset(reset),
	//busy
	.busy_1(LC3_BUSY),
	.busy_2(LC1_BUSY),
	.busy_3(LC4_BUSY),
	.busy_4(LC2_BUSY),
	//common inouts
	.commWrdOut(LCB_ODATA),
	.commWrdAddr(LCB_OADDR),
	.commWren(LCB_WREN),
	.commOldWrd(LCB_IDATA),
	.commOldWrdAddr(LCB_RADR),
	.commOldRdEn(LCB_RDEN),
	//individual inouts
	.wrdOut_1(LCB3_ODATA),
	.wrdAddr_1(LCB3_OADDR),
	.wren_1(LCB3_WREN),
	.oldWrd_1(LCB3_IDATA),
	.oldWrdAddr_1(LCB3_RADR),
	.oldRdEn_1(LCB3_RDEN),
	//individual inouts
	.wrdOut_2(LCB1_ODATA),
	.wrdAddr_2(LCB1_OADDR),
	.wren_2(LCB1_WREN),
	.oldWrd_2(LCB1_IDATA),
	.oldWrdAddr_2(LCB1_RADR),
	.oldRdEn_2(LCB1_RDEN),
	//individual inouts
	.wrdOut_3(LCB4_ODATA),
	.wrdAddr_3(LCB4_OADDR),
	.wren_3(LCB4_WREN),
	.oldWrd_3(LCB4_IDATA),
	.oldWrdAddr_3(LCB4_RADR),
	.oldRdEn_3(LCB4_RDEN),
	//individual inouts
	.wrdOut_4(LCB2_ODATA),
	.wrdAddr_4(LCB2_OADDR),
	.wren_4(LCB2_WREN),
	.oldWrd_4(LCB2_IDATA),
	.oldWrdAddr_4(LCB2_RADR),
	.oldRdEn_4(LCB2_RDEN)
);

reg [7:0]MCM_Addr, MCM_rd;
reg [7:0]MCM_Data, MCM_Byte;
wire MCM_Valid, MCM_Done, MCM_re;
reg [11:0]MCM_ODATA;
reg [9:0]MCM_OADDR;
reg MCM_WREN
wire LC_BUSY;
assign LC_BUSY = LC1_BUSY | LC2_BUSY | LC3_BUSY | LC4_BUSY;

UARTRX rxLCB2(
	.clk(clk80), 			
	.reset(reset),
	.RX(UART6_RX),				// serial wire on UART6
	.oData(MCM_Data),			// parallel data
	.oValid(MCM_Valid)			// data is valid while this signal is 1
);

MCM ram_MSB(
	.clock(clk80),
	.data(MCM_Data),			// from receiver
	.rdaddress(MCM_rd),			// rdaddress from coordinator
	.rden(MCM_re),				// rden from packer
	.wraddress(MCM_Addr),		// wraddress from receiver
	.wren(MCM_Valid),			// wren from receiver
	.q(MCM_Byte)				// to packer
);

MCM_coord modelsim_10(
	.clk(clk80),
	.reset(reset),
	.iRQ(MCM_RQ),				// sync reset from m8
	.iVal(MCM_Valid),			// valid from receiver
	.oAddr(MCM_Addr),			// address for RAM
	.oDone(MCM_Done)			// done to packer
);

MCM_pack modelsim_11(
	.clk(clk80),
	.reset(reset),
	.iDone(MCM_Done),			// done from coordinator (start reading)
	.iData(MCM_Byte),			// data from RAM
	.oRdAddr(MCM_rd),			// address to RAM
	.oRdEn(MCM_re),				// rden from RAM
	.iBusy(LC_BUSY),			// busy signal from lcb's
	.oData(MCM_ODATA),			// data to GROUP distributor(orbit words)
	.oAddr(MCM_OADDR),			// address to group distributor (orbit addresses)
	.oWren(MCM_WREN)			// wren & busy to distributor
);

assign testGreen = LC1_BUSY;		//ch4
assign testBlue = LC3_BUSY;			//ch2
assign testYellow = LCB_rx_val3;	//ch1
assign testRed = LC4_BUSY;			//ch3

endmodule
