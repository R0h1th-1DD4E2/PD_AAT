//
//module posit_encoder_tb;
//
//
//reg start,clk,rst,received;
//reg   sign_out;
//reg  signed [5:0] k_out;//k (regime value) it can take values in the range [-31,30], so 6 bits to represent, k is the run length of regime.
//reg  [2:0] exp_out;
//reg [31:0] mantissa_out;
////input [4:0] mant_size,
////output reg  [31:0] posit_num,
//wire  [31:0] p_hold;
//wire  done;
//
//posit_encoder dut1(start,clk,rst,received,sign_out,k_out,exp_out,mantissa_out,p_hold,done);
//
//
//initial begin
//clk=0;
//received=0;
//rst=0;#100;
//sign_out=0;
//k_out=5;
//exp_out=3'b100;
//mantissa_out=32'hfff00000;
//rst=1;
//start=1;#1000;
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







module posit_encoder_tb;

reg start, clk, rst, received;
reg sign_out;
reg signed [5:0] k_out;           // range [-31,30]
reg [2:0] exp_out;
reg [31:0] mantissa_out;

wire [31:0] p_hold;
wire done;

posit_encoder dut1(
    start,
    clk,
    rst,
    received,
    sign_out,
    k_out,
    exp_out,
    mantissa_out,
    p_hold,
    done
);

initial begin
    clk = 0;
    rst = 0;
    received = 0;
    start = 0;

    #50 rst = 1;

    // --------------------------------------------------
    // TEST CASE 1 : Positive number, small k
    // --------------------------------------------------
    sign_out      = 0;
    k_out         = 5;
    exp_out       = 3'b100;
    mantissa_out  = 32'hFFF00000;

    #50 start = 1;
    #200 received = 1;
    wait(done);
    #50 start = 0;
    received = 0;
    #300;

    // --------------------------------------------------
    // TEST CASE 2 : Negative number, large positive k
    // --------------------------------------------------
    sign_out      = 1;
    k_out         = 20;             // long run of 1's regime
    exp_out       = 3'b011;
    mantissa_out  = 32'h0F0F0F0F;

    #50 start = 1;
    #200 received = 1;
    wait(done);
    #50 start = 0;
    received = 0;
    #300;

    // --------------------------------------------------
    // TEST CASE 3 : Negative k (regime of 0's)
    // --------------------------------------------------
    sign_out      = 0;
    k_out         = -12;            // regime of 0's length=12
    exp_out       = 3'b001;
    mantissa_out  = 32'hAAAAAAAA;

    #50 start = 1;
    #200 received = 1;
    wait(done);
    #50 start = 0;
    received = 0;
    #300;

    // --------------------------------------------------
    // TEST CASE 4 : Zero mantissa test
    // --------------------------------------------------
    sign_out      = 0;
    k_out         = 1;
    exp_out       = 3'b000;
    mantissa_out  = 32'h00000000;

    #50 start = 1;
    #200 received = 1;
    wait(done);
    #50 start = 0;
    received = 0;
    #300;

    // --------------------------------------------------
    // TEST CASE 5 : Extreme k (min)
    // --------------------------------------------------
    sign_out      = 1;
    k_out         = -31;            // lowest k (edge)
    exp_out       = 3'b111;
    mantissa_out  = 32'h12345678;

    #50 start = 1;
    #200 received = 1;
    wait(done);
    #50 start = 0;
    received = 0;
    #300;

    // --------------------------------------------------
    // TEST CASE 6 : Extreme k (max)
    // --------------------------------------------------
    sign_out      = 0;
    k_out         = 30;             // highest k (edge)
    exp_out       = 3'b010;
    mantissa_out  = 32'h87654321;

    #50 start = 1;
    #200 received = 1;
    wait(done);
    #50 start = 0;
    received = 0;
    #300;

    $finish;
end

// Drop start automatically once done = 1
always @(*) begin
    if(done) start = 0;
end

// Clock
always #5 clk = ~clk;

endmodule






















