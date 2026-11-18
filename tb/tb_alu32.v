`timescale 1ns/1ps
`default_nettype none

module tb_alu32;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  opcode;

    wire [31:0] result;
    wire zero;
    wire negative;
    wire carry;
    wire overflow;

    reg [31:0] corners [0:9];
    reg [31:0] random_a;
    reg [31:0] random_b;

    integer i;
    integer j;
    integer op;
    integer seed;
    integer tests;

    alu32 dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .zero(zero),
        .negative(negative),
        .carry(carry),
        .overflow(overflow)
    );

    task automatic check(
        input reg [31:0] x,
        input reg [31:0] y,
        input reg [3:0]  operation
    );
        reg [31:0] expected_result;
        reg expected_carry;
        reg expected_overflow;
        reg expected_zero;
        reg expected_negative;

        reg [63:0] unsigned_math;
        reg signed [63:0] signed_x;
        reg signed [63:0] signed_y;
        reg signed [63:0] signed_math;

        begin
            a      = x;
            b      = y;
            opcode = operation;
            #1;

            expected_result   = 32'b0;
            expected_carry    = 1'b0;
            expected_overflow = 1'b0;

            unsigned_math = 64'b0;

            // Assignment sign-extends each operand to 64 bits.
            signed_x    = $signed(x);
            signed_y    = $signed(y);
            signed_math = 64'sd0;

            case (operation)
                4'h0: begin
                    unsigned_math = {32'b0, x} + {32'b0, y};
                    signed_math   = signed_x + signed_y;

                    expected_result = unsigned_math[31:0];
                    expected_carry  = unsigned_math[32];
                    expected_overflow =
                        (signed_math > 64'sd2147483647) ||
                        (signed_math < -64'sd2147483648);
                end

                4'h1: begin
                    signed_math = signed_x - signed_y;

                    expected_result = signed_math[31:0];
                    expected_carry  = (x >= y);
                    expected_overflow =
                        (signed_math > 64'sd2147483647) ||
                        (signed_math < -64'sd2147483648);
                end

                4'h2: expected_result = x & y;
                4'h3: expected_result = x | y;
                4'h4: expected_result = x ^ y;
                4'h5: expected_result = ~x;

                4'h6: expected_result = x << y[4:0];
                4'h7: expected_result = x >> y[4:0];
                4'h8: expected_result = signed_x >>> y[4:0];

                4'h9: expected_result = (signed_x < signed_y)
                                           ? 32'd1 : 32'd0;
                4'hA: expected_result = (x < y) ? 32'd1 : 32'd0;
                4'hB: expected_result = (x == y) ? 32'd1 : 32'd0;
                4'hC: expected_result = (x != y) ? 32'd1 : 32'd0;

                4'hD: expected_result = x;
                4'hE: expected_result = y;
                4'hF: expected_result = 32'b0;
            endcase

            expected_zero     = (expected_result == 32'b0);
            expected_negative = expected_result[31];

            if ({result, zero, negative, carry, overflow} !==
                {expected_result, expected_zero, expected_negative,
                 expected_carry, expected_overflow}) begin

                $display("FAIL: test=%0d opcode=%h a=%h b=%h",
                         tests + 1, operation, x, y);

                $display(
                    "Expected: result=%h Z=%b N=%b C=%b V=%b",
                    expected_result, expected_zero, expected_negative,
                    expected_carry, expected_overflow
                );

                $display(
                    "Actual:   result=%h Z=%b N=%b C=%b V=%b",
                    result, zero, negative, carry, overflow
                );

                $fatal(1, "ALU verification failed");
            end

            tests = tests + 1;
        end
    endtask

    initial begin
        a      = 32'b0;
        b      = 32'b0;
        opcode = 4'b0;
        tests  = 0;
        seed   = 32'h12345678;

        if ($test$plusargs("vcd")) begin
            $dumpfile("build/alu32.vcd");
            $dumpvars(0, tb_alu32);
        end

        corners[0] = 32'h00000000;
        corners[1] = 32'h00000001;
        corners[2] = 32'hFFFFFFFF;
        corners[3] = 32'h7FFFFFFF;
        corners[4] = 32'h80000000;
        corners[5] = 32'hAAAAAAAA;
        corners[6] = 32'h55555555;
        corners[7] = 32'h0000001F;
        corners[8] = 32'h00000020;
        corners[9] = 32'h80000001;

        // 10 x 10 operand combinations x 16 operations.
        for (i = 0; i < 10; i = i + 1)
            for (j = 0; j < 10; j = j + 1)
                for (op = 0; op < 16; op = op + 1)
                    check(corners[i], corners[j], op[3:0]);

        // 2,000 pseudorandom operand pairs x 16 operations.
        for (i = 0; i < 2000; i = i + 1) begin
            random_a = $random(seed);
            random_b = $random(seed);

            for (op = 0; op < 16; op = op + 1)
                check(random_a, random_b, op[3:0]);
        end

        $display("PASS: %0d ALU tests completed successfully.", tests);
        $finish;
    end

endmodule

`default_nettype wire
