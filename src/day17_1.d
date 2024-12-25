module day17_1;

auto parseReg(InputLine)(InputLine inputLine)
{
    import std.format: formattedRead;

    long regValue;
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

// Register A: ?
// Register B: 0
// Register C: 0

// Program: 2,4,1,7,7,5,0,3,4,4,1,7,5,5,3,0
// Manually decoded to the following program
// A = ?, B = 0, C = 0
// 0. B = A mod 8
// 1. B = B ^ 7
// 2. C = A >> B
// 3. A = A >> 3
// 4. B = B ^ C
// 5. B = B ^ 7
// 6. out B mod 8
// 7. test A =/= 0, if true goto 0.
//
// last 3 bits of B each stage obeys:
// output ^ 7 ^ C ^ 7 == A mod 8
// output ^ C == A mod 8
// C = A >> ((A mod 8) ^ 7 )

auto toNum(A)(A avec) {
    import std.algorithm: fold, until;
    import std.range: enumerate;
    return avec.until!(a => a == -1)
               .enumerate
               .fold!((a, b) => a | (1L * b[1] << b[0]))(0L);
}
auto solveLevel(Instructions, A)(Instructions instrs, A avec, int level = 0) {
    if (level == instrs.length) {
        import std; writeln(avec.toNum);
        return;
    }
    auto aVecOffset = level * 3;
    foreach(bCShift; 0..8) {
        auto toReset = cast(ulong[]) [];
        auto aMod8 = bCShift ^ 7;
        auto cMod8 = aMod8 ^ instrs[level];
        auto valid = true;
        foreach(i; 0..3) {
            auto aBit = (aMod8 >> i) & 1;
            auto cBit = (cMod8 >> i) & 1;
            auto aIdx = aVecOffset + i;
            auto cIdx = aVecOffset + i + bCShift;
            if (avec[aIdx] == -1) {
                toReset ~= aIdx;
                avec[aIdx] = aBit;
            }
            else if(avec[aIdx] != aBit) {
                valid = false;
                break;
            }
            if (avec[cIdx] == -1) {
                toReset ~= cIdx;
                avec[cIdx] = cBit;
            }
            else if(avec[cIdx] != cBit) {
                valid = false;
                break;
            }
        }
        if (valid) {
            solveLevel(instrs, avec, level + 1);
        }
        foreach(i; toReset) {
            avec[i] = -1;
        }
    }
}

auto solve(Instructions)(Instructions instrs)
{
    import std.range: repeat;
    import std.array: array;

    auto aVec = (-1).repeat(64).array;
    // add halting constraint
    aVec[instrs.length*3..$] = 0;
    solveLevel(instrs, aVec);
    return 0;
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

