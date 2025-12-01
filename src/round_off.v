module round_off (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [63:0] shifted_mantissa,
    input  wire [5:0]  k_out,
    output reg  [31:0] mantissa_out,
    output reg         done
);

    // FSM states
    typedef enum reg [1:0] { 
        IDLE     = 2'b00, 
        INIT     = 2'b01, 
        COMPUTE  = 2'b10,
        COMPLETE = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Local regs
    reg [5:0] nbt;
    reg [31:0] temp;
    reg [31:0] ext;

    wire k_sign;
    wire [5:0] k_abs;

    // Signed/absolute k_out
    assign k_sign = k_out[5];
    assign k_abs  = k_sign ? (~k_out + 6'd1) : k_out;

    // FSM sequential logic
    always @(posedge clk) begin
        if (rst)
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
            COMPLETE: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    // FSM output and internal logic
    always @(posedge clk) begin
        if (rst) begin
            mantissa_out <= 32'b0;
            temp         <= 32'b0;
            nbt          <= 6'd0;
            done         <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    done         <= 1'b0;
                    mantissa_out <= mantissa_out;
                end

                INIT: begin
                    mantissa_out <= 32'b0;           // initialize output
                    nbt          <= (!k_sign) ? (6'd26 - k_out) : (6'd27 - k_abs);
                    temp         <= 32'hFFFF_FFFF;   // all ones
                end

                COMPUTE: begin
                    // Shift temp to keep only nbt MSBs as 1
                    temp         <= temp << (32 - nbt);

                    // Extract 32 bits from shifted_mantissa[61:30]
                    ext          <= shifted_mantissa[61:30];

                    // mantissa_out = ext AND mask
                    mantissa_out <= ext & temp ;
                end

                COMPLETE: begin
                    done <= 1'b1;                     // signal computation done
                end
            endcase
        end
    end

endmodule
