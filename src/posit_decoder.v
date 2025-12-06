`timescale 1ns / 1ps

module posit_decoder (
	input  [31:0] posit_num,
	input         start,
	input         clk,
	input         rst,
	input		  recieved,
	output reg    sign,
	output reg    done,
	output reg    ZERO,
	output reg    NAR,
	output reg signed [5:0] k,       // Regime value k ∈ [-31, 30]
	output reg [2:0] exp_value,
	output reg [31:0] mantissa
);

reg [2:0]  state;
reg [31:0] p_hold;

parameter start_d         = 3'd0;
parameter sign_d          = 3'd1;
parameter left_shift      = 3'd2;
parameter regime_value_d  = 3'd3;
parameter es_value_d      = 3'd4;
parameter mantissa_d      = 3'd5;
parameter complete_d      = 3'd6;

reg flag1, flag0,special;
// reg [5:0] count;

always @(posedge clk or negedge rst) begin // active low reset
	if (!rst) begin
		state     <= start_d;
		p_hold    <= 32'd0;
		flag1     <= 1'b0;
		flag0     <= 1'b0;
		k         <= 6'd0;
		exp_value <= 3'd0;
		mantissa  <= 32'd0;
		done      <= 1'b0;
		ZERO      <= 1'b0;
		NAR       <= 1'b0;
		special   <= 1'b0;
		// count     <= 6'd0;
	end else begin
		case (state)
			start_d: begin
				if (start) begin
					p_hold <= posit_num;
					state  <= sign_d;
				end else begin
					state     <= start_d;
					p_hold    <= 32'd0;
					flag1     <= 1'b0;
					flag0     <= 1'b0;
					k         <= 6'd0;
					exp_value <= 3'd0;
					mantissa  <= 32'd0;
					done      <= 1'b0;
					ZERO      <= 1'b0;
					NAR       <= 1'b0;
					special   <= 1'b0;
					// count     <= 6'd0;
				end
			end

			sign_d: begin
			  if(p_hold[31]) begin
				sign   <= 1'b1;
			   p_hold <= (~p_hold) +32'b1;
				state  <= left_shift;
				end
				else begin
				 sign  <= 1'b0;
				 p_hold <= p_hold;
	          state  <= left_shift;			 
				  end
				 	
				
			end
			
			left_shift:begin
			             p_hold <= p_hold << 1'b1;
							  state  <= regime_value_d;
			             end

			regime_value_d: begin
				// Sequence of 1's followed by terminating 0
				if (p_hold[31] && !flag0) begin
					flag1 <= 1'b1;
					k     <= k + 6'd1;
					p_hold <= p_hold << 1'b1;
					state  <= regime_value_d;
				end else if (flag1 && !flag0) begin
					if (k == 6'd31) begin
						state <= complete_d;
						k     <= k - 6'd1;
					end else begin
						k      <= k - 6'd1;
						flag1  <= 1'b0;
						state  <= es_value_d;
						p_hold <= p_hold << 1'b1;
					end
				end else begin
					// Sequence of 0's followed by terminating 1
					if (!p_hold[31]) begin
						if (k < 6'd31) begin 
						flag0  <= 1'b1;
						k      <= k + 6'd1;
						p_hold <= p_hold << 1'b1;
						state  <= regime_value_d;
						// count  <= count + 1'b1;
					   end 
						else begin// NAR and ZERO decoding
							state <= complete_d;
							special<=1'b1;
						end
					end else begin
						k      <= -k;
						state  <= es_value_d;
						flag0  <= 1'b0;
						p_hold <= p_hold << 1'b1;
					end
				end
			end

			es_value_d: begin
				exp_value <= p_hold[31:29];
				p_hold    <= p_hold << 3;
				state     <= mantissa_d;
			end

			mantissa_d: begin
				mantissa <= {1'b1, p_hold[31:1]};
				state    <= complete_d;
			end

			complete_d: begin
			if(special) begin
			            if (sign) begin
							NAR <= 1'b1;
							done<=1;
							state<=start_d;
							end
							else begin    
							ZERO <= 1'b1;
							done<=1;
							state<=start_d;
							end
			        end
			else if(recieved) begin
			state<=start_d;
			done<=0;
			   end 
			
			else begin
			done<=1;
			state<=complete_d;
			end
//				done  <= 1'b1;
//				state <= (recieved) ? start_d : complete_d;
			end

			default: begin
				state <= start_d;
				done  <= 1'b0;
			end
		endcase
	end
end

endmodule


























