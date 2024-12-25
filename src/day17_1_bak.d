module day17_1_bak;

import std.range.primitives;


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

enum ValueType {
    Sym,
    Lit
}

struct SymLit {
    ValueType valueType;
    int value;
    static int nextSym = 0;

    static auto next() {
        return SymLit(ValueType.Sym, nextSym++);
    }

    static auto lit(int value) {
        return SymLit(ValueType.Lit, value);
    }
}

enum Oper {
    Neq,
    Xor,
    Mod8,
    RShift,
    Eq,
    Noop,
}

struct Constr {
    SymLit res;
    Oper op;
    SymLit[] operands;

    static auto invalid() {
        return Constr(SymLit(ValueType.Sym, -1), Oper.Noop, []);
    }
}

auto combo(Op, Registers)(Op op, Registers registers) {
    switch(op) {
        case 0: .. case 3:
            return SymLit.lit(op);
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
    import std.typecons: tuple;
    return tuple(Oper.RShift, [register[Reg.A], operand.combo(register)]);
}

// The adv instruction (opcode 0) performs division. The numerator is the value in the A register. The denominator is found by raising 2 to the power of the instruction's combo operand. (So, an operand of 2 would divide A by 4 (2^2); an operand of 5 would divide A by 2^B.) The result of the division operation is truncated to an integer and then written to the A register.
auto adv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, operand.dvImpl(register).expand);
    register[Reg.A] = constr.res;
    return tuple(pc + 2, constr);
}

// The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand, then stores the result in register B.
auto bxl(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;
    assert(operand == 7);
    auto constr = Constr(SymLit.next, Oper.Xor, [register[Reg.B], SymLit.lit(operand)]);
    register[Reg.B] = constr.res;
    return tuple(pc + 2, constr);
}

// The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its lowest 3 bits), then writes that value to the B register.
auto bst(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, Oper.Mod8, [operand.combo(register)]);
    register[Reg.B] = constr.res;
    return tuple(pc + 2, constr);
}

// The jnz instruction (opcode 3) does nothing if the A register is 0. However, if the A register is not zero, it jumps by setting the instruction pointer to the value of its literal operand; if this instruction jumps, the instruction pointer is not increased by 2 after this instruction.
auto jnz(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.range: empty;
    import std.typecons: tuple;
    // if no output to consume, we can terminate (i.e pc + 2), and constrain A to be 0
    //else we want to jump
    auto oper = output.empty ? Oper.Eq : Oper.Neq;
    auto loc = output.empty ? pc + 2 : operand;
    auto constr = Constr(register[Reg.A], oper, [SymLit.lit(0)]);
    return tuple(loc, constr);
}

// The bxc instruction (opcode 4) calculates the bitwise XOR of register B and register C, then stores the result in register B. (For legacy reasons, this instruction reads an operand but ignores it.)
auto bxc(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, Oper.Xor, [register[Reg.B], register[Reg.C]]);
    register[Reg.B] = constr.res;
    return tuple(pc + 2, constr);
}

// The out instruction (opcode 5) calculates the value of its combo operand modulo 8, then outputs that value. (If a program outputs multiple values, they are separated by commas.)
auto outI(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.range: front;
    import std.typecons: tuple;

    auto constr = Constr(SymLit.lit(output.front), Oper.Mod8, [operand.combo(register)]);
    output = output[1..$];
    return tuple(pc + 2, constr);
}

// The bdv instruction (opcode 6) works exactly like the adv instruction except that the result is stored in the B register. (The numerator is still read from the A register.)
auto bdv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, operand.dvImpl(register).expand);
    register[Reg.B] = constr.res;
    return tuple(pc + 2, constr);
}

// The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the C register. (The numerator is still read from the A register.)
auto cdv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, operand.dvImpl(register).expand);
    register[Reg.C] = constr.res;
    return tuple(pc + 2, constr);
}


auto getValue(Store)(Store store, SymLit symLit) {
    final switch(symLit.valueType) {
        case ValueType.Lit:
            return symLit.value;
        case ValueType.Sym:
            return store[symLit.value];
    }
}

auto unsetVal(Store)(Store store, SymLit symLit) {
    return symLit.valueType == ValueType.Sym && store[symLit.value] == -1;
}

