`timescale 1ns / 1ps

module adjustment (
    input              clk,
    input              rst_n,
    input              start,
    input      [9:0]   E_raw,
    input      [63:0]  mant_prod,
    input              sign_in,

    output reg [63:0]  mant_adj,
    output reg         done,
    output reg [2:0]   adj_exp,
    output reg [5:0]   adj_k,
    output reg         sign_out
);

    // Internal registers
    reg [63:0] mant_work;
    reg [5:0]  shift_count;
    reg [9:0]  scale_out;

    // State encoding
    parameter IDLE     = 2'b00,
              SHIFTING = 2'b01,
              DONE_ST  = 2'b10;

    reg [1:0] current_state, next_state;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start)
                    next_state = SHIFTING;
                else
                    next_state = IDLE;
            end

            SHIFTING: begin
                if (mant_work[63:62] == 2'b01)
                    next_state = DONE_ST;
                else
                    next_state = SHIFTING;
            end

            DONE_ST: begin
                next_state = IDLE;
            end

            default: 
                next_state = IDLE;
        endcase
    end

    // Output and datapath logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scale_out   <= 0;
            mant_adj    <= 0;
            mant_work   <= 0;
            shift_count <= 0;
            done        <= 0;
        end 
        else begin
            case (current_state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        scale_out   <= E_raw;
                        mant_work   <= mant_prod;
                        shift_count <= 0;
                        adj_exp     <= 0;
                        adj_k       <= 0;
                    end
                end

                SHIFTING: begin
                    case (mant_work[63:62])
                        // Shift right for overflow (11 or 10)
                        2'b11, 2'b10: begin
                            mant_work   <= mant_work >> 1;
                            scale_out   <= scale_out + 10'd1;
                            shift_count <= shift_count + 6'd1;
                        end

                        // Normalized (01) - no action needed
                        2'b01: begin
                            // Hold current values
                        end

                        // Shift left for underflow (00)
                        2'b00: begin
                            mant_work   <= mant_work << 1;
                            scale_out   <= scale_out - 10'd1;
                            shift_count <= shift_count + 6'd1;
                        end

                        default: begin
                            // No action
                        end
                    endcase
                end

                DONE_ST: begin
                    mant_adj <= mant_work;
                    done     <= 1;
                    adj_exp  <= scale_out[2:0];
                    adj_k    <= scale_out[8:3];
                    sign_out <= sign_in;
                end

                default: begin
                    // No action
                end
            endcase
        end
    end

endmodule
