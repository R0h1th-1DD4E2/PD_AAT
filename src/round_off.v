`timescale 1ns / 1ps

module round_off (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [63:0] shifted_mantissa,
    input  wire [5:0]  k_out,
    input  wire        sign_out,
    input  wire [2:0]  exp_out,
    input  wire        recieved,
    output reg  [31:0] mantissa_out,
    output reg  [5:0]  k_final,
    output reg         sign_final,
    output reg  [2:0]  exp_final,
    output reg         done,
    output reg         init
);

    // FSM states
    parameter IDLE     = 2'b00, 
                INIT = 2'b01, 
                COMPUTE  = 2'b10, 
                COMPLETE = 2'b11;

    reg [1:0] current_state, next_state;

    // Local regs
    reg [5:0] nbt;
    reg [31:0] temp;
    reg [31:0] ext;
   // reg [29:0] dummy;
    wire k_sign;
    wire [5:0] k_abs;

    // Signed/absolute k_out
    assign k_sign = k_out[5];
    assign k_abs  = k_sign ? -k_out : k_out;

    // FSM sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM combinational next-state logic
    always @(*) begin
        case (current_state)
            IDLE:     next_state = (start) ? INIT : IDLE;
            INIT:     next_state = COMPUTE;
            COMPUTE:  next_state = COMPLETE;
            COMPLETE: next_state = (recieved) ? IDLE : COMPLETE;
            default:  next_state = IDLE;
        endcase
    end

    // FSM output and internal logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mantissa_out <= 32'b0;
            temp         <= 32'b0;
            nbt          <= 6'd0;
            done         <= 1'b0;
            ext          <=0;
            k_final      <=0;
            sign_final   <=0;
            exp_final    <=0;
            init        <= 1'b0;
        
        end else begin
            case (current_state)
                IDLE: begin
                    done         <= 1'b0;
                    mantissa_out <= mantissa_out;
				    ext          <=0;
					k_final      <=0;
                    sign_final   <=0;
                    exp_final    <=0;
                    init         <= 1'b0;
                end

                INIT: begin
                    mantissa_out <= 32'b0;           // initialize output
                    nbt          <= (!k_sign) ? (6'd26 - k_out) : (6'd27 - k_abs);
                    temp         <= 32'hFFFF_FFFF;   // all ones
					ext          <=0;
					k_final      <=0;
                    sign_final   <=0;
                    exp_final    <=0;
                    init         <= 1'b1;
                end

                COMPUTE: begin
                    // Shift temp to keep only nbt MSBs as 1
                    temp         <= temp << (32 - nbt);

                    // Extract 32 bits from shifted_mantissa[61:30]
                    ext          <= shifted_mantissa[61:30];
						  

                 //   dummy<=shifted_mantissa[29:0];
                    init         <= 1'b0;
                end

                COMPLETE: begin
                    done <= 1'b1;   // signal computation done
						      mantissa_out <= ext & temp ;// mantissa_out = ext AND mask
                    sign_final   <= sign_out;
                    k_final      <= k_out;
                    exp_final    <= exp_out;
                    init         <= 1'b0;
                end

                default: begin
                    mantissa_out <= mantissa_out;
                    done         <= 1'b0;
                    init         <= 1'b0;
                end
            endcase
        end
    end

endmodule
























