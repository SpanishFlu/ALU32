`timescale 1ns/1ps
`default_nettype none

module alu32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  opcode,

    output reg  [31:0] result,
    output wire        zero,
    output wire        negative,
    output reg         carry,
    output reg         overflow
);

    localparam [3:0]
        OP_ADD    = 4'h0,
        OP_SUB    = 4'h1,
        OP_AND    = 4'h2,
        OP_OR     = 4'h3,
        OP_XOR    = 4'h4,
        OP_NOT    = 4'h5,
        OP_SLL    = 4'h6,
        OP_SRL    = 4'h7,
        OP_SRA    = 4'h8,
        OP_SLT    = 4'h9,
        OP_SLTU   = 4'hA,
        OP_EQ     = 4'hB,
        OP_NE     = 4'hC,
        OP_PASS_A = 4'hD,
        OP_PASS_B = 4'hE,
        OP_ZERO   = 4'hF;

    reg [32:0] arithmetic_result;

    assign zero     = (result == 32'b0);
    assign negative = result[31];

    always @* begin
        result            = 32'b0;
        carry             = 1'b0;
        overflow          = 1'b0;
        arithmetic_result = 33'b0;

        case (opcode)
            OP_ADD: begin
                arithmetic_result = {1'b0, a} + {1'b0, b};
                result = arithmetic_result[31:0];
                carry  = arithmetic_result[32];

                overflow = (~(a[31] ^ b[31])) &
                           (result[31] ^ a[31]);
            end

            OP_SUB: begin
                // A + two's complement of B.
                // Carry = 1 means no unsigned borrow.
                arithmetic_result =
                    {1'b0, a} + {1'b0, ~b} + 33'd1;

                result = arithmetic_result[31:0];
                carry  = arithmetic_result[32];

                overflow = (a[31] ^ b[31]) &
                           (result[31] ^ a[31]);
            end

            OP_AND:    result = a & b;
            OP_OR:     result = a | b;
            OP_XOR:    result = a ^ b;
            OP_NOT:    result = ~a;

            OP_SLL:    result = a << b[4:0];
            OP_SRL:    result = a >> b[4:0];
            OP_SRA:    result = $signed(a) >>> b[4:0];

            OP_SLT:    result = {31'b0, ($signed(a) < $signed(b))};
            OP_SLTU:   result = {31'b0, (a < b)};
            OP_EQ:     result = {31'b0, (a == b)};
            OP_NE:     result = {31'b0, (a != b)};

            OP_PASS_A: result = a;
            OP_PASS_B: result = b;
            OP_ZERO:   result = 32'b0;

            default:   result = 32'b0;
        endcase
    end

endmodule

`default_nettype wire
