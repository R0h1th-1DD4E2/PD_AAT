module posit_decoder_tb;


reg [31:0] posit_num;
reg start,clk,rst,received;
wire  sign, done,ZERO,NAR;
wire  [5:0] k;//k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
wire [2:0] exp_value;
wire [31:0] mantissa;


posit_decoder dut1(posit_num,start,clk,rst,received,sign,done,ZERO,NAR,k,exp_value,mantissa);


initial begin
clk=0;
received=0;
rst=0;#100;
posit_num=32'h80000000;
rst=1;
start=1;#100;
received=1;

#1000;
$finish;
end


always@(*) begin
if(done) start=0;
end




always #5 clk=~clk;

endmodule
