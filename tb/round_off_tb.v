`timescale 1ns/1ps

module tb_round_off;

    // DUT inputs
    reg         clk;
    reg         rst_n;               // active LOW reset
    reg         start;
    reg  [63:0] shifted_mantissa;
    reg  [5:0]  k_out;
    reg [2:0]   exp_out;
    reg         sign_out;

    // DUT output
    wire [31:0] mantissa_out;
    wire        done;
    wire[5:0]    k_final;
    wire[2:0]    exp_final;
    wire        sign_final;

    // Instantiate DUT
    round_off dut(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .shifted_mantissa(shifted_mantissa),
        .k_out(k_out),
        .sign_out(sign_out),
        .exp_out(exp_out),
        .mantissa_out(mantissa_out),
        .k_final(k_final),
        .sign_final(sign_final)
        .exp_final(exp_final)
        .done(done)
    );

    // Clock generation - 10 ns period
    always #5 clk = 1;
    
  
 // Task to apply a single test
    task apply_test(input [63:0] sm, input signed [5:0] k);
    begin
        @(posedge clk);
        shifted_mantissa = sm;
        k_out            = k;
        start            = 1'b1;      // raise start for 1 cycle
        @(posedge clk);
        start            = 1'b0;

        wait(done);                  // wait for FSM to reach COMPLETE
        @(posedge clk);

        $display("TIME=%0t | SM=%h | k=%0d | mantissa_out=%h",
                  $time, sm, k, mantissa_out);
    end
    endtask

    // MAIN STIMULUS
    initial begin
        // Initial values
        clk = 0;
        rst_n = 1;         // start OUT OF reset
        start = 0;
        shifted_mantissa = 64'd0;
        k_out = 6'd0;

        // Apply ACTIVE-LOW reset properly: 1 -> 0 -> 1
        #10 rst_n = 0;     // ASSERT reset
        #20 rst_n = 1;     // DEASSERT reset

        // ------------ EXPANDED TEST VECTORS -------------
        apply_test(64'hFFFF_FFFF_FFFF_FFFF,  6'd2);
        apply_test(64'h1234_5678_ABCD_EF01,  6'd5);
        apply_test(64'h0F0E_0D0C_0B0A_0908, -6'sd3);
        apply_test(64'hDEAD_BEEF_DEAD_BEEF, -6'sd7);

        apply_test(64'hAAAAAAAA_AAAAAAAA,   6'd0);
        apply_test(64'hBBBBBBBB_BBBBBBBB,   6'd1);
        apply_test(64'hCCCCCCCC_CCCCCCCC,   6'd26);
        apply_test(64'hDDDDDDDD_DDDDDDDD,  -6'sd1);
        apply_test(64'hEEEEEEEE_EEEEEEEE,  -6'sd31);

        apply_test(64'h0000_0000_0000_0000,  6'd4);
        apply_test(64'hFFFF_0000_FFFF_0000,  6'd8);
        apply_test(64'hF0F0_F0F0_F0F0_F0F0,  6'd10);
        apply_test(64'h0F0F_0F0F_0F0F_0F0F,  6'd12);

        apply_test(64'hAAAAAAAA_55555555,   6'd15);
        apply_test(64'h1234_ABCD_4321_DCBA, -6'sd4);
        apply_test(64'h89AB_CDEF_0123_4567,  6'd17);
        apply_test(64'h7654_3210_FEDC_BA98, -6'sd12);
        apply_test(64'h1357_9BDF_2468_ACE0,  6'd20);

        apply_test(64'h8000_0000_0000_0001,  6'd25);
        apply_test(64'h7FFF_FFFF_FFFF_FFFF, -6'sd6);
        apply_test(64'h0000_FFFF_0000_FFFF,  6'd3);
        apply_test(64'hFF00_FF00_FF00_FF00, -6'sd8);

        #100;
        $finish;
    end

  initial begin
      $dumpfile("round_off_tb.vcd");
    $dumpvars(0, tb_round_off);
  end

endmodule
