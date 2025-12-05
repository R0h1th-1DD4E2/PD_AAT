`timescale 1ns / 1ps

module exp_adder #(
    parameter ES = 3,
            K_BITS = 6, // to represent +29 to -30
            MAX_BITS = ES + K_BITS
) (
    input wire clk, rst_n, start,
    input wire [ES-1:0] exp_A, exp_B,
    input wire signed [K_BITS-1:0] k_A, k_B,
    input wire sign_A, sign_B,

    output reg [MAX_BITS:0] exp_raw,
    output reg sign_out,
    output reg NaR,
    output reg zero_out,
    output reg done, init
    
);

// Exponent can be extracted using the formula : E = k*2^ES + e
    // local parameter of maximum exponent value and minimum value
    localparam signed EXP_MAX = (29 << ES) + ((1 << ES) - 1);
    localparam signed EXP_MIN = (-31 << ES);

    // States 
    parameter IDLE      = 2'b00, 
              INIT      = 2'b01,
              ADD_EXP   = 2'b10,
              DONE      = 2'b11;

    // State registers
    reg [1:0] cur_state, next_state;

    // other internal signals
    reg signed [MAX_BITS-1:0] exp_A_raw, exp_B_raw;
    reg sign;
    reg signed [MAX_BITS:0] exp_sum;


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
            IDLE:       next_state = (start) ? INIT : IDLE;
            INIT:       next_state = ADD_EXP;
            ADD_EXP:    next_state = DONE;
            DONE:       next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end

    // Datapath logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_raw <= 0;
            sign_out <= 0;
            NaR <= 0;
            zero_out <= 0;
            done <= 0;
            init <= 0;
        end 
        else begin
            case (cur_state)
                IDLE: begin
                    done <= 0;
                    NaR <= 0;
                    zero_out <= 0;
                    init <= 0;
                end
                INIT: begin
                    // Convert to raw exponent
                    exp_A_raw <= ({3'b0, k_A} << ES) + {6'b0, exp_A};
                    exp_B_raw <= ({3'b0, k_B} << ES) + {6'b0, exp_B};
                    sign <= sign_A ^ sign_B;
                    init <= 1;
                end
                ADD_EXP: begin
                    // add the output 
                    exp_sum <= exp_A_raw + exp_B_raw;
                    init <= 0;
                end
                DONE: begin
                    done <= 1;
                    sign_out <= sign;
                    exp_raw <= exp_sum;
                    // Check for NaR and zero conditions
                    if (exp_sum> EXP_MAX) begin
                        NaR <= 1;
                    end else if (exp_sum < EXP_MIN) begin
                        zero_out <= 1;
                    end
                    init <= 0;
                end
                default: ;
            endcase
        end
    end
endmodule
