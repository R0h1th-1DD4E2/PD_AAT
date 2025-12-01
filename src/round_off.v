module round_off(
  input wire [63:0]shifted_mantissa,
  input wire k_out,
  output reg mantissa_out
);

reg int no_bt;
  
  always@()
  begin
    if(k_out >= 0)
      no_bt  = 32-1-(k_out+2)-3;
    else
      no_bt  = 32-1-((-k_out)+2)-3;
  end 
  
  assign mantissa_out = { data_in[63:(63-no_bt+1)], 9'b0 };
