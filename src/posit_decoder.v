



module posit_decoder(
input [31:0] posit_num,
input start,clk,rst,
output reg sign, done,
output  reg signed [5:0] k,//k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
output reg [2:0] exp_value,
output reg [31:0] mantissa
);


reg [2:0] state;
reg [31:0] p_hold;
parameter start_d=3'd0,sign_d=3'd1,regime_value_d=3'd2,es_value_d=3'd3,mantissa_d=3'd4,complete_d=3'd5;

reg flag1,flag0,comp_int;

always@(posedge clk)
 begin
if(rst)begin
                     state <= start_d;
			            p_hold <=32'd0;
							flag1<=0;
							flag0<=0;
							k=0;
							exp_value=0;
							//mul_start=0;
							mantissa=0;
							done=0;

      end
  else begin
  case(state)
    start_d: begin
					 if(start)
                   begin
                     p_hold <= posit_num;
							state <= sign_d;
						 end
		 
	             else 
	                begin
		               state <= start_d;
			            p_hold <=32'd0;
							flag1<=0;
							flag0<=0;
							k=0;
							exp_value=0;
							//mul_start=0;
							mantissa=0;
							done=0;
							
		             end
		             
				  end
	 
	 sign_d: begin
	           sign = p_hold[31];
				  p_hold <= p_hold << 1'b1;
				  state <= regime_value_d;
				  
	         end
	  
	 regime_value_d: begin
	                     if(p_hold[31] && !flag0)// seq of 1's followed by terminating 0
								  begin
								    flag1<=1;
									 k<= k+6'd1;
									 p_hold <= p_hold << 1'b1;
									 state<=regime_value_d;
								   
								  end
								 
								 else if(flag1 && !flag0 ) 
								   begin
									k<= k-6'd1;
									flag1<=0;
									state<=es_value_d;
									p_hold <= p_hold << 1'b1;
									
									end
									
								 else // seq of 0's followed by terminating 1
								    begin
									 if( !p_hold[31] )
									    begin
										 flag0<=1;
										  k<= k+6'd1;
										 p_hold <= p_hold << 1'b1;
										 state<=regime_value_d;
										 end
									 
									 else
									    begin
									    k<= -k;//
										 state<= es_value_d;
										 flag0=0;
										 p_hold <= p_hold << 1'b1;
										 end

									 
									 end
								  
	                  end
				
					 
		es_value_d: begin
		               exp_value<=p_hold[31:29];
							p_hold <= p_hold << 2'd3;
							state<= mantissa_d;
		
                  end	
						
	   mantissa_d:begin
		            mantissa<={1'b1,p_hold[31:1]};
						state <= complete_d;
						
	              end
					  
		complete_d:begin
	               done=1;
						state<=start_d;
						end
					   	
		
		
		
	  default: begin
	            state <= start_d;
					done = 0;
					end
	
  endcase
  

 end
end
 
 endmodule
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 