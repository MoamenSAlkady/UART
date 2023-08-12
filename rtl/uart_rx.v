`default_nettype none
module uart_rx #(
	parameter D_BIT   = 8 ,
	parameter SB_TICK = 16
) (
	input  wire             clk, rst, rx, s_tick,
	output reg              rx_done_tick,
	output wire [D_BIT-1:0] dout
);

	localparam [                1:0] IDLE       = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
	reg        [                1:0] state_reg                                                    ;
	reg        [                1:0] state_next                                                   ;
	reg        [$clog2(SB_TICK)-1:0] s_reg                                                        ;
	reg        [$clog2(SB_TICK)-1:0] s_next                                                       ;
	reg        [  $clog2(D_BIT)-1:0] n_reg                                                        ;
	reg        [  $clog2(D_BIT)-1:0] n_next                                                       ;
	reg        [          D_BIT-1:0] b_reg                                                        ;
	reg        [          D_BIT-1:0] b_next                                                       ;

	always @(posedge clk or posedge rst)
		begin
			if(rst)
				begin
					state_reg <= 0;
					s_reg     <= 0;
					n_reg     <= 0;
					b_reg     <= 0;
				end
			else
				begin
					state_reg <= state_next;
					s_reg     <= s_next;
					n_reg     <= n_next;
					b_reg     <= b_next;
				end
		end
	always @*
		begin
			state_next   = state_reg;
			s_next       = s_reg;
			n_next       = n_reg;
			b_next       = b_reg;
			rx_done_tick = 0;
			case(state_reg)
				IDLE :
					if(!rx)
						begin
							state_next = START;
							s_next     = 0;
						end
						else
							begin
								state_next = IDLE;
							end
				START :
					if(s_tick)
						begin
							if(s_reg == 7)
								begin
									s_next     = 0;
									n_reg      = 0;
									state_next = DATA;
								end
							else
								begin
									s_next = s_reg + 1;
								end
						end
						else
							begin
								state_next = START;
							end
				DATA :
					if(s_tick)
						begin
							if(s_reg == 15)
								begin
									s_next = 0;
									b_next = {rx, b_reg[D_BIT-1:1]};
									if(n_reg == D_BIT-1)
										begin
											state_next = STOP;
										end
									else
										begin
											n_next = n_reg + 1;
										end
								end
							else
								begin
									s_next = s_reg + 1;
								end
						end
						else
							begin
								state_next = DATA;
							end
				STOP :
					if(s_tick)
						begin
							if(s_reg == SB_TICK-1)
								begin
									rx_done_tick = 1;
									state_next   = IDLE;
								end
							else
								begin
									s_next = s_reg + 1;
								end
						end
						else
							begin
								state_next = STOP;
							end
			endcase
		end
	assign dout = b_reg;
endmodule
