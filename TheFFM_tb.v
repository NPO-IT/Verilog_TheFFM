`timescale 10 ps/10 ps

module TheFFM_tb();

	// Wires and variables to connect to UUT (unit under test)
	reg clk80, clk100;
	
	reg rxwire1, rxwire2, rxwire3, rxwire4;
	wire rqwire1, rqwire2, rqwire3, rqwire4;
	reg [4:0]numReq = 0;
	reg iMeasRequest;
	wire orbData;
	wire [9:0]oOrbAddr;

	
	//local variables
	reg clk5, clkOrbx4, clkOrb;
	reg [7:0]number[0:14];
	reg [2:0]i = 0;
	reg [3:0]j = 0;
	reg [2:0]i2 = 0;
	reg [3:0]j2 = 0;
	reg [2:0]i3 = 0;
	reg [3:0]j3 = 0;
	reg [2:0]i4 = 0;
	reg [3:0]j4 = 0;
	
	// Instantiate UUT
	TheFFM TheFFM_tb(
	.clk80(clk80), 
	.clk100(clk100),

	//ins
	.UART1_RX(rxwire1), 
	.UART3_RX(rxwire2), 
	.UART4_RX(rxwire3),
	.UART5_RX(rxwire4),
	.UART1_dRX(rqwire1), 
	.UART3_dRX(rqwire2), 
	.UART4_dRX(rqwire3), 
	.UART5_dRX(rqwire4),

	.Orb_serial(orbData)
	);

	// Clock definition
	initial begin						// clk 80MHz
		clk80 = 0;
		forever #625 clk80 = ~clk80;
	end
	initial begin						// clk 5MHz
		clk5=0;
		forever #10000 clk5 = ~clk5;
	end
	
	initial begin						// clk Orb 
		clkOrb=0;
		forever #15900 clkOrb = ~clkOrb;
	end
	initial begin						// clk Orb x4
		clkOrbx4=0;
		forever #3975 clkOrbx4 = ~clkOrbx4;		//#15900 = ~3145728 Hz
	end
	initial begin						// clk Orb x4
		clk100=0;
		forever #994 clk100 = ~clk100;		//#15900 = ~3145728 Hz
	end
	
	initial begin
		number[0]=85;
		number[1]=145;
		number[2]=146;
		number[3]=147;
		number[4]=148;
		number[5]=85;
		number[6]=149;
		number[7]=150;
		number[8]=151;
		number[9]=152;
		number[10]=85;
		number[11]=153;
		number[12]=154;
		number[13]=155;
		number[14]=156;
	end
	
	initial begin						// Main
		repeat (30)@(posedge clk80);
		rxwire1 = 1;
		repeat (66) begin					// 5 times
			j=0;
			wait(rqwire1 == 1);
			wait(rqwire1 == 0);
			repeat (30)@(posedge clk5);
			repeat (15) begin				// 15 bytes
				repeat(10)@(posedge clk5);
				rxwire1 = 0;
				repeat (8)					// 8 bit
				begin
					@(posedge clk5)
					rxwire1=number[j][i];
					i=i+1;
				end
				@(posedge clk5);
				rxwire1 = 1;
				j=j+1;
			end
		end
	end
	initial begin						// Main
		repeat (30)@(posedge clk80);
		rxwire2 = 1;
		repeat (66) begin					// 5 times
			j2=0;
			wait(rqwire2 == 1);
			wait(rqwire2 == 0);
			repeat (30)@(posedge clk5);
			repeat (15) begin				// 15 bytes
				repeat(10)@(posedge clk5);
				rxwire2 = 0;
				repeat (8)					// 8 bit
				begin
					@(posedge clk5)
					rxwire2=number[j2][i2];
					i2=i2+1;
				end
				@(posedge clk5);
				rxwire2 = 1;
				j2=j2+1;
			end
		end
	end
	initial begin						// Main
		repeat (30)@(posedge clk80);
		rxwire3 = 1;
		repeat (66) begin					// 5 times
			j3=0;
			wait(rqwire3 == 1);
			wait(rqwire3 == 0);
			repeat (30)@(posedge clk5);
			repeat (15) begin				// 15 bytes
				repeat(10)@(posedge clk5);
				rxwire3 = 0;
				repeat (8)					// 8 bit
				begin
					@(posedge clk5)
					rxwire3=number[j3][i3];
					i3=i3+1;
				end
				@(posedge clk5);
				rxwire3 = 1;
				j3=j3+1;
			end
		end
	end
	initial begin						// Main
		repeat (30)@(posedge clk80);
		rxwire4 = 1;
		repeat (66) begin					// 5 times
			j4=0;
			wait(rqwire4 == 1);
			wait(rqwire4 == 0);
			repeat (30)@(posedge clk5);
			repeat (15) begin				// 15 bytes
				repeat(10)@(posedge clk5);
				rxwire4 = 0;
				repeat (8)					// 8 bit
				begin
					@(posedge clk5)
					rxwire4=number[j4][i4];
					i4=i4+1;
				end
				@(posedge clk5);
				rxwire4 = 1;
				j4=j4+1;
			end
		end
		$stop;
	end
	
endmodule
