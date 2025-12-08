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
	 
	 input wire encode_done,

    // Encoder data
    output reg [31:0] result,
    output reg NAR, ZERO,
    
    // reset stage 3 and 4 and 5th
    output reg  adjust_rst_n,
    output reg  round_rst_n,
    output reg  encoder_rst_n,
	 
    output reg bm_rst_n,//
	 output reg decoder_rst_n,//

    output reg  done

);

    // State definitions
    localparam NORMAL_OPERATION = 2'd0, 
                NAR_DETECTED = 2'd1, 
                ZERO_DETECTED = 2'd2,
                SPECIAL_DONE = 2'd3;
    
    reg [1:0] state, next_state;
    
    // Special case detection
    wire is_nar, is_zero;
    
    assign is_nar = NAR_A_DE | NAR_B_DE | NAR_EXP_ADDER;
    assign is_zero = ZERO_A_DE | ZERO_B_DE | ZERO_EXP_ADDER;

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
        case (state)
            NORMAL_OPERATION: begin
                case ({is_nar, is_zero})
                    2'b00: next_state = NORMAL_OPERATION;
                    2'b01: next_state = ZERO_DETECTED;
                    2'b10: next_state = NAR_DETECTED;
                    2'b11: next_state = NORMAL_OPERATION;
                    default: begin
                        next_state = NORMAL_OPERATION;
                    end
                endcase
            end
            
            ZERO_DETECTED: next_state = SPECIAL_DONE;

            NAR_DETECTED: next_state = SPECIAL_DONE;
            
            SPECIAL_DONE: next_state = NORMAL_OPERATION;
            
            default: next_state = NORMAL_OPERATION;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            encoder_rst_n      <= 1'b0;
            adjust_rst_n       <= 1'b0;
            round_rst_n        <= 1'b0;
				bm_rst_n           <= 1'b0;
				decoder_rst_n      <= 1'b0;
            done               <= 1'b0;
            ZERO           <= 1'b0;
            NAR           <= 1'b0;
            result             <= 32'd0;
        end else begin 
            case (state)
                NORMAL_OPERATION: begin
					 if(encode_done)begin// reset all modules on completion.
					    encoder_rst_n      <= 1'b0;
                   adjust_rst_n       <= 1'b0;
                   round_rst_n        <= 1'b0;
			        	 bm_rst_n           <= 1'b0;
				       decoder_rst_n      <= 1'b0;
						     ZERO           <= 1'b0;
                        NAR           <= 1'b0;
					    end
						 
						else begin
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                    encoder_rst_n <= 1'b1;
						  bm_rst_n           <= 1'b1;
				        decoder_rst_n      <= 1'b1;
                    done          <= 1'b0;
                    ZERO           <= 1'b0;
                    NAR           <= 1'b0;
                    result        <= 32'd0;
						  end
                end
                
                ZERO_DETECTED: begin
                    adjust_rst_n <= 1'b0;
                    round_rst_n <= 1'b0;
                    encoder_rst_n <= 1'b0;
					bm_rst_n           <= 1'b0;
				    decoder_rst_n      <= 1'b0;
                    done          <= 1'b0;
                    ZERO           <= 1'b1;
                    NAR           <= 1'b0;
                    result        <= 32'd0;
                end
                NAR_DETECTED: begin
                    adjust_rst_n <= 1'b0;
                    round_rst_n <= 1'b0;
                    encoder_rst_n <= 1'b0;
                    bm_rst_n           <= 1'b0;
                    decoder_rst_n      <= 1'b0;
                    done          <= 1'b0;
                    NAR           <= 1'b1;
                    ZERO           <= 1'b0;
                    result        <= 32'h80000000; // NAR representation
                end
                SPECIAL_DONE: begin
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                    encoder_rst_n <= 1'b1;
                    bm_rst_n           <= 1'b1;
                    decoder_rst_n      <= 1'b1;
                    done               <= 1'b1;
                    ZERO           <= ZERO;
                    NAR           <= NAR;
                    result        <= result;
                end
                
                default: begin
                    encoder_rst_n <= 1'b1;
                    adjust_rst_n <= 1'b1;
                    round_rst_n <= 1'b1;
                    bm_rst_n           <= 1'b1;
                    decoder_rst_n      <= 1'b1;
                    done               <= 1'b0;
                    ZERO           <= 1'b0;
                    NAR           <= 1'b0;
                    result        <= 32'd0;
                end
            endcase
        end
    end

endmodule