enum RAW_RANGE = 100000;
enum SHIFT_RANGE = 32;
static i = 0;
auto solveConstraints(Constraints)(ref int[] store, Constraints constraints) {
    i += 1;
    if (i == 1000){
        import std; "called".writeln(constraints.length, constraints.front);
    }
    import std.algorithm: all, count;
    import std.stdio: writeln;
    import std.range: chain, dropOne, front, only;

    if (constraints.empty) {
        store[0].writeln;
        return;
    }
    auto constr = constraints.front;
    auto allArgs = only(constr.res).chain(constr.operands);
    auto unset = allArgs.count!(a => store.unsetVal(a));
    auto check = unset == 0;

    auto nullConstr = allArgs.all!(a => a.valueType == ValueType.Lit);
    constraints = constraints[1..$];
    import std;
    assert (unset <= 1 || constr.op == Oper.RShift || constr.op == Oper.Xor,
            [constraints.length.to!string, constr.to!string].join(" "));
    if (nullConstr) {
        return solveConstraints(store, constraints);
    }
    final switch(constr.op) {
        case Oper.Eq:
            auto lhs = constr.res;
            auto rhs = constr.operands[0];
            if (check) {
                auto valid = store.getValue(lhs) == store.getValue(rhs);
                if (valid) {
                    return solveConstraints(store, constraints);
                }
                return;
            }
            assert (lhs.valueType == ValueType.Sym);
            store[lhs.value] = store.getValue(rhs);
            solveConstraints(store, constraints);
            store[lhs.value] = -1;
            return;
        case Oper.Neq:
            auto lhs = constr.res;
            auto rhs = constr.operands[0];
            if (check) {
                auto valid = store.getValue(lhs) != store.getValue(rhs);
                if (valid) {
                    return solveConstraints(store, constraints);
                }
                return;
            }
            assert(false);
            assert (lhs.valueType == ValueType.Sym);
            auto neqVal = store.getValue(rhs);
            foreach (val; 0..RAW_RANGE) {
                if (val == neqVal) {
                    continue;
                }
                store[lhs.value] = val;
                solveConstraints(store, constraints);
                store[lhs.value] = -1;
            }
            return;
        case Oper.Mod8:
            auto lhs = constr.res;
            auto rhs = constr.operands[0];
            if (check) {
                auto valid = store.getValue(lhs) == store.getValue(rhs) % 8;
                if (valid) {
                    return solveConstraints(store, constraints);
                }
                return;
            }
            if (store.unsetVal(lhs)) {
                store[lhs.value] = store.getValue(rhs) % 8;
                solveConstraints(store, constraints);
                store[lhs.value] = -1;
                return; 
            }
            else {
                solveConstraints(store, constraints);
                return;
                import std;
                assert(false, [constraints.length.to!string, constr.to!string].join(" "));
                auto targetVal = store.getValue(lhs);
                if (targetVal >= 8) {
                    return;
                }
                foreach(val; 0..RAW_RANGE) {
                    store[rhs.value] = targetVal + val * 8;
                    solveConstraints(store, constraints);
                    store[rhs.value] = -1;
                }
            }
            return;
        case Oper.RShift:
            auto lhs = constr.res;
            auto rhs0 = constr.operands[0];
            auto rhs1 = constr.operands[1];
            if (check) {
                auto valid = store.getValue(lhs) == store.getValue(rhs0) >> store.getValue(rhs1);
                if (valid) {
                    return solveConstraints(store, constraints);
                }
                return;
            }
            if (store.unsetVal(lhs)) {
                assert(!store.unsetVal(rhs0));
                if (store.unsetVal(rhs1)) {
                    foreach(val; 0..SHIFT_RANGE) {
                        store[rhs1.value] = val;
                        store[lhs.value] = store.getValue(rhs0) >> store.getValue(rhs1);
                        solveConstraints(store, constraints);
                        store[lhs.value] = -1;
                        store[rhs1.value] = -1;
                    }
                }
                else {
                    store[lhs.value] = store.getValue(rhs0) >> store.getValue(rhs1);
                    solveConstraints(store, constraints);
                    store[lhs.value] = -1;
                }
                return; 
            }
            else if (store.unsetVal(rhs0)){
                assert(!store.unsetVal(lhs));
                assert(!store.unsetVal(rhs1));
                auto targetVal = store.getValue(lhs);
                foreach(val; 0..(1 << store.getValue(rhs1))) {
                    store[rhs0.value] = (store.getValue(lhs) << store.getValue(rhs1)) + val;
                    solveConstraints(store, constraints);
                    store[rhs0.value] = -1;
                }
            }
            else { // if (store.unsetVal(rhs1))
                assert(!store.unsetVal(lhs));
                assert(!store.unsetVal(rhs0));
                auto targetVal = store.getValue(lhs);
                if (targetVal >= 8) {
                    return;
                }
                foreach(val; 0..SHIFT_RANGE) {
                    auto probe = store.getValue(lhs)  == store.getValue(rhs1) >> val;
                    if (probe) {
                        store[rhs1.value] = val;
                        solveConstraints(store, constraints);
                        store[rhs1.value] = -1;
                    }
                }
            }
            return;
        case Oper.Xor:
            auto lhs = constr.res;
            auto rhs0 = constr.operands[0];
            auto rhs1 = constr.operands[1];
            if (check) {
                auto valid = store.getValue(lhs) == (store.getValue(rhs0) ^ store.getValue(rhs1));
                if (valid) {
                    return solveConstraints(store, constraints);
                }
                return;
            }
            if (store.unsetVal(lhs) && store.unsetVal(rhs0)) {
                assert(false);
                assert(rhs1.valueType == ValueType.Lit);
                assert(rhs1.value == 7);
                foreach(val; 0..8) {
                    store[rhs0.value] = val;
                    store[lhs.value] = store.getValue(rhs0) ^ store.getValue(rhs1);
                    solveConstraints(store, constraints);
                    store[lhs.value] = -1;
                    store[rhs0.value] = -1;
                }
                return;
            }
            else if (store.unsetVal(lhs)) {
                store[lhs.value] = store.getValue(rhs0) ^ store.getValue(rhs1);
                solveConstraints(store, constraints);
                store[lhs.value] = -1;
                return;
            }
            else if (store.unsetVal(rhs0)){
                store[rhs0.value] = store.getValue(lhs) ^ store.getValue(rhs1);
                solveConstraints(store, constraints);
                store[rhs0.value] = -1;
                return;
            }
            else if (store.unsetVal(rhs1)) {
                store[rhs1.value] = store.getValue(lhs) ^ store.getValue(rhs0);
                solveConstraints(store, constraints);
                store[rhs1.value] = -1;
                return;
            }
            else {
                assert(false);
            }
            return;
        case Oper.Noop:
            assert (false);
    }
}

