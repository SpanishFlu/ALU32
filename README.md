# 32-bit ALU in Verilog

A combinational 32-bit Arithmetic Logic Unit with 16 operations,
status flags, automated verification, and GitHub Actions CI.

## Features

- Synthesizable Verilog-2005 RTL
- Two 32-bit operands and a 4-bit opcode
- Arithmetic, bitwise, shift, and comparison operations
- Zero, negative, carry, and signed-overflow flags
- Self-checking SystemVerilog testbench
- 1,600 corner-case tests and 32,000 pseudorandom tests
- Optional VCD waveform output
- MIT license

## Interface

| Port | Direction | Width | Description |
|---|---|---:|---|
| `a` | Input | 32 | First operand |
| `b` | Input | 32 | Second operand / shift amount |
| `opcode` | Input | 4 | Operation selector |
| `result` | Output | 32 | ALU result |
| `zero` | Output | 1 | Result equals zero |
| `negative` | Output | 1 | Result bit 31 |
| `carry` | Output | 1 | Addition carry / subtraction no-borrow |
| `overflow` | Output | 1 | Signed arithmetic overflow |

The design is combinational and has no clock or reset.

## Operations

| Opcode | Operation | Result |
|---|---|---|
| `0x0` | ADD | `a + b` |
| `0x1` | SUB | `a - b` |
| `0x2` | AND | `a & b` |
| `0x3` | OR | `a \| b` |
| `0x4` | XOR | `a ^ b` |
| `0x5` | NOT | `~a` |
| `0x6` | SLL | Logical left shift |
| `0x7` | SRL | Logical right shift |
| `0x8` | SRA | Arithmetic right shift |
| `0x9` | SLT | Signed less-than |
| `0xA` | SLTU | Unsigned less-than |
| `0xB` | EQ | Equality |
| `0xC` | NE | Inequality |
| `0xD` | PASS_A | `a` |
| `0xE` | PASS_B | `b` |
| `0xF` | ZERO | `0` |

### Semantics

- Arithmetic results wrap to 32 bits.
- Shift operations use only `b[4:0]`, giving shift amounts 0–31.
  For example, `b = 32` produces a shift amount of zero.
- Arithmetic right shift sign-extends operand `a`.
- Comparisons return 32-bit `1` or `0`.
- Addition carry is the unsigned carry-out.
- Subtraction carry is `1` when `a >= b` unsigned: no borrow.
- `overflow` reports signed overflow for ADD and SUB only.
- Carry and overflow are zero for all other operations.
- `negative` always reflects result bit 31, even for unsigned operations.
- X/Z input behavior is not part of the verified functional contract.

## Project layout

```text
rtl/alu32.v                         ALU implementation
tb/tb_alu32.sv                      Self-checking testbench
.github/workflows/simulation.yml   Continuous integration
Makefile                           Build and simulation commands
```

## Requirements

- Icarus Verilog (`iverilog` and `vvp`)
- GNU Make
- GTKWave, optional, for waveform viewing

### Install on Ubuntu / Debian

```bash
sudo apt-get update
sudo apt-get install -y iverilog make
```

## Run tests

From the repository root:

```bash
make test
```

A successful simulation prints:

```text
PASS: 33600 ALU tests completed successfully.
```

A mismatch prints the input operands, opcode, expected outputs,
and actual outputs, then exits with a failure.

## Compile-check the RTL

```bash
make lint
```

This is a Verilog compile/warning check, not a comprehensive lint
or synthesis analysis.

## Generate waveforms

```bash
make waves
```

Waveform output:

```text
build/alu32.vcd
```

If GTKWave is installed:

```bash
gtkwave build/alu32.vcd
```

## Run without Make

```bash
mkdir -p build
iverilog -g2012 -Wall -s tb_alu32 \
  -o build/alu32_sim rtl/alu32.v tb/tb_alu32.sv
vvp build/alu32_sim
```

## Integration example

```verilog
wire [31:0] alu_result;
wire alu_zero;
wire alu_negative;
wire alu_carry;
wire alu_overflow;

alu32 u_alu (
    .a(operand_a),
    .b(operand_b),
    .opcode(operation),
    .result(alu_result),
    .zero(alu_zero),
    .negative(alu_negative),
    .carry(alu_carry),
    .overflow(alu_overflow)
);
```

Declare and drive `operand_a`, `operand_b`, and `operation`
in the surrounding module.
