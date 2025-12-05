`timescale 1ns / 1ps

module posit_mul_tb;

    // Testbench signals
    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [31:0] posit_a;
    reg  [31:0] posit_b;
    wire [31:0] posit_result;
    wire        done;
    wire        NAR;
    wire        ZERO;

    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    posit_mul dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .posit_a(posit_a),
        .posit_b(posit_b),
        .posit_result(posit_result),
        .done(done),
        .NAR(NAR),
        .ZERO(ZERO)
    );

    // Task to apply test case and wait for result
    task test_multiply;
        input [31:0] a;
        input [31:0] b;
        input [255:0] test_name;
        begin
            @(posedge clk);
            posit_a = a;
            posit_b = b;
            start = 1'b1;
            
            @(posedge clk);
            start = 1'b0;
            
            // Wait for done signal
            wait(done == 1'b1);
            @(posedge clk);
            
            // Display results
            $display("===========================================");
            $display("Test: %s", test_name);
            $display("Time: %0t ns", $time);
            $display("Input A:  0x%h", a);
            $display("Input B:  0x%h", b);
            $display("Result:   0x%h", posit_result);
            $display("NAR flag: %b", NAR);
            $display("ZERO flag: %b", ZERO);
            $display("===========================================\n");
            
            // Small delay before next test
            repeat(2) @(posedge clk);
        end
    endtask

    // Test sequence
    initial begin
        // Initialize waveform dump
        $dumpfile("posit_mul_tb.vcd");
        $dumpvars(0, posit_mul_tb);
        
        // Initialize signals
        rst_n = 0;
        start = 0;
        posit_a = 32'h0;
        posit_b = 32'h0;
        
        // Apply reset
        #20;
        rst_n = 1;
        #20;
        
        $display("\n========================================");
        $display("Starting Posit Multiplier Testbench");
        $display("========================================\n");
        
        // Test Case 1: Basic multiplication
        test_multiply(32'h40000000, 32'h40000000, "1.0 * 1.0");
        
        // Test Case 2: Multiply by 2
        test_multiply(32'h50000000, 32'h40000000, "2.0 * 1.0");
        
        // Test Case 3: Small numbers
        test_multiply(32'h30000000, 32'h30000000, "0.5 * 0.5");
        
        // Test Case 4: Zero multiplication
        test_multiply(32'h00000000, 32'h40000000, "0 * 1.0");
        
        // Test Case 5: Zero * Zero
        test_multiply(32'h00000000, 32'h00000000, "0 * 0");
        
        // Test Case 6: NAR input A
        test_multiply(32'h80000000, 32'h40000000, "NAR * 1.0");
        
        // Test Case 7: NAR input B
        test_multiply(32'h40000000, 32'h80000000, "1.0 * NAR");
        
        // Test Case 8: NAR * NAR
        test_multiply(32'h80000000, 32'h80000000, "NAR * NAR");
        
        // Test Case 9: Negative number multiplication
        test_multiply(32'hC0000000, 32'h40000000, "-1.0 * 1.0");
        
        // Test Case 10: Negative * Negative
        test_multiply(32'hC0000000, 32'hC0000000, "-1.0 * -1.0");
        
        // Test Case 11: Large number multiplication
        test_multiply(32'h60000000, 32'h60000000, "4.0 * 4.0");
        
        // Test Case 12: Mixed magnitude
        test_multiply(32'h48000000, 32'h38000000, "1.5 * 0.75");
        
        // Add more test cases as needed
        
        // Wait some time after last test
        #100;
        
        $display("\n========================================");
        $display("Testbench Complete");
        $display("========================================\n");
        
        $finish;
    end

    // Timeout watchdog (prevents infinite simulation)
    initial begin
        #100000000; // 100us timeout
        $display("\n*** ERROR: Simulation timeout! ***\n");
        $finish;
    end

    // Optional: Monitor for debugging
    initial begin
        $monitor("Time=%0t | start=%b | done=%b | NAR=%b | ZERO=%b | result=0x%h", 
                 $time, start, done, NAR, ZERO, posit_result);
    end

endmodule



























