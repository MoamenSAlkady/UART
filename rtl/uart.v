`default_nettype none
module uart #(
	parameter D_BIT    = 8  ,											// Number of Data Bits
	parameter SB_TICK  = 16 ,											// Number of Sampling Ticks for a single bit
	parameter DVSR     = 163,											// Mod-m generator "M" divisor that ensures one-clock-cycle tick every 163 clock cycles based on 50MHz/(16*BaudRate) which ensures correct sampling tick increments.
	parameter DVSR_BIT = 8  ,											// Number of bits to represent divisor.
	parameter FIFO_W   = 2												// Number of Address Bits for FIFO
) (
	input  wire             clk, rst,
	input  wire             rx      ,
	input  wire             rd_uart, wr_uart,
	input  wire [D_BIT-1:0] w_data  ,
	output wire             tx      ,
	output wire             rx_empty, tx_full,
	output wire [D_BIT-1:0] r_data
);

	wire		[D_BIT-1:0] rx_data_to_fifo  ;
	wire		[D_BIT-1:0] tx_data_from_fifo;
	wire             		rx_done          ;
	wire             		tx_done          ;
	wire             		tx_fifo_empty    ;
	wire             		tick             ;

	mod_m_counter #(
		.N(DVSR_BIT),
		.M(DVSR    )
	) baud_generator (
		.clk     (clk ),
		.rst     (rst ),
		.max_tick(tick),
		.q       (    )
	);

	uart_rx #(
		.D_BIT  (D_BIT  ),
		.SB_TICK(SB_TICK)
	) uart_receiver (
		.clk         (clk            ),
		.rst         (rst            ),
		.rx          (rx             ),
		.s_tick      (tick           ),
		.rx_done_tick(rx_done        ),
		.dout        (rx_data_to_fifo)
	);

	uart_tx #(
		.WIDTH  (D_BIT  ),
		.SB_TICK(SB_TICK)
	) uart_transmitter (
		.clk         (clk              ),
		.rst         (rst              ),
		.tx          (tx               ),
		.s_tick      (tick             ),
		.tx_done_tick(tx_done          ),
		.tx_start    (!tx_fifo_empty   ),
		.din         (tx_data_from_fifo)
	);

	fifo #(
		.B(D_BIT ),
		.W(FIFO_W)
	) fifo_receiver (
		.clk   (clk            ),
		.rst   (rst            ),
		.rd    (rd_uart        ),
		.wr    (rx_done        ),
		.w_data(rx_data_to_fifo),
		.r_data(r_data         ),
		.empty (rx_empty       ),
		.full  (               )
	);

	fifo #(
		.B(D_BIT ),
		.W(FIFO_W)
	) fifo_transmitter (
		.clk   (clk              ),
		.rst   (rst              ),
		.rd    (tx_done          ),
		.wr    (wr_uart          ),
		.w_data(w_data           ),
		.r_data(tx_data_from_fifo),
		.empty (tx_fifo_empty    ),
		.full  (tx_full          )
	);

endmodule
