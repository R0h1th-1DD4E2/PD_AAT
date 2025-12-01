module posit_decoder_tb;

    // Inputs
    reg [31:0] posit_num;
    reg start, clk, rst, received;
    
    // Outputs
    wire sign, done, ZERO, NAR;
    wire [5:0] k;
    wire [2:0] exp_value;
    wire [31:0] mantissa;

    // Instantiate DUT
    posit_decoder dut1 (
        .posit_num  (posit_num),
        .start      (start),
        .clk        (clk),
        .rst        (rst),
        .received   (received),
        .sign       (sign),
        .done       (done),
        .ZERO       (ZERO),
        .NAR        (NAR),
        .k          (k),
        .exp_value  (exp_value),
        .mantissa   (mantissa)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Monitor done signal
    always @(*) begin
        if (done) start = 0;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        received = 0;
        rst = 0;
        
        // Apply reset
        #100;
        rst = 1;
        posit_num = 32'h80000000;
        start = 1;
        
        #100;
        received = 1;
        
        // Run simulation
        #1000;
        $finish;
    end

    // Waveform and monitoring
    initial begin
        $dumpfile("posit_decoder.vcd");
        $dumpvars(0, posit_decoder_tb);
        $monitor("Time=%0t, posit_num=%h, sign=%b, done=%b, ZERO=%b, NAR=%b, k=%d, exp_value=%d, mantissa=%h", 
                 $time, posit_num, sign, done, ZERO, NAR, k, exp_value, mantissa);
    end

endmodule