auto solve(Instructions)(Instructions instrs)
{
    import std.array: array;
    import std.algorithm: cumulativeFold, fill, joiner, map, until;
    import std.conv: to;
    import std.range: dropOne, iota, recurrence, retro;
    import std.typecons: No, tuple;

    SymLit[3] registerBuf = [SymLit.next, SymLit.lit(0), SymLit.lit(0)];
    auto register = registerBuf[];
    assert(register[Reg.A].value == 0);
    
    alias Register = typeof(register);
    int[] output = instrs.dup;
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
    auto constraints = tuple(0, Constr.invalid).recurrence!((state, n) {
        auto pc = state[n][0];
        pc %= instrs.length; // to prevent access
        auto op = Ops[instrs[pc]];
        auto operand = instrs[pc + 1];
        return op(operand, pc, register, output);
    })
    .until!(a => a[0] >= instrs.length)(No.openRight)
    .map!(a => a[1])
    .dropOne
    .array
    ;
    int cRunIdx = 0;
    int[] runIdx = new int[constraints.length];
    foreach(i, constr; constraints) {
        runIdx[i] = (cRunIdx);
        cRunIdx += constr.op == Oper.Neq;
    }
    import std.range: zip;
    import std.algorithm: sort, SwapStrategy;
    import std; constraints.writeln;
    constraints.zip(runIdx).sort!((a, b) {
        // return a[0].op < b[0].op;
        return tuple(a[1], a[0].op) < tuple(b[1], b[0].op);
    }, SwapStrategy.stable);
    auto realValues = new int[SymLit.nextSym];
    realValues.fill(-1);
    solveConstraints(realValues, constraints.retro);
    return constraints;
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
    auto ret = solve(instruction);
    writeln(ret);
    return 0;
}

