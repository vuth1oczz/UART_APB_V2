module apb_slave
(   
    input pclk,
    input presetn,
    input psel,
    input penable,
    input pwrite,
    input [3:0] pstrb,
    input [11:0] paddr,
    input [31:0] pwdata,

    input wadderr,
    input radderr,
    output logic pready,
    output pslverr,
    output [31:0] prdata,

    // output to register block
    output [11:0] waddr,
    output [31:0] wdata,
    output pwrite_o,
    output [11:0] raddr,
    //input from register block
    input [31:0] rdata

    // input tx_done, rx_done;

 );

enum logic [1:0] {IDLE, SETUP, WRITE, READ} curr_state, next_state;

logic [31:0] reg_wdata;
logic [11:0] reg_waddr;
logic [11:0] reg_raddr;
logic [31:0] reg_rdata;

assign pwrite_o = pwrite;


always_comb begin 
   case(curr_state)
        IDLE: begin
            if(psel) begin
                next_state = SETUP;
            end else begin 
                next_state = IDLE;
            end
        end
        SETUP: begin
            if(penable) begin
                 if(pwrite) next_state = WRITE;
                 else next_state = READ;
            end
            else next_state = SETUP;
        end
        WRITE: begin
            casex ({psel,penable,pwrite})
                3'b0xx: next_state = IDLE;
                3'b10x: next_state = SETUP;
                3'b110: next_state = READ;
                3'b111: next_state = WRITE;  
            endcase 
        end
        READ: begin
            casex ({psel,penable,pwrite})
                3'b0xx: next_state = IDLE;
                3'b10x: next_state = SETUP;
                3'b110: next_state = READ;
                3'b111: next_state = WRITE;  
            endcase 
        end
   endcase
end

always_comb begin 
    reg_waddr  =12'hz;
    reg_wdata = 32'hz;
    reg_raddr = 12'hz;
    reg_rdata = 32'hz;
    pready = 1'b1;
   case(curr_state)
        IDLE: begin
            pready = 1'b1;
        end
        SETUP: begin
            pready = 1'b0;
        end
        WRITE: begin
            pready = 1'b1;
            if(pstrb[0]) begin
            reg_waddr = paddr;
            reg_wdata = pwdata;
            
            end else begin
                reg_waddr = paddr;
                reg_wdata = 'hz;
            end
        end
        READ: begin
            pready = 1'b1;
            reg_raddr = paddr;
            reg_rdata = rdata;
        end
   endcase
end


always_ff @( posedge pclk, negedge presetn ) begin 
    if(~presetn) begin
        curr_state <= IDLE;
    end else begin
        curr_state <= next_state;
    end
    
end


assign prdata = reg_rdata;
assign waddr = reg_waddr;
assign wdata = reg_wdata;
assign raddr = reg_raddr;
// assign pready = 1'b1;

assign pslverr = ~(wadderr & radderr );
endmodule