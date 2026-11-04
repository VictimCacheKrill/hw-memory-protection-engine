module sbox4 (
    input  [3:0] in,
    output reg [3:0] out
);
    always @(*) begin
        case (in)
            4'h0: out = 4'hC;
            4'h1: out = 4'h5;
            4'h2: out = 4'h6;
            4'h3: out = 4'hB;
            4'h4: out = 4'h9;
            4'h5: out = 4'h0;
            4'h6: out = 4'hA;
            4'h7: out = 4'hD;
            4'h8: out = 4'h3;
            4'h9: out = 4'hE;
            4'hA: out = 4'hF;
            4'hB: out = 4'h8;
            4'hC: out = 4'h4;
            4'hD: out = 4'h7;
            4'hE: out = 4'h1;
            4'hF: out = 4'h2;
            default: out = 4'h0;
        endcase
    end
endmodule

module cache_line_enc_round (
    input  [511:0] data_in,
    input  [63:0]  round_key,
    input  [63:0]  address_tweak,
    output [511:0] data_out
);
    wire [511:0] xored_state;
    wire [511:0] sbox_state;
    reg  [511:0] permuted_state;

    assign xored_state = data_in ^ {8{round_key ^ address_tweak}};

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin: enc_sbox_gen
            sbox4 sb (
                .in(xored_state[(i*4)+3 : i*4]),
                .out(sbox_state[(i*4)+3 : i*4])
            );
        end
    endgenerate

    integer j;
    always @(*) begin
        for (j = 0; j < 512; j = j + 1) begin
            permuted_state[j] = sbox_state[(j * 37) % 511];
        end
        permuted_state[511] = sbox_state[511];
    end

    assign data_out = permuted_state;
endmodule

module cache_line_encryption_engine (
    input  [511:0] cache_line_plaintext,
    input  [63:0]  physical_address,
    input  [63:0]  master_key,
    output [511:0] cache_line_ciphertext
);
    wire [511:0] r1, r2;

    cache_line_enc_round round1 (.data_in(cache_line_plaintext), .round_key(master_key), .address_tweak(physical_address), .data_out(r1));
    cache_line_enc_round round2 (.data_in(r1), .round_key(master_key), .address_tweak(physical_address), .data_out(r2));
    cache_line_enc_round round3 (.data_in(r2), .round_key(master_key), .address_tweak(physical_address), .data_out(cache_line_ciphertext));
endmodule
