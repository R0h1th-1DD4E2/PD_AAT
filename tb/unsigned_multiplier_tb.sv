`timescale 1ns / 1ps

module unsigned_multiplier_tb;

    // Parameters
    parameter N = 32;  // 32-bit multiplier
    parameter CLK_PERIOD = 10;
    
    // Signals
    reg clk, rst_n, load, recieved;
    reg [N-1:0] A, B;
    wire done, init;
    wire [2*N-1:0] C;
    
    // Expected result
    reg [2*N-1:0] expected;
    integer test_count, pass_count, fail_count;
    
    // Instantiate DUT
    unsigned_multiplier #(.N(N)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .recieved(recieved),
        .A(A),
        .B(B),
        .done(done),
        .init(init),
        .C(C)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        load = 0;
        recieved = 0;
        A = 0;
        B = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // VCD dump for waveform viewing
        $dumpfile("unsigned_multiplier.vcd");
        $dumpvars(0, unsigned_multiplier_tb);
        
        // Apply reset
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        $display("========================================");
        $display("Unsigned Multiplier Testbench - %0d-bit", N);
        $display("========================================\n");
        
        // Test 1: Simple small multiplication
        test_multiply(32'd5, 32'd3, "5 * 3");
        
        // Test 2: Zero multiplication
        test_multiply(32'd0, 32'd100, "0 * 100");
        test_multiply(32'd100, 32'd0, "100 * 0");
        
        // Test 3: One multiplication
        test_multiply(32'd1, 32'd42, "1 * 42");
        test_multiply(32'd42, 32'd1, "42 * 1");
        
        // Test 4: Power of 2
        test_multiply(32'd16, 32'd4, "16 * 4");
        test_multiply(32'd256, 32'd256, "256 * 256");
        
        // Test 5: Small values
        test_multiply(32'd15, 32'd15, "15 * 15");
        test_multiply(32'd7, 32'd6, "7 * 6");
        
        // Test 6: Medium values
        test_multiply(32'd1000, 32'd500, "1000 * 500");
        test_multiply(32'd12345, 32'd678, "12345 * 678");
        
        // Test 7: Large values
        test_multiply(32'd65535, 32'd65535, "65535 * 65535 (16-bit max)");
        test_multiply(32'd1000000, 32'd1000, "1000000 * 1000");
        
        // Test 8: Maximum values (no overflow in 64-bit result)
        test_multiply(32'd4294967295, 32'd1, "4294967295 * 1 (32-bit max)");
        test_multiply(32'd4294967295, 32'd2, "4294967295 * 2");
        test_multiply(32'd65536, 32'd65536, "65536 * 65536");
        
        // Test 9: Maximum value multiplication (the ultimate test!)
        test_multiply(32'hFFFFFFFF, 32'hFFFFFFFF, "0xFFFFFFFF * 0xFFFFFFFF (max * max)");
        
        // Test 9: Random test values
        test_multiply(32'd37, 32'd19, "37 * 19");
        test_multiply(32'd63, 32'd25, "63 * 25");
        test_multiply(32'd123456, 32'd789, "123456 * 789");
        test_multiply(32'hc0000000, 32'hc0000000, "3221225472 * 3221225472");
        
        // Test 10: Powers of 2
        test_multiply(32'd1024, 32'd1024, "1024 * 1024");
        test_multiply(32'd2048, 32'd512, "2048 * 512");
        
        // Test 11: Back-to-back operations
        $display("\n--- Testing Back-to-Back Operations ---");
        test_multiply(32'd10, 32'd10, "10 * 10 (back-to-back 1)");
        test_multiply(32'd20, 32'd5, "20 * 5 (back-to-back 2)");
        test_multiply(32'd100, 32'd100, "100 * 100 (back-to-back 3)");
        
        // Test 12: Edge cases with large numbers
        test_multiply(32'd4095, 32'd4095, "4095 * 4095");
        test_multiply(32'd8388607, 32'd2, "8388607 * 2");
        
        // Summary
        #(CLK_PERIOD*5);
        $display("\n========================================");
        $display("Test Summary:");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (fail_count == 0)
            $display("*** ALL TESTS PASSED! ***");
        else
            $display("*** SOME TESTS FAILED ***");
        $display("========================================\n");
        
        #(CLK_PERIOD*5);
        $finish;
    end
    
    // Task to perform multiplication test
    task test_multiply;
        input [N-1:0] val_a, val_b;
        input [256*8-1:0] test_name;
        begin
            test_count = test_count + 1;
            
            // Calculate expected result (unsigned multiplication)
            expected = val_a * val_b;
            
            // Apply inputs
            A = val_a;
            B = val_b;
            
            // Pulse load signal
            @(posedge clk);
            load = 1;
            @(posedge clk);
            load = 0;
            
            // Wait for done signal
            wait(done == 1);
            @(posedge clk);
            
            // Check result
            if (C === expected) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                $display("       A=%0d (0x%h), B=%0d (0x%h)", A, A, B, B);
                $display("       Result=%0d (0x%h), Expected=%0d (0x%h)", 
                         C, C, expected, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       A=%0d (0x%h), B=%0d (0x%h)", A, A, B, B);
                $display("       Result=%0d (0x%h), Expected=%0d (0x%h)", 
                         C, C, expected, expected);
                $display("       ERROR: Mismatch!");
                fail_count = fail_count + 1;
            end
            
            // Pulse recieved signal to return to IDLE
            @(posedge clk);
            recieved = 1;
            @(posedge clk);
            recieved = 0;
            
            // Wait for state machine to return to IDLE
            @(posedge clk);
            #(CLK_PERIOD);
        end
    endtask
    
    // Timeout watchdog (longer timeout for 32-bit operations)
    initial begin
        #(CLK_PERIOD * 50000);
        $display("\n[ERROR] Simulation timeout!");
        $display("Test may be stuck in infinite loop.\n");
        $finish;
    end
    
    // Monitor for debugging (optional - comment out if too verbose)
    initial begin
        $monitor("Time=%0t | State=%b | A=%h B=%h | ACC=%h Q=%h | Counter=%0d | Done=%b | C=%h",
                 $time, dut.cur_state, dut.M, dut.Q, dut.ACC, dut.Q, dut.counter, done, C);
    end

endmodule