module adjustment (
    input                      clk,
    input                      reset,
    input                      start,
    input      [9:0]           scale_in,
    input      [63:0]          mant_prod,

    output reg [9:0]           scale_out,
    output reg [63:0]          mant_adj,
    output reg [63:0]          shift_amt,
    output     reg             done,
    output reg      [2:0]          adj_exp,
    output reg    [5:0]          adj_regime,
    output reg                    exp_sign
);

    reg [63:0] mant_work;
    reg [63:0] shift_count;



parameter IDLE     = 2'b00,
          SHIFTING = 2'b01,
          DONE_ST  = 2'b10;

reg [1:0] current_state, next_state;

always @(posedge clk) begin
    if (reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

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

        default: next_state = IDLE;

    endcase
end

always @(posedge clk) begin
    if (reset) begin
        scale_out   <= 0;
        mant_adj    <= 0;
        shift_amt   <= 0;
        mant_work   <= 0;
        shift_count <= 0;
        done        <= 0;
    end else begin
        case (current_state)

        IDLE: begin
            done <= 0;
            if (start) begin
                scale_out   <= scale_in;
                mant_adj    <= mant_prod;
                mant_work   <= mant_prod;
                shift_amt   <= 0;
                shift_count <= 0;
					 adj_exp    <= 0 ;
					 adj_regime  <= 0 ;
					 exp_sign   <= 0 ;
            end
        end

        SHIFTING: begin
            case (mant_work[63:62])

                2'b11,2'b10: begin
                    mant_work   <= mant_work >> 1;
                    scale_out   <= scale_out + 10'd1;
                    shift_count   <= shift_count + 64'd1;
                end

//                2'b10: begin
//                    mant_work   <= mant_work >> 1;
//                    scale_out   <= scale_out + 10'd1;
//                    shift_count   <= 1;
//                end

                2'b01: begin
                 //   shift_count <= 64'd0;
                end

                2'b00: begin
                    mant_work   <= mant_work << 1;
                    shift_count <= shift_count + 64'd1;
                    scale_out   <= scale_out - 10'd1;
                end

            endcase
        end

        DONE_ST: begin
            mant_adj  <= mant_work;
            shift_amt <= shift_count;
             done      <= 1;
				 adj_exp    <= scale_out[2:0] ;
				adj_regime  <= scale_out[8:3] ;
				 exp_sign   <= scale_out[9];
        end

        endcase
    end
end

endmodule
