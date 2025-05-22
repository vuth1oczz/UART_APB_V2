 module register (
    input clk,
    input reset_n,
//apb slave
    input logic [11:0] waddr, 
    input [11:0] raddr,
 //   input logic [3:0] pstrb,
    input logic [31:0] wdata,
    input logic pwrite,

    output logic [31:0] rdata,
    output logic wadderr,
    output logic radderr,

// uart_core
    input logic tx_done,
    input logic rx_done,
    input logic [7:0] rx_data,
    input logic parity_error,


    output logic [7:0] tx_data,
    output logic [1:0] data_bit_num,
    output logic stop_bit_num,
    output logic parity_en,
    output logic parity_type,
    output logic start_tx
);
    logic [31:0] tx_data_reg;
    logic [31:0] rx_data_reg;
    logic [31:0] cfg_reg;
    logic [31:0] ctrl_reg;
    logic [31:0] stt_reg;; 
//apb side

always_ff @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            cfg_reg <= 0;
            ctrl_reg <= 0;
            stt_reg[31:3] <= 32'h00000001;
            rdata <= 0;
            radderr <= 0;
            wadderr <= 0;
        end else begin
            if(pwrite) begin
                case (waddr) 
                    12'h000: begin
                        tx_data_reg <= wdata;
                    end
                    12'h008: begin
                            cfg_reg <= wdata;
                    end
                    12'h00c: begin
                          ctrl_reg <= wdata;
                          
                    end
                    default: wadderr <= 1'b1;
            
                endcase 
            end else begin
                case (raddr)
                    12'h000: rdata <= tx_data_reg;

                    12'h004: rdata <= rx_data_reg;

                    12'h008: rdata <= cfg_reg;

                    12'h00c: rdata <= ctrl_reg;

                    12'h010: rdata <= stt_reg;

                    default: radderr<= 1'b1;
                endcase
            end
        end
    end


//uart side
always_ff @(posedge clk, negedge reset_n) begin
            rx_data_reg <= rx_data;
            stt_reg[0] <= tx_done;
            stt_reg[1] <= rx_done;
            stt_reg[2] <= parity_error;
end

always_comb begin
        tx_data         = tx_data_reg [7:0];
        data_bit_num    = cfg_reg [1:0];
        stop_bit_num    = cfg_reg [2];
        parity_en       = cfg_reg [3];
        parity_type     = cfg_reg [4];
        start_tx = ctrl_reg [0];
      
        


    end

endmodule