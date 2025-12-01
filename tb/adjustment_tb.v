



`timescale 1ns/1ps

module adjustment_tb;

    reg clk, reset, start;
    reg [9:0]  scale_in;
    reg [63:0] mant_prod;

    wire [9:0] scale_out;
    wire [63:0] mant_adj;
    wire [63:0] shift_amt;
    wire done;
    wire [2:0] adj_exp;
    wire [5:0] adj_regime;
    wire exp_sign;

    // Instantiate DUT
    adjustment dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .scale_in(scale_in),
        .mant_prod(mant_prod),
        .scale_out(scale_out),
        .mant_adj(mant_adj),
        .shift_amt(shift_amt),
        .done(done),
        .adj_exp(adj_exp),
        .adj_regime(adj_regime),
        .exp_sign(exp_sign)
    );

    // Clock generation
    always #5 clk = ~clk;

    task run_case(input [63:0] mant_val, input [8*20:1] label);
    begin
        @(posedge clk);
        $display("\n==============================");
        $display(" Running case: %s", label);
        $display("==============================");

        start     = 1;
        mant_prod = mant_val;
        scale_in  = 10'd100;

        @(posedge clk);
        start = 0;

        wait(done);

        @(posedge clk);
        $display("DONE for %s:", label);
        $display(" mant_prod  = %h", mant_val);
        $display(" mant_adj   = %h", mant_adj);
        $display(" scale_out  = %d", scale_out);
        $display(" shift_amt  = %d", shift_amt);
        $display(" exp_sign   = %b", exp_sign);
        $display(" adj_regime = %d", adj_regime);
        $display(" adj_exp    = %d", adj_exp);
    end
    endtask


    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        mant_prod = 0;
        scale_in = 0;

        #20 reset = 0;

        // CASE 1: mant_work[63:62] = 2'b11
        run_case(64'hC000000000000000, "Case 1: 11");

        // CASE 2: mant_work[63:62] = 2'b10
        run_case(64'h8000000000000000, "Case 2: 10");

        // CASE 3: mant_work[63:62] = 2'b01
        run_case(64'h4000000000000000, "Case 3: 01");

        // CASE 4: mant_work[63:62] = 2'b00 (normalize left shift)
        run_case(64'h00F0000000000000, "Case 4: 00");

        #50;
        $display("\nAll cases completed.");
        $finish;
    end

endmodule
