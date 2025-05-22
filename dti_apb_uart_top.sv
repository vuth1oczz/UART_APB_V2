module dti_apb_uart_top
#(parameter baud_rate= 15) 
(
    input clk,
    input reset_n,
    input pclk,
    input presetn,
    input psel,
    input penable,
    input pwrite,
    input [3:0] pstrb,
    input [11:0] paddr,
    input [31:0] pwdata,
    output [31:0] prdata,
    output pready,
    output pslverr,
   

    output tx, 
    output rts_n,

    input rx,
    input cts_n

);

logic [31:0] rdata;

logic [11:0] waddr;
logic [31:0] wdata;
logic pwrite_o;

logic [11:0] raddr;
logic radderr, wadderr;
logic [7:0] tx_data;
logic [1:0] data_bit_num;
logic stop_bit_num;
logic parity_en;
logic parity_type;
logic start_tx;


logic tx_interupt;

logic tx_done;
logic rx_done;
logic [7:0] rx_data;
logic parity_error;
apb_slave apb_slave (
    .pclk(clk),
    .presetn(reset_n),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .pstrb(pstrb),
    .paddr(paddr),
    .pwdata(pwdata),
    .wadderr(wadderr),
    .radderr(radderr),
    .pready(pready),
    .pslverr(pslverr),
    .prdata(prdata),
    .waddr(waddr),
    .wdata(wdata),
    .pwrite_o(pwrite_o),
    .raddr(raddr),
    .rdata(rdata)
);

register register_block (
    .clk(clk),
    .reset_n(reset_n),
    .waddr(waddr),
    .raddr(raddr),
    .wdata(wdata),
    .pwrite(pwrite_o),
    .rdata(rdata),
    .wadderr(wadderr),
    .radderr(radderr),
    .tx_done(tx_done),
    .rx_done(rx_done),
    .rx_data(rx_data),
    .parity_error(parity_error),
    .tx_data(tx_data),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .start_tx(start_tx)
);

uart_tx #(.baute_rate(15)) tx_dut (
    .clk(clk),
    .reset_n(reset_n),
    .tx_data(tx_data),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .start_tx(start_tx),
    .tx_done(tx_done),
    .tx(tx)
);

uart_rx #(.baud_rate(15)) rx_dut (
    .clk(clk),
    .reset_n(reset_n),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .parity_error(parity_error),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .rx(rx),
    .rts_n(rts_n)
);
endmodule