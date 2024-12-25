module day17_1_naive_bad;


auto parseReg(InputLine)(InputLine inputLine)
{
    import std.format: formattedRead;

    int regValue;
    inputLine.formattedRead("Register %*c: %d", regValue);
    return regValue;
}

auto parseRegs(InputLines)(InputLines inputLines)
{
    import std.algorithm: map;
    import std.array: array;

    return inputLines.map!parseReg.array;
}

auto parseInstrs(InputLine)(InputLine inputLine)
{
    import std.algorithm: map, splitter;
    import std.array: array;
    import std.conv: to;
    import std.range: dropOne;

    return inputLine.splitter(": ").dropOne.front.splitter(",").map!(to!int).array;
}


auto combo(Op, Registers)(Op op, Registers registers) {
    switch(op) {
        case 0: .. case 3:
            return op;
        case 4: .. case 6:
            return registers[op - 4];
        default:
            assert(false);
    }
    assert(false);
}

enum Reg {
    A = 0,
    B,
    C
}

auto dvImpl(Register)(int operand, Register register) {
    auto res = register[Reg.A] / 2^^ (operand.combo(register));
    return res;
}

// The adv instruction (opcode 0) performs division. The numerator is the value in the A register. The denominator is found by raising 2 to the power of the instruction's combo operand. (So, an operand of 2 would divide A by 4 (2^2); an operand of 5 would divide A by 2^B.) The result of the division operation is truncated to an integer and then written to the A register.
auto adv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    register[Reg.A] = operand.dvImpl(register);
    return pc + 2;
}

// The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand, then stores the result in register B.
auto bxl(Register, Out)(int operand, int pc, Register register, ref Out output) {
    register[Reg.B] ^= operand;
    return pc + 2;
}

// The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its lowest 3 bits), then writes that value to the B register.
auto bst(Register, Out)(int operand, int pc, Register register, ref Out output) {
    register[Reg.B] = operand.combo(register) % 8;
    return pc + 2;
}

// The jnz instruction (opcode 3) does nothing if the A register is 0. However, if the A register is not zero, it jumps by setting the instruction pointer to the value of its literal operand; if this instruction jumps, the instruction pointer is not increased by 2 after this instruction.
auto jnz(Register, Out)(int operand, int pc, Register register, ref Out output) {
    return register[Reg.A] == 0 ? pc + 2 : operand;
}

// The bxc instruction (opcode 4) calculates the bitwise XOR of register B and register C, then stores the result in register B. (For legacy reasons, this instruction reads an operand but ignores it.)
auto bxc(Register, Out)(int operand, int pc, Register register, ref Out output) {
    register[Reg.B] ^= register[Reg.C];
    return pc + 2;
}

// The out instruction (opcode 5) calculates the value of its combo operand modulo 8, then outputs that value. (If a program outputs multiple values, they are separated by commas.)
auto outI(Register, Out)(int operand, int pc, Register register, ref Out output) {
    output ~= operand.combo(register) % 8;
    return pc + 2;
}

// The bdv instruction (opcode 6) works exactly like the adv instruction except that the result is stored in the B register. (The numerator is still read from the A register.)
auto bdv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    register[Reg.B] = operand.dvImpl(register);
    return pc + 2;
}

// The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the C register. (The numerator is still read from the A register.)
auto cdv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    register[Reg.C] = operand.dvImpl(register);
    return pc + 2;
}

auto solveOnce(Register, Instructions)(Register reg, Instructions instrs)
{
    import std.algorithm: copy, cumulativeFold, joiner, map, until, startsWith;
    import std.conv: to;
    import std.range: nullSink, recurrence;

    int[] output;
    alias Out = typeof(output);

    auto Ops = [
        &adv!(Register, Out),
        &bxl!(Register, Out),
        &bst!(Register, Out),
        &jnz!(Register, Out),
        &bxc!(Register, Out),
        &outI!(Register, Out),
        &bdv!(Register, Out),
        &cdv!(Register, Out),
    ];

    0.recurrence!((state, n) {
        auto pc = state[n];
        auto op = Ops[instrs[pc]];
        auto operand = instrs[pc + 1];
        return op(operand, pc, reg, output);
    })
    .until!(a=> a >= instrs.length || !instrs.startsWith(output))
    .copy(nullSink) // materialize
    ;

    return output;
}


auto solve(Register, Instructions)(Register reg, Instructions instrs)
{
    import std.algorithm: map, until;
    import std.range: sequence, walkLength;

    return sequence!((a, n) {
        return n;
    })
    .map!(a=> [a, 0, 0].solveOnce(instrs))
    .until!(a => a == instrs)
    .walkLength;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: splitter;
    import std.range: dropOne;
    import std.array: array, front;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto registers = inputLines.front.parseRegs;
    auto instruction = inputLines.dropOne.front.front.parseInstrs;
    registers.writeln(" ", instruction);
    auto ret = solve(registers, instruction);
    writeln(ret);
    return 0;
}

