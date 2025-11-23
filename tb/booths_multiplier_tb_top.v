`timescale 1ns/1ps

module booths_multiplier_tb_top;
    
    // Signals
    reg clk;
    reg rst_n;
    reg load;
    reg [7:0] A;
    reg [7:0] B;
    wire [15:0] C;
    wire done;
    
    // Instantiate DUT
    booths_multiplier #(.N(8)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .A(A),
        .B(B),
        .C(C),
        .done(done)
    );
    
    // VCD Dump
    initial begin
        $dumpfile("booths_multiplier.vcd");
        $dumpvars(0, booths_multiplier_tb_top);
    end
    
endmodule
