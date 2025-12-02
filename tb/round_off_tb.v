//`timescale 1ns/1ps
//
//module tb_round_off;
//
//    // DUT inputs
//    reg         clk;
//    reg         rst_n;               // active LOW reset
//    reg         start;
//    reg  [63:0] shifted_mantissa;
//    reg  [5:0]  k_out;
//    reg [2:0]   exp_out;
//    reg         sign_out;
//
//    // DUT output
//    wire [31:0] mantissa_out;
//    wire        done;
//    wire[5:0]    k_final;
//    wire[2:0]    exp_final;
//    wire        sign_final;
//
//    // Instantiate DUT
//    round_off dut(
//        .clk(clk),
//        .rst_n(rst_n),
//        .start(start),
//        .shifted_mantissa(shifted_mantissa),
//        .k_out(k_out),
//        .sign_out(sign_out),
//        .exp_out(exp_out),
//        .mantissa_out(mantissa_out),
//        .k_final(k_final),
//        .sign_final(sign_final),
//        .exp_final(exp_final),
//        .done(done)
//    );
//
//    // Clock generation - 10 ns period
//    always #5 clk = 1;
//    
//  
// // Task to apply a single test
//    task apply_test(input [63:0] sm, input signed [5:0] k);
//    begin
//        @(posedge clk);
//        shifted_mantissa = sm;
//        k_out            = k;
//        start            = 1'b1;      // raise start for 1 cycle
//        @(posedge clk);
//        start            = 1'b0;
//
//        wait(done);                  // wait for FSM to reach COMPLETE
//        @(posedge clk);
//
//        $display("TIME=%0t | SM=%h | k=%0d | mantissa_out=%h",
//                  $time, sm, k, mantissa_out);
//    end
//    endtask
//
//    // MAIN STIMULUS
//    initial begin
//        // Initial values
//        clk = 0;
//        rst_n = 1;         // start OUT OF reset
//        start = 0;
//        shifted_mantissa = 64'd0;
//        k_out = 6'd0;
//
//        // Apply ACTIVE-LOW reset properly: 1 -> 0 -> 1
//        #10 rst_n = 0;     // ASSERT reset
//        #20 rst_n = 1;     // DEASSERT reset
//                
//        // ------------ TEST VECTORS -------------
//        // Basic tests
//        apply_test(64'hFFFF_FFFF_FFFF_FFFF,  6'd2);
//        apply_test(64'h1234_5678_ABCD_EF01,  6'd5);
//        apply_test(64'h0F0E_0D0C_0B0A_0908, -6'sd3);
//        apply_test(64'hDEAD_BEEF_DEAD_BEEF, -6'sd7);
//
//        // Edge cases for k_out
//        apply_test(64'hAAAAAAAA_AAAAAAAA,   6'd0);    // smallest +ve
//        apply_test(64'hBBBBBBBB_BBBBBBBB,   6'd1);
//        apply_test(64'hCCCCCCCC_CCCCCCCC,   6'd26);   // max before negative rule flips
//        apply_test(64'hDDDDDDDD_DDDDDDDD,  -6'sd1);   // smallest negative
//        apply_test(64'hEEEEEEEE_EEEEEEEE,  -6'sd2);
//        apply_test(64'hFFFFFFFF_00000000,  -6'sd31);  // large negative magnitude
//
//        // Pattern tests
//        apply_test(64'h0000_0000_0000_0000,  6'd4);   // All zeros mantissa
//        apply_test(64'hFFFF_0000_FFFF_0000,  6'd8);   // alternating chunks
//        apply_test(64'hF0F0_F0F0_F0F0_F0F0,  6'd10);  // alternating 11110000
//        apply_test(64'h0F0F_0F0F_0F0F_0F0F,  6'd12);  // alternating 00001111
//        apply_test(64'hAAAAAAAA_55555555,   6'd15);   // classic checkerboard
//
//        // Random-like values
//        apply_test(64'h1234_ABCD_4321_DCBA, -6'sd4);
//        apply_test(64'h89AB_CDEF_0123_4567,  6'd17);
//        apply_test(64'h7654_3210_FEDC_BA98, -6'sd12);
//        apply_test(64'h1357_9BDF_2468_ACE0,  6'd20);
//
//        // Extreme mix
//        apply_test(64'h8000_0000_0000_0001,  6'd25);   // MSB + LSB only
//        apply_test(64'h7FFF_FFFF_FFFF_FFFF, -6'sd6);   // all ones except MSB
//        apply_test(64'h0000_FFFF_0000_FFFF,  6'd3);    // repeating halves
//        apply_test(64'hFF00_FF00_FF00_FF00, -6'sd8);   // repeating 1111111100000000
//
//        #100;
//        $finish;
//    end
//
//  initial begin
//      $dumpfile("round_off_tb.vcd");
//    $dumpvars(0, tb_round_off);
//  end
//
//endmodule
//
//



