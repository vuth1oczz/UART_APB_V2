module uart_rx
#(
    parameter baud_rate = 15
)
 (
    
    input clk,
    input reset_n,
//apb side
    input [1:0] data_bit_num,
    input  stop_bit_num,
    input  parity_en,
    input  parity_type,

    output logic parity_error,
    output logic [7:0] rx_data,
    output logic rx_done,
//peripheral side
    input  rx,
    
    output logic rts_n
);
    enum logic [2:0]  {IDLE, ST_START, ST_DATA, ST_PRT, STOP_BIT } state, next_state;
    logic [3:0] count_data;
    logic [1:0] count_stop;
    logic [3:0]count, count_next;
    logic [4:0] baud, baud_next;
    logic [7:0] rx_reg, rx_reg_next;
 



 
    logic [4:0] divisor = baud_rate;
    logic parity_bit;

    logic baud_en;
    logic bit_done;
    logic [1:0] reg_stop_bit_next, reg_stop_bit, count_stop_bit_next, count_stop_bit;
    always_comb begin
        case (data_bit_num)
            2'b00: count_data = 4'd5;
            2'b01: count_data = 4'd6;
            2'b10: count_data = 4'd7;
            2'b11: count_data = 4'd8;
            default : count_data = 4'd5;
        endcase
        
        case (stop_bit_num)
            1'b0: count_stop = 2'd1;
            1'b1: count_stop = 2'd2;
            default: count_stop = 2'd1;
        endcase
    end    

    always_comb begin
        count_next = count;
        rx_reg_next = rx_reg;
        count_stop_bit_next = count_stop_bit;
        reg_stop_bit_next = reg_stop_bit;
        next_state = state;
        case (state) 
            IDLE: begin
                //baud_en = 1'b0;
                if(rx == 0) begin
                     next_state = ST_START;
                     rx_done = 1'b0;
                     rts_n = 1'b0;
                end
                else begin
                    next_state = IDLE;
                    rx_done = 1'b1;
                    rts_n = 1'b1;

                    
                end
            end
            ST_START: begin
                baud_en = 1'b1;
                rx_reg_next = 'h0;
                if(bit_done) begin
                        baud_en = 1'b0;
                        next_state = ST_DATA;   
                end  else next_state = ST_START;
         
            end
            ST_DATA:  begin
            count_next = count;
            baud_en = 1'b1;
            //rx_reg_next = rx_reg;
            
            if(baud_next == 8) begin
                rx_reg_next = rx_reg;
                rx_reg_next[0] = rx;
            end
            if(bit_done) begin
                rx_reg_next = rx_reg << 1;
                baud_en =1'b0;
                if (count == count_data-1) begin 
                    next_state = ST_PRT;
                    rx_data = rx_reg;
                    count_next = 4'h0;
                end
                else begin 
                    next_state = ST_DATA;
                    count_next = count + 1;
                    rx_done =1'b0;
                end

            end else begin
                next_state = ST_DATA;
                rx_done = 1'b0;
            end
            end
                
            ST_PRT: begin
                parity_bit = rx;
                baud_en = 1'b1;
                if (bit_done) begin
                    next_state = STOP_BIT;
                    baud_en = 1'b0;
                end
                else begin 
                    next_state = ST_PRT;
                 
                end
            end
            STOP_BIT:  begin
            baud_en = 1'b1;
            reg_stop_bit_next = reg_stop_bit;
            reg_stop_bit_next[0] = 1'b1;
            if(bit_done) begin
                reg_stop_bit_next = reg_stop_bit << 1;
                baud_en = 1'b0;
                if (count_stop_bit == count_stop) begin 
                    next_state = IDLE;
                    count_stop_bit_next = 'h0;
                    rx_done = 1'b1;
                    rts_n = 1'b1;
                    
                end
                else begin 
                    next_state = STOP_BIT;
                    count_stop_bit_next = count_stop_bit +1; 
                end
            end else begin
                next_state = STOP_BIT;
            end 
            end
            default: begin
                parity_bit = 1'b0;
                
                rx_done =1'b0;
               
                rx_data = 'h0;
               
                rts_n = 1'b0;
                
            end
        endcase
    end 

    always_ff @(posedge clk, negedge reset_n) begin
        if (~reset_n) begin 
             state <= IDLE;
             rx_reg <= 'h0;
             reg_stop_bit <= 'h0;
        end
        else begin
             state <= next_state;
             rx_reg <= rx_reg_next;
             reg_stop_bit <= reg_stop_bit_next;
        end
    end

    always_ff @(posedge clk, negedge reset_n) begin
        if(~reset_n) begin
             count <=0;
             count_stop_bit <= 0;
        end
        else begin
             count <= count_next;
             count_stop_bit <= count_stop_bit_next;
        end
    end


always_comb begin
    if(baud_en) baud_next = baud +1;
    else baud_next = baud;
end


always_ff @(posedge clk, negedge reset_n) begin
          if(~reset_n) begin
                baud <= 0;
                bit_done <= 0;
            end else if(baud_en) begin
                 if(baud == divisor-1 ) begin
                        bit_done <= 1'b1;
                        baud <=0;
                        
                       
                end else begin
                        baud <= baud_next;
                        bit_done = 1'b0;
        end 
    end else begin 
        bit_done = 1'b0;
     end
    end


always_comb begin
        case ({parity_en, parity_type})
            2'b10: parity_error = ~((^rx_reg) ^ parity_bit) ;
            2'b11: parity_error =  (^rx_reg) ^ parity_bit;
            default : parity_error = 1'b0;
        endcase

        //rts_n_out = rts_n_in;
    end

endmodule