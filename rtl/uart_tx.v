`default_nettype none
module uart_tx #(parameter
	WIDTH   = 8 ,
	SB_TICK = 16
) (
	input  wire             clk, rst, tx_start, s_tick,
	input  wire [WIDTH-1:0] din         ,
	output reg              tx_done_tick,
	output wire             tx
);

	localparam [1:0] idle = 2'b00,start=2'b01,data=2'b10,stop=2'b11;

	reg [                1:0] state_reg ;
	reg [                1:0] state_next;
	reg [$clog2(SB_TICK)-1:0] s_reg     ;
	reg [$clog2(SB_TICK)-1:0] s_next    ;
	reg [  $clog2(WIDTH)-1:0] n_reg     ;
	reg [  $clog2(WIDTH)-1:0] n_next    ;
	reg [          WIDTH-1:0] b_reg     ;
	reg [          WIDTH-1:0] b_next    ;
	reg                       tx_reg    ;
	reg                       tx_next   ;

	always @ (posedge clk, posedge rst)
		if (rst)
			begin
				state_reg <= idle;
				s_reg     <= 0;
				n_reg     <= 0;
				b_reg     <= 0;
				tx_reg    <= 1'b1;
			end
		else
			begin
				state_reg <= state_next;
				s_reg     <= s_next;
				n_reg     <= n_next;
				b_reg     <= b_next;
				tx_reg    <= tx_next;
			end

	always @*
		begin
			state_next   = state_reg;
			tx_done_tick = 1'b0;
			s_next       = s_reg;
			n_next       = n_reg;
			b_next       = b_reg;
			tx_next      = tx_reg;
			case (state_reg)
				idle :
					begin
						tx_next = 1'b1;
						if (tx_start)
							begin
								state_next = start;
								s_next     = 0;
								b_next     = din;
							end
					end
				start :
					begin
						tx_next = 1'b0;
						if (s_tick)
							if (s_reg==7)
								begin
									state_next = data;
									s_next     = 0;
									n_next     = 0;
									$display("hena");
								end
						else
							s_next = s_reg + 1;
					end
				data :
					begin
						// tx_next = b_reg[0];
						if (s_tick)
							if (s_reg==15)
								begin
									s_next  = 0;
									// b_next = b_reg >> 1;
									tx_next = din[n_reg];
									if (n_reg==(WIDTH-1))
										begin
											$display("bit rakam %d, tx_next is %d",n_next,tx_next);
											state_next = stop;
										end
									else
										begin
											n_next = n_reg + 1;
											$display("bit rakam %d, tx_next is %d",n_next,tx_next);
										end

								end
						else
							s_next = s_reg + 1;
					end
				stop :
					begin
						tx_next = 1'b1;
						if (s_tick)
							if (s_reg == (SB_TICK-1))
								begin
									state_next   = idle;
									tx_done_tick = 1'b1;
								end
						else
							s_next = s_reg + 1;
					end
			endcase
		end
	assign tx = tx_reg;
endmodule

