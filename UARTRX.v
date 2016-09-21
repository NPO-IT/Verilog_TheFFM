/*
	5Mbps UART receiver (8bit UART, no parity, LSB, start 0, stop 1)
	80MHz clk
	double dff included
	Ivan I. Ovchinnikov
	2016.02.25
*/

module UARTRX
	(
		input clk, reset,
		input RX,
		output reg [7:0]oData,
		output oValid
	);

	reg rx_act;
	reg Valid;
	reg [3:0]place;
	reg [7:0]data;
	reg [3:0]strtcnt;
	reg [4:0]stepcnt;
	reg [3:0]delay;

	assign oValid = Valid;
	
	reg [1:0] sync;
	wire iRX;
	assign iRX = sync[1];

	always @ (posedge clk)
	sync <= { sync[0], RX };
	
	
	always@(posedge clk or negedge reset)
	begin
	if (~reset) begin
		place <= 0;
		data <= 0;
		strtcnt <= 0;
		stepcnt <= 0;
		delay <= 0;
		rx_act <= 0;
		oData <= 0;
		Valid <= 0;
	end else begin
		if (Valid) begin
			if (delay == 4'd9) begin delay <= 0; Valid <= 0; end else begin delay <= delay + 1'b1; end
		end
		

		
		if (rx_act) begin
			if (stepcnt == 15) begin
				if (place == 8) begin
					if (iRX) begin
						Valid <= 1;
						oData <= data;
					end else begin
						data <= 8'b0;
					end
					place <= 0;
					rx_act <= 0;
				end else begin
					data[place] <= iRX;
					place <= place + 1'b1;
				end
					stepcnt <= 0;
			end else begin
				stepcnt <= stepcnt + 1'b1;
			end
		end else begin
			if ((~rx_act)&&(~iRX)) begin
				if (strtcnt == 7) begin
					rx_act <= 1'b1;
					strtcnt <= 0;
				end else begin
					strtcnt <= strtcnt + 1'b1;
				end
			end
		end
		
	end
	end

endmodule
