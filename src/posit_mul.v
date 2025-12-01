``timescale 1ns / 1ps

module posit_mul (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] posit_a,
    input  wire [31:0] posit_b,
    output reg  [31:0] posit_result,
    output reg         done
);


    // Decoder instantiation 
    // Instantiate decoder for posit_a
    posit_decoder decoder_a (
        .posit_num( /* connect posit_a */ ),
        .start(     /* connect start */ ),
        .clk(       /* connect clk */ ),
        .rst(       /* connect rst */ ),
        .received(  /* connect received */ ),
        .sign(      /* connect sign_a */ ),
        .done(      /* connect done_a */ ),
        .ZERO(      /* connect ZERO_a */ ),
        .NAR(       /* connect NAR_a */ ),
        .k(         /* connect k_a */ ),
        .exp_value( /* connect exp_a */ ),
        .mantissa(  /* connect mantissa_a */ )
    );

    // Instantiate decoder for posit_b
    posit_decoder decoder_b (
        .posit_num( /* connect posit_b */ ),
        .start(     /* connect start */ ),
        .clk(       /* connect clk */ ),
        .rst(       /* connect rst */ ),
        .received(  /* connect received */ ),
        .sign(      /* connect sign_b */ ),
        .done(      /* connect done_b */ ),
        .ZERO(      /* connect ZERO_b */ ),
        .NAR(       /* connect NAR_b */ ),
        .k(         /* connect k_b */ ),
        .exp_value( /* connect exp_b */ ),
        .mantissa(  /* connect mantissa_b */ )
    );

    // Booth's multiplier (parameter N = 32)
    booths_multiplier #(.N(32)) booths_inst (
        .clk(    /* connect clk */ ),
        .rst_n(  /* connect rst_n */ ),
        .load(   /* connect load */ ),
        .A(      /* connect multiplicand A */ ),
        .B(      /* connect multiplier B */ ),
        .done(   /* connect done_mul */ ),
        .C(      /* connect product C (2*N-1:0) */ )
    );

    // Exponent adder
    exp_adder #(
        .ES(3),
        .K_BITS(6)
    ) exp_adder_inst (
        .clk(      /* connect clk */ ),
        .rst_n(    /* connect rst_n */ ),
        .start(    /* connect start */ ),
        .exp_A(    /* connect exp from decoder A */ ),
        .exp_B(    /* connect exp from decoder B */ ),
        .k_A(      /* connect k from decoder A */ ),
        .k_B(      /* connect k from decoder B */ ),
        .sign_A(   /* connect sign from decoder A */ ),
        .sign_B(   /* connect sign from decoder B */ ),
        .exp_raw(  /* connect exp_raw output */ ),
        .sign_out( /* connect sign_out */ ),
        .NaR(      /* connect NaR flag */ ),
        .zero_out( /* connect zero_out flag */ ),
        .done(     /* connect done_exp */ )
    );

    // Adjustment module
    adjustment adjustment_inst (
        .clk(        /* connect clk */ ),
        .rst_n(      /* connect rst_n */ ),
        .start(      /* connect start */ ),
        .scale_in(   /* connect initial scale (e.g., from exp_adder) */ ),
        .mant_prod(  /* connect mantissa product (e.g., from multiplier) */ ),
        .scale_out(  /* connect adjusted scale_out */ ),
        .mant_adj(   /* connect adjusted mantissa */ ),
        .shift_amt(  /* connect shift amount */ ),
        .done(       /* connect done_adj */ ),
        .adj_exp(    /* connect adj_exp */ ),
        .adj_regime( /* connect adj_regime */ ),
        .exp_sign(   /* connect exp_sign */ )
    );

    // Round-off: produce final mantissa bits
    round_off round_off_inst (
        .clk(             /* connect clk */ ),
        .rst_n(           /* connect rst_n */ ),
        .start(           /* connect start */ ),
        .shifted_mantissa(/* connect shifted mantissa [63:0] */ ),
        .k_out(           /* connect k_out [5:0] */ ),
        .mantissa_out(    /* connect final mantissa_out [31:0] */ ),
        .done(            /* connect done_round */ )
    );

    // Posit encoder: pack sign,k,exp,mantissa back to posit
    posit_encoder posit_encoder_inst (
        .start(        /* connect start */ ),
        .clk(          /* connect clk */ ),
        .rst(          /* connect rst */ ),
        .received(     /* connect received */ ),
        .sign_out(     /* connect sign */ ),
        .k_out(        /* connect k_out signed [5:0] */ ),
        .exp_out(      /* connect exp_out [2:0] */ ),
        .mantissa_out( /* connect mantissa_out [31:0] */ ),
        .p_hold(       /* connect output packed posit [31:0] */ ),
        .done(         /* connect done_enc */ )
    );

    controller ctrl_inst (
        .clk(            /* connect clk */ ),
        .rst_n(          /* connect rst_n */ ),
        // Special-case detections from decoders and exponent adder
        .ZERO_A_DE(      /* connect ZERO from decoder A */ ),
        .NAR_A_DE(       /* connect NAR from decoder A */ ),
        .ZERO_B_DE(      /* connect ZERO from decoder B */ ),
        .NAR_B_DE(       /* connect NAR from decoder B */ ),
        .NAR_EXP_ADDER(  /* connect NaR from exp_adder */ ),
        .ZERO_EXP_ADDER( /* connect zero_out from exp_adder */ ),
        // Encoder handshake
        .encoder_start(  /* drive posit_encoder.start */ ),
        .encode_done(    /* connect posit_encoder.done */ ),
        // Stage resets
        .adjust_rst_n(   /* connect to adjustment.rst_n */ ),
        .round_rst_n(    /* connect to round_off.rst_n */ )
    );

endmodule