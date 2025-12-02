`timescale 1ns / 1ps

module controller (
    input  wire clk,
    input  wire rst_n,
    
    // Special case detection from stage 1 or stage 2
    input  wire ZERO_A_DE,
    input  wire NAR_A_DE,
    input  wire ZERO_B_DE,
    input  wire NAR_B_DE,
    input  wire NAR_EXP_ADDER,
    input  wire ZERO_EXP_ADDER,
    
    // Stage 5 interface
    output reg  encoder_start,
    input  wire encode_done,
    
    // reset stage 3 and 4
    output reg  adjust_rst_n,
    output reg  round_rst_n
);

    // State definitions
    localparam NORMAL_OPERATION = 2'd0, 
                SPECIAL_DETECTED = 2'd1, 
                SPECIAL_PROCESSING = 2'd2,
                SPECIAL_DONE = 2'd3;
    
    reg [1:0] state, next_state;
    
    // Special case detection
    wire special_case_detected;
    
    assign special_case_detected = ZERO_A_DE | NAR_A_DE | 
                                   ZERO_B_DE | NAR_B_DE | 
                                   NAR_EXP_ADDER | ZERO_EXP_ADDER;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= NORMAL_OPERATION;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            NORMAL_OPERATION: next_state = special_case_detected ? SPECIAL_DETECTED : NORMAL_OPERATION;
            
            SPECIAL_DETECTED: next_state = SPECIAL_PROCESSING;
            
            SPECIAL_PROCESSING: next_state = encode_done ? SPECIAL_DONE : SPECIAL_PROCESSING;
            
            SPECIAL_DONE: next_state = NORMAL_OPERATION;
            
            default: next_state = NORMAL_OPERATION;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            encoder_start      <= 1'b0;
            adjust_rst_n       <= 1'b1;
            round_rst_n        <= 1'b1;
        end else begin 
            case (state)
                NORMAL_OPERATION: begin
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                    encoder_start <= 1'b0;
                end
                
                SPECIAL_DETECTED: begin
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                    encoder_start <= 1'b1;
                end
                
                SPECIAL_PROCESSING: begin
                    adjust_rst_n <= 1'b0;
                    round_rst_n <= 1'b0;
                    encoder_start <= 1'b0;
                end
                
                SPECIAL_DONE: begin
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                    encoder_start <= 1'b0;
                end
                
                default: begin
                    encoder_start <= 1'b0;
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                end
            endcase
        end
    end

endmodule
