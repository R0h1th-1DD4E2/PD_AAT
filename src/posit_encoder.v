`timescale 1ns / 1ps

module posit_encoder(
	input start, clk, rst,
	input sign_out,
	input signed [5:0] k_out,  // k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
	input [2:0] exp_out,
	input [31:0] mantissa_out,
	output reg [31:0] p_hold,
	output reg done,
	output reg init
);

	reg [2:0] state;
	reg [5:0] k_mod, k_pos;  // k_mod for k<0, and k_pos for k>=0.
	parameter start_e = 3'd0, sign_e = 3'd1, regime_value_e = 3'd2, es_value_e = 3'd3, mantissa_e = 3'd4,sign_check =3'd5, complete_e = 3'd6;

	reg [4:0] index, m_cnt;
	reg [1:0] es_count;
	reg sign_reg, kb5;  // 5th bit of k_out.
	reg [2:0] exp_out_reg;
	reg [31:0] mantissa_out_reg;

	always @(posedge clk or negedge rst) begin  // active low reset
		if (!rst) begin
			state <= start_e;
			p_hold <= 32'd0;
			done <= 1'b0;
			index <= 5'd31;
			es_count <= 2;
			m_cnt <= 5'd31;
			sign_reg <= 0;
			exp_out_reg <= 0;
			mantissa_out_reg <= 0;
			kb5 <= 0;
		end
		else begin
			case (state)
				start_e: begin
					if (start) begin
						state <= sign_e;
						k_mod <= -k_out;  // if k_out is -ve, take only magnitude.
						k_pos <= k_out + 1'b1;  // gives number of ones in the regime.
						sign_reg <= sign_out;
						exp_out_reg <= exp_out;
						mantissa_out_reg <= mantissa_out;
						kb5 <= k_out[5];
					end
					else begin
						state <= start_e;
						p_hold <= 32'd0;
						done <= 0;
						index <= 5'd31;
						es_count <= 2;
						m_cnt <= 5'd31;
						sign_reg <= 0;
						exp_out_reg <= 0;
						mantissa_out_reg <= 0;
						kb5 <= 0;
					end
					init <= 1'b0;
				end

				sign_e: begin
					p_hold[index] <= 1'b0;
					state <= regime_value_e;
					index <= index - 5'd1;
					init <= 1'b1;
				end

				regime_value_e: begin
					if (kb5) begin  // k_out is -ve
						if (k_mod == 0) begin
							p_hold[index] <= 1;
							state <= es_value_e;
							index <= index - 5'd1;
						end
						else begin
							index <= index - 5'd1;
							k_mod <= k_mod - 6'd1;
							state <= regime_value_e;
						end
					end
					else begin  // k_out is +ve
						if (k_pos == 0) begin
							p_hold[index] <= 0;
							state <= es_value_e;
							index <= index - 5'd1;
						end
						else begin
							p_hold[index] <= 1;
							index <= index - 5'd1;
							k_pos <= k_pos - 6'd1;
							state <= regime_value_e;
						end
					end
					init <= 1'b0;
				end

				es_value_e: begin
					if (es_count == 0) begin
						index <= index - 5'd1;
						state <= mantissa_e;
						p_hold[index] <= exp_out_reg[es_count];
					end
					else begin
						p_hold[index] <= exp_out_reg[es_count];
						index <= index - 5'd1;
						state <= es_value_e;
						es_count <= es_count - 1'b1;
					end
					init <= 1'b0;
				end

				mantissa_e: begin
					if (index == 0) begin
						p_hold[index] <= mantissa_out_reg[m_cnt];
						state <= sign_check;
					end
					else begin
						p_hold[index] <= mantissa_out_reg[m_cnt];
						index <= index - 5'd1;
						state <= mantissa_e;
						m_cnt <= m_cnt - 5'd1;
					end
					init <= 1'b0;
				end
				
				sign_check: begin
				             if(sign_reg)begin
								     p_hold <= (~p_hold) +32'b1;
									  state <= complete_e;
								    end
								 else begin
								    p_hold <= p_hold;
									  state <= complete_e;
								   end
								 
				             end
				

				complete_e: begin
					done <= 1'b1;
					state <= start_e;
					init <= 1'b0;
				end

				default: begin
					state <= start_e;
					done <= 1'b0;
					init <= 1'b0;
				end
			endcase
		end
	end

endmodule






















