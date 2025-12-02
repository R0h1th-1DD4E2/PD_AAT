



`timescale 1ns/1ps

module adjustment_tb;

    reg clk, rst_n, start;
    reg [9:0]  E_raw;
    reg [63:0] mant_prod;
    reg        sign_in;

    wire [63:0] mant_adj;
    wire done;
    wire [2:0] adj_exp;
    wire [5:0] adj_k;
    wire sign_out;

    // Instantiate DUT
    adjustment dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .E_raw(E_raw),
        .mant_prod(mant_prod),
        .sign_in(sign_in),
        .mant_adj(mant_adj),
        .done(done),
        .adj_exp(adj_exp),
        .adj_k(adj_k),
        .sign_out(sign_out)
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
        E_raw     = 10'd100;
        sign_in   = 0;

        @(posedge clk);
        start = 0;

        wait(done);

        @(posedge clk);
        $display("DONE for %s:", label);
        $display(" mant_prod  = %h", mant_val);
        $display(" mant_adj   = %h", mant_adj);
        $display(" adj_k      = %d", adj_k);
        $display(" adj_exp    = %d", adj_exp);
        $display(" sign_out   = %b", sign_out);
    end
    endtask


    initial begin
        clk = 0;
        rst_n = 1;
        start = 0;
        mant_prod = 0;
        E_raw = 0;
        sign_in = 0;

        #20 rst_n = 0;
        #20 rst_n = 1;

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

    initial begin
        $dumpfile("adjustment_tb.vcd");
        $dumpvars(0, adjustment_tb);
    end

endmodule
