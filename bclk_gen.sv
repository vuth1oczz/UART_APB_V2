module bclk_gen
#(
    parameter baud_rate = 16
)
(
    input clk,
    input reset_n,
    output Bclk
);
localparam divisor = 50000000/(baud_rate*16);
logic [10:0] count, count_next;
logic bclk, bclk_next;
always_comb begin
    if(count == divisor-1) begin
        count_next =0;
        bclk_next = 1;
    end else begin
        count_next = count +1;
        bclk_next = 0;
    end
end
always_ff @(posedge clk, negedge reset_n)begin
    if(~reset_n) begin
        bclk <= 0;
        count <= 0;
    end else begin
        count <= count_next;
        bclk <= bclk_next;
    end
end
assign Bclk = bclk;
endmodule 