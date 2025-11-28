`timescale 1ns / 1ps

module exp_adder_tb;

// Parameters
parameter ES = 3;
parameter K_BITS = 6;
parameter MAX_BITS = ES + K_BITS;

// Testbench signals
reg clk, rst_n, start;
reg [ES-1:0] exp_A, exp_B;
reg [K_BITS-1:0] k_A, k_B;
reg sign_A, sign_B;
reg valid_out;
wire [MAX_BITS:0] exp_raw;
wire sign_out;
wire NaR;
wire zero_out;
wire done;

// Expected values for checking
integer exp_A_val, exp_B_val, exp_sum_expected;
integer test_num;

// Instantiate the DUT (Device Under Test)
exp_adder #(
    .ES(ES),
    .K_BITS(K_BITS),
    .MAX_BITS(MAX_BITS)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .exp_A(exp_A),
    .esp_B(exp_B),  // Note: typo in original module
    .k_A(k_A),
    .k_B(k_B),
    .sign_A(sign_A),
    .sign_B(sign_B),
    .valid_out(valid_out),
    .exp_raw(exp_raw),
    .sign_out(sign_out),
    .NaR(NaR),
    .zero_out(zero_out),
    .done(done)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period
end

// Test stimulus
initial begin
    // Initialize signals
    rst_n = 0;
    start = 0;
    exp_A = 0;
    exp_B = 0;
    k_A = 0;
    k_B = 0;
    sign_A = 0;
    sign_B = 0;
    valid_out = 0;
    test_num = 0;
    
    // Display header
    $display("\n========================================");
    $display("Exponent Adder Testbench");
    $display("ES=%0d, K_BITS=%0d", ES, K_BITS);
    $display("========================================\n");
    
    // Reset pulse
    #20;
    rst_n = 1;
    #10;
    
    // Test 1: Simple positive exponents
    test_num = 1;
    $display("Test %0d: Simple addition - k_A=2, exp_A=3, k_B=1, exp_B=2", test_num);
    run_test(6'd2, 3'd3, 6'd1, 3'd2, 1'b0, 1'b0);
    
    // Test 2: Zero k values
    test_num = 2;
    $display("\nTest %0d: Zero k values - k_A=0, exp_A=5, k_B=0, exp_B=3", test_num);
    run_test(6'd0, 3'd5, 6'd0, 3'd3, 1'b0, 1'b0);
    
    // Test 3: Negative k values (two's complement)
    test_num = 3;
    $display("\nTest %0d: Negative k - k_A=-2, exp_A=1, k_B=3, exp_B=2", test_num);
    run_test(-6'd2, 3'd1, 6'd3, 3'd2, 1'b0, 1'b0);
    
    // Test 4: Different signs
    test_num = 4;
    $display("\nTest %0d: Different signs - sign_A=0, sign_B=1", test_num);
    run_test(6'd1, 3'd4, 6'd1, 3'd2, 1'b0, 1'b1);
    
    // Test 5: Both negative signs
    test_num = 5;
    $display("\nTest %0d: Both negative signs - sign_A=1, sign_B=1", test_num);
    run_test(6'd2, 3'd3, 6'd1, 3'd5, 1'b1, 1'b1);
    
    // Test 6: Maximum exponent values (test for overflow/NaR)
    test_num = 6;
    $display("\nTest %0d: Large exponents - k_A=25, exp_A=7, k_B=4, exp_B=6", test_num);
    run_test(6'd25, 3'd7, 6'd4, 3'd6, 1'b0, 1'b0);
    
    // Test 7: Very large k values (should overflow to NaR)
    test_num = 7;
    $display("\nTest %0d: Overflow test - k_A=28, exp_A=7, k_B=28, exp_B=7", test_num);
    run_test(6'd28, 3'd7, 6'd28, 3'd7, 1'b0, 1'b0);
    
    // Test 8: Negative k values (test for underflow/zero)
    test_num = 8;
    $display("\nTest %0d: Underflow test - k_A=-30, exp_A=0, k_B=-30, exp_B=0", test_num);
    run_test(-6'd30, 3'd0, -6'd30, 3'd0, 1'b0, 1'b0);
    
    // Test 9: Mixed large positive and negative
    test_num = 9;
    $display("\nTest %0d: Mixed values - k_A=10, exp_A=5, k_B=-5, exp_B=2", test_num);
    run_test(6'd10, 3'd5, -6'd5, 3'd2, 1'b0, 1'b0);
    
    // Test 10: Edge case near maximum
    test_num = 10;
    $display("\nTest %0d: Near maximum - k_A=29, exp_A=6, k_B=0, exp_B=1", test_num);
    run_test(6'd29, 3'd6, 6'd0, 3'd1, 1'b0, 1'b0);
    
    // Final summary
    #50;
    $display("\n========================================");
    $display("Testbench completed - %0d tests run", test_num);
    $display("========================================\n");
    
    $finish;
end

// Task to run a single test
task run_test;
    input [K_BITS-1:0] ka;
    input [ES-1:0] ea;
    input [K_BITS-1:0] kb;
    input [ES-1:0] eb;
    input sa, sb;
    begin
        // Calculate expected exponent value
        exp_A_val = ($signed(ka) << ES) + ea;
        exp_B_val = ($signed(kb) << ES) + eb;
        exp_sum_expected = exp_A_val + exp_B_val;
        
        // Apply inputs
        @(posedge clk);
        k_A = ka;
        k_B = kb;
        exp_A = ea;
        exp_B = eb;
        sign_A = sa;
        sign_B = sb;
        start = 1;
        
        @(posedge clk);
        start = 0;
        
        // Wait for done
        wait(done);
        @(posedge clk);
        
        // Display results
        $display("  Inputs: k_A=%0d, exp_A=%0d, k_B=%0d, exp_B=%0d", 
                 $signed(ka), ea, $signed(kb), eb);
        $display("  Raw exponents: A=%0d, B=%0d, Expected Sum=%0d", 
                 exp_A_val, exp_B_val, exp_sum_expected);
        $display("  Output: exp_raw=%0d (0x%h)", $signed(exp_raw), exp_raw);
        $display("  Sign: A=%b, B=%b, XOR=%b, Output=%b", 
                 sa, sb, sa^sb, sign_out);
        $display("  Flags: NaR=%b, zero_out=%b, done=%b", NaR, zero_out, done);
        
        // Check results
        if (NaR) begin
            $display("  Result: NaR (Overflow detected)");
        end else if (zero_out) begin
            $display("  Result: Zero (Underflow detected)");
        end else if (exp_raw == exp_sum_expected) begin
            $display("  Result: PASS");
        end else begin
            $display("  Result: MISMATCH! Expected %0d, Got %0d", 
                     exp_sum_expected, $signed(exp_raw));
        end
        
        // Clear valid_out to return to IDLE
        valid_out = 1;
        @(posedge clk);
        valid_out = 0;
        @(posedge clk);
    end
endtask

// Monitor for debugging (optional)
initial begin
    $monitor("Time=%0t: State=%0d, done=%b, exp_raw=%0d, NaR=%b, zero=%b", 
             $time, dut.cur_state, done, $signed(exp_raw), NaR, zero_out);
end

// Waveform dump (for viewing in waveform viewer)
initial begin
    $dumpfile("exp_adder_tb.vcd");
    $dumpvars(0, exp_adder_tb);
end

endmodule
