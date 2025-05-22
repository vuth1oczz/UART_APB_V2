module uart_tx 
#(
    parameter baute_rate = 15  
)
(
    input clk,
    input reset_n,
    input [7:0 ] tx_data,
    input [1:0] data_bit_num,
    input stop_bit_num,
    
    input parity_en,
    input parity_type,
    input start_tx,

    output logic tx_done,
    output tx
  
);


logic [3:0] data_bit_target;
logic parity_bit;

localparam even =1'b1;
localparam odd = 1'b0;
logic[4:0] divisor = baute_rate;

logic [3:0] count, count_next;
logic bit_done;
logic count_en;

logic tx_o;
logic TX_DONE;

logic [3:0] count_bit, count_bit_next;


logic [7:0] reg_data_bit, reg_data_bit_next;
enum logic [2:0] {IDLE, START_BIT, DATA_BIT, PARITY_BIT, 
                    STOP_BIT_FIRST, STOP_BIT_SECOND  } curr_state, next_state;
always_comb begin : PROCESS_DATABIT_NUM_AND_PARITY_BIT
    data_bit_target = 3'h0;
    parity_bit = 1'b0;
    case(data_bit_num)
        2'b00:begin
            if(parity_en) begin
                if(parity_type == even) parity_bit = ^tx_data[4:0];
                else parity_bit = ~^tx_data[4:0];  
            end
            data_bit_target = 4'd5;
        end
        2'b01: begin
             if(parity_en) begin
                if(parity_type == even) parity_bit = ^tx_data[5:0];
                else parity_bit = ~^tx_data[5:0];
            end
             data_bit_target = 4'd6;
        end
        2'b10:begin
             if(parity_en) begin
                if(parity_type == even) parity_bit = ^tx_data[6:0];
                else parity_bit = ~^tx_data[6:0];
            end
             data_bit_target = 4'd7;
        end
        2'b11:begin
            if(parity_en) begin
                if(parity_type == even) parity_bit = ^tx_data[7:0];
                else parity_bit = ~^tx_data[7:0];
            end
            data_bit_target = 4'd8;
        end
        default: begin
            data_bit_target = 3'h0;
            parity_bit = 1'b0;
        end
    endcase  
end
always_comb begin
    if(count_en) count_next = count +1;
    else count_next = count;
end

always_ff @( posedge clk, negedge reset_n ) begin : GENARTE_BAUTE
    if(~reset_n) begin
        count <= 0;
        bit_done <= 0;
    end else 
    if(count_en) begin
        if(count == divisor ) begin
            bit_done <= 1'b1;
            count <=0;
        end else begin
            count <= count_next;
            bit_done = 1'b0;
        end 
    end else begin end
end


always_comb begin : PROCESS_NEXT_STATE
    reg_data_bit_next = reg_data_bit;
    count_bit_next = count_bit;
    case(curr_state)
        IDLE: begin
            tx_o =1'b1;
            if(~(start_tx ^ tx_done) ) begin
                    TX_DONE = 1'b0;
                    next_state = START_BIT;
            end else begin
                
                next_state = IDLE;
            end
        end
        START_BIT: begin
            tx_o = 1'b0;
            count_en = 1'b1;
            if(bit_done) begin
                next_state = DATA_BIT;
                reg_data_bit_next = tx_data;
            end else begin
                next_state = START_BIT;
                reg_data_bit_next = 8'b0;
            end
        end
        DATA_BIT: begin
            tx_o = reg_data_bit[0];
            count_en = 1'b1;
            reg_data_bit_next = reg_data_bit;
    
            if(bit_done) begin
                if(count_bit == data_bit_target-1) begin
                    if(parity_en) next_state = PARITY_BIT;
                    else  next_state = STOP_BIT_FIRST;
                end else begin
                     count_bit_next = count_bit +1;
                     next_state = DATA_BIT;
                end
                reg_data_bit_next = reg_data_bit >>1;
            end else begin
                 next_state = DATA_BIT;
                 count_en = 1'b1;
                 reg_data_bit_next = reg_data_bit;
            end
        end
        PARITY_BIT: begin
            tx_o = parity_bit;
            count_en = 'b1;
     
            if(bit_done) begin
                    next_state = STOP_BIT_FIRST;  
            end else begin
                 next_state = PARITY_BIT;
            end
        end
        STOP_BIT_FIRST: begin
            tx_o = 1'b0;
            count_en = 1'b1;
            if(bit_done) begin
                if(stop_bit_num) begin
                    next_state = STOP_BIT_SECOND;
                end else begin
                     next_state = IDLE;
                     TX_DONE = 1'b1;
                    
                    
                end
            end else begin
                next_state = STOP_BIT_FIRST;
            end
        end
        STOP_BIT_SECOND: begin
            tx_o = 1'b0; 
            count_en = 1'b1;
            if(bit_done) begin
                next_state = IDLE;
                TX_DONE = 1'b1;
              
            end else begin
                next_state = STOP_BIT_SECOND;
            end
        end
        default begin
            next_state = IDLE;
            TX_DONE = 1'b1;
            tx_o = 1'b1;
            count_en = 1'b0;
        end
    endcase    
end

always_ff @(posedge clk, negedge reset_n ) begin : PROCESS_CURR_STATE
    if(~reset_n) begin
        curr_state <= IDLE;
        count_bit <= 0;

    end else begin
        curr_state <= next_state;
        count_bit <= count_bit_next;
    end
end

always_ff @( posedge clk, negedge reset_n ) begin : PROCESS_DATA_OUT
    if(~reset_n) begin
        reg_data_bit <= tx_data;

    end  else begin
        reg_data_bit <= reg_data_bit_next;
    end   
end

assign tx = tx_o;
// assign tx_done = TX_DONE;
always_ff @(posedge clk, negedge reset_n) begin
    if(~reset_n) tx_done <= 0;
    else tx_done <= TX_DONE;
end
endmodule