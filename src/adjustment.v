module adjustment #(
    parameter SCALE_W  = 6
)(
    input                      clk,
    input                      reset,
    input                      start,
    input      [9:0]   scale_in,
    input      [63:0]          mant_prod,

    output reg [9:0]   scale_out,
    output reg [63:0]          mant_adj,
    output reg [63:0]   shift_amt,
    output                  done ,
	 output  [2:0]adj_exp  ,
	 output   [5:0]adj_regime,
	 output   exp_sign
);

    reg [63:0] mant_work;
    reg [63:0] shift_count;

assign adj_exp = done ? scale_out[2:0] : adj_exp  ;
assign adj_regime = done ? scale_out[8 : 3] : adj_regime ;
assign  exp_sign  = done? scale_out[9] : exp_sign  ;
	 
parameter         IDLE     = 2'b00,
        SHIFTING = 2'b01,
        DONE_ST  = 2'b10 ;

    reg[1:0] current_state, next_state;

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
    always @(posedge clk) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case (current_state)

            IDLE: begin
                if(start)
                    next_state = SHIFTING;
                else
                    next_state = IDLE;
            end

            SHIFTING: begin
                if ((mant_work[63:62] != 2'b00) || (mant_work[62] == 1'b1) || (mant_work == 64'b0))
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
           // done        <= 0;
        end else begin

            case (current_state)

            IDLE: begin
				   if(start) begin
               scale_out   <= scale_in;
                mant_adj    <= mant_prod;
                mant_work   <= mant_prod;
                shift_amt   <= 0;
                shift_count <= 0;
					 end
             //   done        <= 0;
            end

            SHIFTING: begin
                
                case (mant_work[63:62])

                    2'b11: begin
                        mant_adj    <= mant_work >> 1;
                        scale_out   <= scale_out + 1;
                        shift_amt   <= 1;
                    end

                    2'b10: begin
                        mant_adj    <= mant_work >> 1;
                        scale_out   <= scale_out + 1;
                        shift_amt   <= 1;
                    end

                    2'b01: begin
                        mant_adj <= mant_work;
                        shift_amt <= 0;
                    end

                    2'b00: begin
                        if (mant_work[62] == 1'b0 && mant_work != 64'b0) begin
                            mant_work   <= mant_work << 1;
                            shift_count <= shift_count + 1;
                            scale_out   <= scale_out - 1;
                        end else begin
                            mant_adj  <= mant_work;
                            shift_amt <= shift_count;
                        end
                    end

                endcase
            end

            DONE_ST: begin
//                mant_adj  <= mant_work;
//                shift_amt <= shift_count;
            //    done      <= 1;
            end

            endcase
        end
    end
assign done = (current_state == DONE_ST) ;

endmodule
