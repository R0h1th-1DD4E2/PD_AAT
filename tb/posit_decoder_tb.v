//module posit_decoder_tb;
//
//
//reg [31:0] posit_num;
//reg start,clk,rst,received;
//wire  sign, done,ZERO,NAR;
//wire  [5:0] k;//k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
//wire [2:0] exp_value;
//wire [31:0] mantissa;
//
//
//posit_decoder dut1(posit_num,start,clk,rst,received,sign,done,ZERO,NAR,k,exp_value,mantissa);
//
//
//initial begin
//clk=0;
//received=0;
//rst=0;#100;
//posit_num=32'h80000000;
//rst=1;
//start=1;#100;
//received=1;
//
//#1000;
//$finish;
//end
//
//
//always@(*) begin
//if(done) start=0;
//end
//
//
//
//
//always #5 clk=~clk;
//
//endmodule



module posit_decoder_tb;

reg  [31:0] posit_num;
reg  start, clk, rst, received;

wire sign, done, ZERO, NAR;
wire signed [5:0] k;             
wire [2:0] exp_value;           
wire [31:0] mantissa;

posit_decoder dut1(
    posit_num,
    start,
    clk,
    rst,
    received,
    sign,
    done,
    ZERO,
    NAR,
    k,
    exp_value,
    mantissa
);

initial begin
    clk = 0;
    received = 0;

    // ----------------------------------------------------
    // RESET
    // ----------------------------------------------------
    rst = 0; #100;
    rst = 1;

    // ----------------------------------------------------
    // TEST CASE 1: Check NaR (0x8000_0000)
    // ----------------------------------------------------
    $display("TEST 1: NaR input");
    posit_num = 32'h80000000;
    start     = 1;
    #100; received = 1;
    #100; start = 0;
    #200;

    // ----------------------------------------------------
    // TEST CASE 2: Zero
    // ----------------------------------------------------
    $display("TEST 2: Zero input");
    posit_num = 32'h00000000;
    start     = 1;
    received  = 0;
    #100; received = 1;
    #100; start = 0;
    #200;

    // ----------------------------------------------------
    // TEST CASE 3: Output from encoder TEST 1 (0x007FF97E)
    // ----------------------------------------------------
    $display("TEST 3: Encoder test #1 result");
    posit_num = 32'h007FF97E;
    start     = 1;
    received  = 0;
    #100; received = 1;
    #100; start = 0;
    #200;

    // ----------------------------------------------------
    // TEST CASE 4: Output from encoder TEST 2 (0xC33FFFFF)
    // ----------------------------------------------------
    $display("TEST 4: Encoder test #2 result");
    posit_num = 32'hC33FFFFF;
    start     = 1;
    received  = 0;
    #100; received = 1;
    #100; start = 0;
    #200;

    // ----------------------------------------------------
    // TEST CASE 5: Largest positive regime (0xFFFFFFFE)
    // ----------------------------------------------------
    $display("TEST 5: Large positive regime");
    posit_num = 32'hFFFFFFFE;
    start     = 1;
    received  = 0;
    #100; received = 1;
    #100; start = 0;
    #200;

    // ----------------------------------------------------
    // TEST CASE 6: Negative regime (0xAAAB2000)
    // ----------------------------------------------------
    $display("TEST 6: Negative regime input");
    posit_num = 32'hAAAB2000;
    start     = 1;
    received  = 0;
    #100; received = 1;
    #100; start = 0;
    #200;

    $finish;
end

always @(*) begin
    if(done)
        start = 0;
end

always #5 clk = ~clk;

endmodule



































