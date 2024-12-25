module day17_1_fail_again;

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
    long numBits;
    static int nextSym = 0;

    static auto next() {
        return SymLit(ValueType.Sym, nextSym++, 64);
    }

    static auto lit(int value) {
        import std.algorithm: fold;
        import std.bitmanip: bitsSet;
        auto numBits = bitsSet(value).fold!((a, b) => b + 1)(0UL);
        assert(0 <= numBits && numBits <= 3);
        return SymLit(ValueType.Lit, value, numBits);
    }
}

enum Oper {
    Eq,
    Xor,
    Mod8,
    RShift,
    Neq,
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
    auto oper0 = register[Reg.A];
    auto oper1 =  operand.combo(register);
    auto res = SymLit.next;
    res.numBits = oper0.numBits;
    if (oper1.valueType == ValueType.Lit) {
        res.numBits -= oper1.value;
        res.numBits  = res.numBits < 0 ? 0 : res.numBits;
    }
    auto ret = Constr(res, Oper.RShift, [register[Reg.A], operand.combo(register)]);
    return ret;
}


// The adv instruction (opcode 0) performs division. The numerator is the value in the A register. The denominator is found by raising 2 to the power of the instruction's combo operand. (So, an operand of 2 would divide A by 4 (2^2); an operand of 5 would divide A by 2^B.) The result of the division operation is truncated to an integer and then written to the A register.
auto adv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = operand.dvImpl(register);
    register[Reg.A] = constr.res;
    return tuple(pc + 2, constr);
}

// The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand, then stores the result in register B.
auto bxl(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.algorithm: max;
    import std.typecons: tuple;
    assert(operand == 7);
    auto constr = Constr(SymLit.next, Oper.Xor, [register[Reg.B], SymLit.lit(operand)]);
    constr.res.numBits = max(constr.operands[0].numBits, constr.operands[1].numBits);
    register[Reg.B] = constr.res;
    return tuple(pc + 2, constr);
}

// The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its lowest 3 bits), then writes that value to the B register.
auto bst(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.algorithm: min;
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, Oper.Mod8, [operand.combo(register)]);
    constr.res.numBits = min(constr.operands[0].numBits, 3);
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
    import std.algorithm: max;
    import std.typecons: tuple;

    auto constr = Constr(SymLit.next, Oper.Xor, [register[Reg.B], register[Reg.C]]);
    constr.res.numBits = max(constr.operands[0].numBits, constr.operands[1].numBits);
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

    auto constr = operand.dvImpl(register);
    register[Reg.B] = constr.res;
    return tuple(pc + 2, constr);
}

