
module posit_encoder_tb;


reg start,clk,rst,received;
reg   sign_out;
reg  signed [5:0] k_out;//k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
reg  [2:0] exp_out;
reg [31:0] mantissa_out;
//input [4:0] mant_size,
//output reg  [31:0] posit_num,
wire  [31:0] p_hold;
wire  done;

posit_encoder dut1(start,clk,rst,received,sign_out,k_out,exp_out,mantissa_out,p_hold,done);


initial begin
clk=0;
received=0;
rst=0;#100;
sign_out=1;
k_out=-5;
exp_out=3'b101;
mantissa_out=32'hf0000000;
rst=1;
start=1;#1000;
received=1;

#1000;
$finish;
end


always@(*) begin
if(done) start=0;
end




always #5 clk=~clk;

endmodule

























