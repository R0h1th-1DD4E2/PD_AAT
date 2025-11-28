 `timescale 1ns/1ps

module adjustment_tb;

    parameter SCALE_W = 6;

    reg                   clk;
    reg                   reset;
    reg                   start;
    reg  [9:0]    scale_in;
    reg  [63:0]           mant_prod;

    wire [9:0]    scale_out;
    wire [63:0]           mant_adj;
    wire [63:0]    shift_amt;
    wire                  done;
    wire  [2:0]adj_exp  ;
	 wire   [5:0]adj_regime ;
	 wire      exp_sign  ;

    adjustment #( SCALE_W) DUT (
        .clk       (clk),
        .reset     (reset),
        .start     (start),
        .scale_in  (scale_in),
        .mant_prod (mant_prod),
        .scale_out (scale_out),
        .mant_adj  (mant_adj),
        .shift_amt (shift_amt),
        .done      (done) ,
		  .adj_exp  (adj_exp),
		  .adj_regime(adj_regime),
		  .exp_sign (exp_sign )
    );

    always #5 clk = ~clk;

    // =====================================================
    // TASK: Apply stimulus and compare expected values
    // =====================================================
    task test_case;
        input  [SCALE_W-1:0] s;
        input  [63:0]        m;
        input  [SCALE_W-1:0] expected_scale;
        input  [63:0]        expected_mant;
        input  [SCALE_W-1:0] expected_shift;

        begin
            // Apply inputs
            @(posedge clk);
            scale_in  = s;
            mant_prod = m;
            start     = 1;

            @(posedge clk);
            start     = 0;

            // Wait for module to finish
            wait(done);
            @(posedge clk);

            // Compare and report
            $display("\n------------------------------------------------");
            $display("Input  : scale_in=%d, mant_prod=%h", s, m);
            $display("Output : scale_out=%d shift=%d mant_adj=%h",
                    scale_out, shift_amt, mant_adj);

            if (scale_out === expected_scale &&
                shift_amt  === expected_shift &&
                mant_adj   === expected_mant)
            begin
                $display("STATUS : PASS");
            end else begin
                $display("STATUS : FAIL");
                $display("EXPECTED: scale_out=%d shift=%d mant_adj=%h",
                        expected_scale, expected_shift, expected_mant);
            end
            $display("------------------------------------------------\n");
        end
    endtask

    // =====================================================
    // TEST SEQUENCE
    // =====================================================
    initial begin

        clk      = 0;
        reset    = 1;
        start    = 0;
        scale_in = 0;
        mant_prod = 0;

        repeat (3) @(posedge clk);
        reset = 0;

        //----------------------------------------------------
        // TEST 1
        // MSB = 11 → shift right 1 step
        //----------------------------------------------------
        test_case(
            6'd20,
            64'hC000_0000_0000_0000,
            6'd21,                             // expected scale
            64'h6000_0000_0000_0000,           // expected mant_adj
            6'd1                               // shift_amt
        );

        //----------------------------------------------------
        // TEST 2
        // MSB = 10 → shift right
        //----------------------------------------------------
        test_case(
            6'd15,
            64'h8000_0000_0000_0000,
            6'd16,
            64'h4000_0000_0000_0000,
            6'd1
        );

        //----------------------------------------------------
        // TEST 3
        // MSB = 01 → no shift
        //----------------------------------------------------
        test_case(
            6'd8,
            64'h4000_0000_0000_0000,
            6'd8,
            64'h4000_0000_0000_0000,
            6'd0
        );

        //----------------------------------------------------
        // TEST 4
        // MSB = 00 → requires multi-cycle left shift
        //----------------------------------------------------
        // Original mantisa = 0x0200...
        // Needs one left shift to move 1 into bit 62
        test_case(
            6'd30,
            64'h0200_0000_0000_0000,
            6'd29,                              // one left shift subtracts scale
            64'h0400_0000_0000_0000,
            6'd1
        );

        //----------------------------------------------------
        // TEST 5
        // Zero input → should finish immediately
        //----------------------------------------------------
        test_case(
            6'd25,
            64'h0,
            6'd25,
            64'h0,
            6'd0
        );

        $display("\n*** ALL TESTS EXECUTED ***\n");
        $finish;
    end

endmodule
 