// The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the C register. (The numerator is still read from the A register.)
auto cdv(Register, Out)(int operand, int pc, Register register, ref Out output) {
    import std.typecons: tuple;

    auto constr = operand.dvImpl(register);
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

auto isUnset(Store)(Store store, SymLit symLit) {
    return symLit.valueType == ValueType.Sym && store[symLit.value] == -1;
}

static i = 0L;
auto solveConstraints(ref int[] store, Constr[] constraints, bool[] toCheck) {
    i += 1;
    if (i % 1_000_000_000 == 0){
        import std; "called ".writeln(constraints.length, ", ", constraints.front, ", ", toCheck.front);
    }
    import std.stdio: writeln;
    import std.range: dropOne, empty, front;

    if (constraints.empty) {
        store[0].writeln;
        store.writeln;
        return;
    }
    auto constr = constraints.front;
    auto check = toCheck.front;
    constraints = constraints.dropOne;
    toCheck = toCheck.dropOne;

    final switch(constr.op) {
        case Oper.Eq:
            auto lhs = constr.res;
            auto rhs = constr.operands[0];
            if (check) {
                auto valid = store.getValue(lhs) == store.getValue(rhs);
                if (valid) {
                    return solveConstraints(store, constraints, toCheck);
                }
                return;
            }
            assert (lhs.valueType == ValueType.Sym);
            store[lhs.value] = store.getValue(rhs);
            solveConstraints(store, constraints, toCheck);
            store[lhs.value] = -1;
            return;
        case Oper.Neq:
            auto lhs = constr.res;
            auto rhs = constr.operands[0];
            if (check) {
                auto valid = store.getValue(lhs) != store.getValue(rhs);
                if (valid) {
                    return solveConstraints(store, constraints, toCheck);
                }
                return;
            }
            // assert(false);
            assert (rhs.valueType == ValueType.Lit);
            assert (rhs.value == 0);
            auto neqVal = store.getValue(rhs);
            foreach (val; neqVal + 1..2^^cast(int)lhs.numBits) {
                store[lhs.value] = val;
                solveConstraints(store, constraints, toCheck);
                store[lhs.value] = -1;
            }
            return;
        case Oper.Mod8:
            auto lhs = constr.res;
            auto rhs = constr.operands[0];
            if (check) {
                auto valid = store.getValue(lhs) == store.getValue(rhs) % 8;
                if (valid) {
                    return solveConstraints(store, constraints, toCheck);
                }
                return;
            }
            if (store.isUnset(lhs)) {
                store[lhs.value] = store.getValue(rhs) % 8;
                solveConstraints(store, constraints, toCheck);
                store[lhs.value] = -1;
                return; 
            }
            else {
                // import std; assert(false, [constraints.length.to!string, constr.to!string].join(" "));
                auto targetVal = store.getValue(lhs);
                if (targetVal >= 8) {
                    return;
                }
                auto targetBits = rhs.numBits - 3;
                targetBits = targetBits < 0 ? 0 : targetBits;
                import std;
                assert(targetBits <= 32, targetBits.to!string);
                foreach(val; 0..2^^cast(int)targetBits) {
                    store[rhs.value] = targetVal + val * 8;
                    solveConstraints(store, constraints, toCheck);
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
                    return solveConstraints(store, constraints, toCheck);
                }
                return;
            }
            if (store.isUnset(rhs0)){
                assert(!store.isUnset(lhs));
                assert(!store.isUnset(rhs1));
                auto targetVal = store.getValue(lhs);
                auto rhs1Val = store.getValue(rhs1);
                auto shifted = targetVal << rhs1Val;
                foreach(val; 0..(1 << rhs1Val)) {
                    store[rhs0.value] = shifted + val;
                    solveConstraints(store, constraints, toCheck);
                    store[rhs0.value] = -1;
                }
            }
            else if (store.isUnset(lhs)) {
                store[lhs.value] = store.getValue(rhs0) >> store.getValue(rhs1);
                solveConstraints(store, constraints, toCheck);
                store[lhs.value] = -1;
                return; 
            }
            else { // if (store.isUnset(rhs1))
                assert(!store.isUnset(lhs));
                assert(!store.isUnset(rhs0));
                auto targetVal = store.getValue(lhs);
                if (targetVal >= 8) {
                    return;
                }
                foreach(val; 0..cast(int)2^^rhs1.numBits) {
                    auto probe = store.getValue(lhs)  == store.getValue(rhs0) >> val;
                    if (probe) {
                        store[rhs1.value] = val;
                        solveConstraints(store, constraints, toCheck);
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
                    return solveConstraints(store, constraints, toCheck);
                }
                return;
            }
            if (store.isUnset(lhs)) {
                assert(!store.isUnset(rhs0));
                assert(!store.isUnset(rhs1));
                store[lhs.value] = store.getValue(rhs0) ^ store.getValue(rhs1);
                solveConstraints(store, constraints, toCheck);
                store[lhs.value] = -1;
                return;
            }
            else if (store.isUnset(rhs0)){
                assert(!store.isUnset(lhs));
                assert(!store.isUnset(rhs1));
                store[rhs0.value] = store.getValue(lhs) ^ store.getValue(rhs1);
                solveConstraints(store, constraints, toCheck);
                store[rhs0.value] = -1;
                return;
            }
            else if (store.isUnset(rhs1)) {
                assert(!store.isUnset(lhs));
                assert(!store.isUnset(rhs0));
                store[rhs1.value] = store.getValue(lhs) ^ store.getValue(rhs0);
                solveConstraints(store, constraints, toCheck);
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

    
auto allSymOperands(Constr constr) {
    import std.algorithm: filter;
    import std.range: chain, only;

    return only(constr.res).chain(constr.operands)
                .filter!(a => a.valueType == ValueType.Sym);
}

auto topSortAndPrune(Constraints)(SymLit symlit, Constraints constraints) {
    import std.algorithm: filter, find, map, reverse, sort, sum, SwapStrategy;
    import std.array: array, assocArray;
    import std.range: empty, enumerate, front, popFront, repeat, zip;
    import std.typecons: tuple;

    auto constraintsCopy = constraints.dup;
    constraintsCopy.reverse;
    auto unknowns = constraintsCopy.map!((a) {
        return allSymOperands(a).assocArray(true.repeat);
                ;
    }).array;

    auto edgesToVisit = [tuple(symlit, 0)];

    ulong[][SymLit] nodeList;
    foreach(constrIdx, symList; unknowns.enumerate) {
        foreach(sym; symList.byKey) {
            nodeList.require(sym, []) ~= constrIdx;
        }
    }

    Constr[] ordered;
    ulong[] order;
    long[] bits;
    while(!edgesToVisit.empty) {
        auto currSymOrder = edgesToVisit.front;
        auto currSym = currSymOrder[0];
        auto currOrder = currSymOrder[1];
        edgesToVisit.popFront;
        auto nextContrs = currSym in nodeList;
        if (!nextContrs) {
            continue;
        }
        foreach(next; *nextContrs) {
            auto symList = unknowns[next];
            auto removed = symList[currSym];
            symList[currSym] = false;
            auto unvisited = symList.byValue.sum;
            if (removed && unvisited == 0) {
                ordered ~= constraintsCopy[next];
                order ~= currOrder;
                bits ~= currSym.numBits;
                continue;
            }
            foreach(nextEdge, unseen; symList) {
                if (!unseen) {
                    continue;
                }
                edgesToVisit ~= tuple(nextEdge, currOrder + 1);
            }
        }
    }
    ordered.zip(order, bits)
           .sort!((a, b) => tuple(a[1], /*a[2],*/ a[0].op) < tuple(b[1], /*b[2],*/ b[0].op),
                  SwapStrategy.stable);
    assert(ordered.length == constraints.length);
    return ordered;
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


    import std; constraints.writeln;
    auto realValues = new int[SymLit.nextSym];
    realValues.fill(-1);
    constraints = register[Reg.A].topSortAndPrune(constraints);
    auto toCheck = new bool[constraints.length];
    ulong[SymLit] firstOnly;
    foreach(consIdx, constr; constraints) {
        import std.algorithm: all, each, filter;
        import std.array: array;
        auto syms = constr.allSymOperands.filter!(a => a !in firstOnly).array;
        import std; syms.writeln;
        if (syms.length == 1) {
            firstOnly[syms.front] = consIdx;
        }
    }
    {import std; firstOnly.writeln(firstOnly.length);}
    foreach(consIdx, constr; constraints) {
        import std.algorithm: maxElement;
        auto check = constr.allSymOperands
                           .map!(a => a in firstOnly ? firstOnly[a]: long.max)
                           .maxElement < consIdx;
        toCheck[consIdx] = check;
    }
    import std; constraints.writeln; toCheck.writeln; firstOnly.writeln(firstOnly.length);
    solveConstraints(realValues, constraints, toCheck);
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

