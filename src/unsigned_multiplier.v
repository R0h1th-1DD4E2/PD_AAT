`timescale 1ns / 1ps

module unsigned_multiplier #(parameter N = 32)(
    input wire clk, rst_n, load,recieved,
    input wire [N-1:0] A, B,
    output reg done, init,
    output reg [2*N-1:0] C
);
    
    // States 
    parameter IDLE      = 3'b000, 
              INIT      = 3'b001, 
              CHECK_LSB = 3'b010, 
              ACC_ADD   = 3'b011, 
              R_SHIFT   = 3'b100, 
              DONE      = 3'b101;
    
    // State registers
    reg [2:0] cur_state, next_state;
    
    // Internal registers
    reg [N-1:0] Q;
    reg [2*N-1:0] ACC, M;
    reg [$clog2(N)-1:0] counter;
    
    // State update (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cur_state <= IDLE;
        else
            cur_state <= next_state; 
    end
    
    // Next state logic (Combinational)
    always @(*) begin
        case (cur_state)
            IDLE:       next_state = (load) ? INIT : IDLE;
            INIT:       next_state = CHECK_LSB;
            CHECK_LSB:  next_state = (Q[0]) ? ACC_ADD : R_SHIFT;
            ACC_ADD:    next_state = R_SHIFT;
            R_SHIFT:    next_state = (counter == 0) ? DONE : CHECK_LSB;
            DONE:       next_state = (recieved) ? IDLE : DONE;
            default:    next_state = IDLE;
        endcase
    end
    
    // Datapath logic (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            M <= 0;
            Q <= 0;
            ACC <= 0;
            counter <= 0;
            C <= 0;
            done <= 0;
            init <= 0;
        end
        else begin
            case (cur_state)
                IDLE: begin
                    done <= 0;
                    init <= 0;
                end
                INIT: begin
                    M <= {{N{1'b0}}, A};
                    Q <= B;
                    ACC <= 0;
                    counter <= N-5'b1;
                    done <= 0;
                    init <= 1;
                end
                ACC_ADD: begin
                    ACC <= ACC + M;
                    init <= 0;
                end
                R_SHIFT: begin
                    Q <= Q >> 1;
                    counter <= counter - 1;
                    M <= M << 1;
                    init <= 0;
                end
                DONE: begin
                    C <= ACC;
                    done <= 1;
                    init <= 0;
                end
                default: begin
                    C <= 0;
                    done <= 0;
                    init <= 0;
                end
            endcase
        end 
    end
    
endmodule






























