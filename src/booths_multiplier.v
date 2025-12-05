`timescale 1ns / 1ps

module booths_multiplier #(parameter N = 32)(
    input wire clk, rst_n, load,
    input wire [N-1:0] A, B,
    output reg done, init,
    output reg [2*N-1:0] C
);
    
    // States 
    parameter IDLE      = 3'b000, 
              INIT      = 3'b001, 
              CHECK_LSB = 3'b010, 
              ACC_ADD   = 3'b011, 
              ACC_SUB   = 3'b100, 
              AR_SHIFT  = 3'b101, 
              DONE      = 3'b110;
    
    // State registers
    reg [2:0] cur_state, next_state;
    
    // Internal registers
    reg signed [N-1:0] M, Q;
    reg signed [N:0] ACC;
    reg [$clog2(N)-1:0] counter;  // Made wider to avoid overflow
    reg Q_1;
    
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
            CHECK_LSB: begin
                case ({Q[0], Q_1})
                    2'b00: next_state = AR_SHIFT;
                    2'b01: next_state = ACC_ADD;
                    2'b10: next_state = ACC_SUB;
                    2'b11: next_state = AR_SHIFT;
                    default: next_state = AR_SHIFT;
                endcase
            end
            ACC_ADD:    next_state = AR_SHIFT;
            ACC_SUB:    next_state = AR_SHIFT;
            AR_SHIFT:   next_state = (counter == 0) ? DONE : CHECK_LSB;
            DONE:       next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end
    
    // Datapath logic (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            M <= 0;
            Q <= 0;
            ACC <= 0;
            Q_1 <= 0;
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
                    M <= A;
                    Q <= B;
                    ACC <= 0;
                    Q_1 <= 0;
                    counter <= 5'(N - 1);
                    done <= 0;
                    init <= 1;
                end
                ACC_ADD: begin
                    ACC <= ACC + M;
                    init <= 0;
                end
                ACC_SUB: begin
                    ACC <= ACC - M;
                    init <= 0;
                end
                AR_SHIFT: begin
                    {ACC, Q, Q_1} <= $signed({ACC, Q, Q_1}) >>> 1;
                    counter <= counter - 1;
                    init <= 0;
                end
                DONE: begin
                    C <= {ACC[N-1:0], Q};
                    done <= 1;
                    init <= 0;
                end
                default: ;
            endcase
        end 
    end
    
endmodule
