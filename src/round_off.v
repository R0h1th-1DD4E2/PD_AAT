module round_off(
    input  wire [63:0] shifted_mantissa,
    input  wire signed [7:0] k_out,      // must be wider & signed
    output reg  [31:0] mantissa_out
);

    reg bt;

    //  initialization
    initial begin
        mantissa_out = 32'b0;
    end

    // compute  of number of bits
    always @(*) begin
        if (k_out >= 0)
            bt = 32 - 1 - (k_out + 2) - 3;
        else
            bt = 32 - 1 - ((-k_out) + 2) - 3;
    end

    // extract 'bt' number of  bits into MSB side of mantissa_out
    always @(*) begin
        mantissa_out = 32'b0;

        if (bt > 0 && bt <= 32) begin
            mantissa_out[31 : (32 - bt)] = shifted_mantissa[63 : (64 - bt)];
        end
    end

endmodule