`timescale 1ns/1ps

module round_off_tb;

    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [63:0] shifted_mantissa;
    reg  [5:0]  k_out;
    reg         sign_out;
    reg  [2:0]  exp_out;

    wire [31:0] mantissa_out;
    wire [5:0]  k_final;
    wire        sign_final;
    wire [2:0]  exp_final;
    wire        done;

    // DUT
    round_off dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .shifted_mantissa(shifted_mantissa),
        .k_out(k_out),
        .sign_out(sign_out),
        .exp_out(exp_out),
        .mantissa_out(mantissa_out),
        .k_final(k_final),
        .sign_final(sign_final),
        .exp_final(exp_final),
        .done(done)
    );

    // 10ns clock
    always #5 clk = ~clk;


    // Task to run a single test
//    task run_test(
//        input [63:0] sm,
//        input [5:0]  k,
//        input        s,
//        input [2:0]  e
//    );
//    begin
//        shifted_mantissa = sm;
//        k_out            = k;
//        sign_out         = s;
//        exp_out          = e;
//
//        start = 1;
//        @(posedge clk);
//        start = 0;
//
//        // wait for done
//        wait(done == 1);
//
//        // display results
//        $display("\n===============================================");
//        $display(" shifted_mantissa = %h", shifted_mantissa);
//        $display(" k_out  = %0d  (sign=%0d)", k_out, k_out[5]);
//        $display(" exp_out = %0d  sign_out = %0d", exp_out, sign_out);
//        $display(" --> APPROX mantissa_out = %h", mantissa_out);
//        $display("===============================================\n");
//
//        @(posedge clk);
//    end
//    endtask


//    initial begin
//        clk = 0;
//        rst_n = 0;
//        start = 0;
//        shifted_mantissa = 0;
//        k_out = 0;
//        sign_out = 0;
//        exp_out = 0;
//
//        // Reset release
//        repeat(3) @(posedge clk);
//        rst_n = 1;
//
//        // TEST 1: simple shifting, k = +5
//        run_test(64'hFFFF_FFFF_FFFF_F000, 6'd5, 0, 3'd2);
//
//        // TEST 2: k negative (k[5]=1) , k = -4
//        run_test(64'hABCDEF12_34567890, 6'b111100, 1, 3'd3);
//
//        // TEST 3: mid-range mantissa pattern
//        run_test(64'h0123_4567_89AB_CDEF, 6'd10, 0, 3'd6);
//
//        // TEST 4: full ones mantissa
//        run_test(64'hFFFF_FFFF_FFFF_FFFF, 6'd20, 0, 3'd1);
//
//        $display("\nAll tests finished.");
		  
		 

		
	
	

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        shifted_mantissa = 0;
        k_out = 0;
        sign_out = 0;
		  exp_out =0;
        #100;
rst_n=1;
k_out=5;
sign_out=0;
exp_out=3'b100;
//mantissa_out=32'hfff00000;
shifted_mantissa<=64'haaaaaaaaffffffff;
start=1;#1000;
//received=1;

#1000;
$finish;
end


always@(*) begin
if(done) start=0;


      
    end

endmodule



















