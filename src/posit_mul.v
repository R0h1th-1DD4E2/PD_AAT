`timescale 1ns / 1ps

module posit_mul (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] posit_a,
    input  wire [31:0] posit_b,
    output reg  [31:0] posit_result,
    output reg         done
);
    wire sign_a, sign_b;
    wire done_decode_a, done_decode_b;
    wire ZERO_decode_a, NAR_decode_a;
    wire ZERO_decode_b, NAR_decode_b;
    wire [5:0] k_decode_a, k_decode_b;
    wire [2:0] exp_decode_a, exp_decode_b;
    wire [31:0] mantissa_decode_a, mantissa_decode_b;
    // Booth's multiplier outputs
    wire [63:0] mantissa_product;
    wire done_mul;
    // Exponent adder outputs
    wire [9:0] exp_raw;
    wire sign_out_exp;
    wire NaR_exp;
    wire zero_out_exp;
    wire done_exp;
    // Adjustment module outputs
    wire [63:0] mant_adj;
    wire done_adj;
    wire [2:0] adj_exp;
    wire [5:0] adj_k;
    wire sign_out_adj;
    // Round-off outputs
    wire [31:0] mantissa_rounded;
    wire done_round;
    wire [5:0] k_final;
    wire        sign_final;
    wire [2:0]  exp_final;
    // Controller outputs
    wire encoder_start;
    wire adjust_rst_n;
    wire round_rst_n;

    // Decoder instantiation 
    // Instantiate decoder for posit_a
    posit_decoder decoder_a (
        .posit_num(posit_a),
        .start(start),
        .clk(clk),
        .rst(rst_n),
        .sign(sign_a),
        .done(done_decode_a),
        .ZERO(ZERO_decode_a),
        .NAR(NAR_decode_a),
        .k(k_decode_a),
        .exp_value(exp_decode_a),
        .mantissa(mantissa_decode_a)
    );

    // Instantiate decoder for posit_b
    posit_decoder decoder_b (
        .posit_num(posit_b),
        .start(start),
        .clk(clk),
        .rst(rst_n),
        .sign(sign_b),
        .done(done_decode_b),
        .ZERO(ZERO_decode_b),
        .NAR(NAR_decode_b),
        .k(k_decode_b),
        .exp_value(exp_decode_b),
        .mantissa(mantissa_decode_b)
    );

    // Booth's multiplier (parameter N = 32)
    booths_multiplier #(.N(32)) booths_inst (
        .clk(clk),
        .rst_n(rst_n),
        .load(done_decode_a & done_decode_b),
        .A(mantissa_decode_a),
        .B(mantissa_decode_b),
        .done(done_mul),
        .C(mantissa_product)
    );

    // Exponent adder
    exp_adder #(
        .ES(3),
        .K_BITS(6)
    ) exp_adder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .exp_A(exp_decode_a),
        .exp_B(exp_decode_b),
        .k_A(k_decode_a),
        .k_B(k_decode_b),
        .sign_A(sign_a),
        .sign_B(sign_b),
        .exp_raw(exp_raw),
        .sign_out(sign_out_exp),
        .NaR(NaR_exp),
        .zero_out(zero_out_exp),
        .done(done_exp)
    );

    // Adjustment module
    adjustment adjustment_inst (
        .clk(clk),
        .rst_n(rst_n || adjust_rst_n),
        .start(done_mul),
        .E_raw(exp_raw),
        .mant_prod(mantissa_product),
        .sign_in(sign_out_exp),
        .mant_adj(mant_adj),
        .done(done_adj),
        .adj_exp(adj_exp),
        .adj_k(adj_k),
        .sign_out(sign_out_adj)
    );

    // Round-off: produce final mantissa bits
    round_off round_off_inst (
        .clk(clk),
        .rst_n(rst_n || round_rst_n),
        .start(done_adj),
        .shifted_mantissa(mant_adj),
        .k_out(adj_k),
        .sign_out(sign_out_adj),
        .exp_out(adj_exp),
        .mantissa_out(mantissa_rounded),
        .k_final(k_final),
        .sign_final(sign_final),
        .exp_final(exp_final),
        .done(done_round)
    );

    // Posit encoder: pack sign,k,exp,mantissa back to posit
    posit_encoder posit_encoder_inst (
        .start(done_round || encoder_start),
        .clk(clk),
        .rst(rst_n),
        .sign_out(sign_final),
        .k_out(k_final),
        .exp_out(exp_final),
        .mantissa_out(mantissa_rounded),
        .p_hold(posit_result),
        .done(done)
    );

    controller ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        // Special-case detections from decoders and exponent adder
        .ZERO_A_DE(ZERO_decode_a),
        .NAR_A_DE(NAR_decode_a),
        .ZERO_B_DE(ZERO_decode_b),
        .NAR_B_DE(NAR_decode_b),
        .NAR_EXP_ADDER(NaR_exp),
        .ZERO_EXP_ADDER(zero_out_exp),
        // Encoder handshake
        .encoder_start(encoder_start),
        .encode_done(done),
        // Stage resets
        .adjust_rst_n(adjust_rst_n),
        .round_rst_n(round_rst_n)
    );

endmodule
