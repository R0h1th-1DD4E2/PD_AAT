module posit_decoder_tb;


reg [31:0] posit_num;
reg start,clk,rst;
wire  sign, done;
wire  [5:0] k;//k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
wire [2:0] exp_value;
wire [31:0] mantissa;


posit_decoder dut1(posit_num,start,clk,rst,sign,done,k,exp_value,mantissa);


initial begin
clk=0;
rst=1;#100;
posit_num=32'b00001101110011001100110011001100;
rst=0;
start=1;

#1000;
$finish;
end


always@(*) begin
if(done) start=0;
end




always #5 clk=~clk;

endmodule
