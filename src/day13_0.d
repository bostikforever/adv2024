module day13_0;

auto parseInput(InputGroup)(InputGroup inputGroup) {
    import std.algorithm: map;
    import std.range: chunks, dropOne, front;
    import std.array: array;
    import std.format: formattedRead;
    import std.typecons: tuple;

    auto lineGroups = inputGroup.chunks(2);
    auto buttons = lineGroups.front.map!((inputLine){
        int x, y;
        inputLine.formattedRead("Button %*c: X+%d, Y+%d", x, y);
        return tuple(x, y);
    }).array;

    auto prize = tuple(0, 0);
    auto prizeLine = lineGroups.dropOne.front.front;
    prizeLine.formattedRead("Prize: X=%d, Y=%d", prize[0], prize[1]);
    return tuple(buttons[0], buttons[1], prize);
}

auto parseInputs(InputStream)(InputStream inputGroups)
{
    import std.algorithm : map;

    return inputGroups
        .map!(parseInput);
}

auto extendedGcd(Num)(Num a, Num b) {
    import std.math: abs;
    import std.meta: AliasSeq;
    import std.typecons: tuple;

    Num old_r, r, old_s, s, old_t, t;

    AliasSeq!(old_r, r) = AliasSeq!(a, b);
    AliasSeq!(old_s, s) = AliasSeq!(1, 0);
    AliasSeq!(old_t, t) = AliasSeq!(0, 1);
    
    while (r != 0) {
        auto quotient = old_r / r;
        AliasSeq!(old_r, r) = tuple(r, old_r - quotient * r);
        AliasSeq!(old_s, s) = tuple(s, old_s - quotient * s);
        AliasSeq!(old_t, t) = tuple(t, old_t - quotient * t);

    }
    return tuple(
        // Bézout coefficients:
        old_s, old_t,
        // quotients by the gcd:
        abs(t), abs(s),
        // greatest common divisor:
        old_r);
}

auto solveLine(Input)(Input input) {
    import std.algorithm: filter, find, map, min, minElement, until;
    import std.meta: AliasSeq;
    import std.numeric: gcd;
    import std.range: recurrence;
    import std.typecons: tuple;

    auto A = input[0];
    auto B = input[1];
    auto P = input[2];

    typeof(A[0]) a, b, u, v, gcd0;
    AliasSeq!(a, b, u, v, gcd0) = extendedGcd(A[0], B[0]);

    if ((P[0] % gcd0) != 0) {
        return 0;
    }

    auto gcd1 = gcd(A[1], B[1]);
    if ((P[1] % gcd1) != 0) {
        return 0;
    }

    a *= P[0] / gcd0;
    b *= P[0] / gcd0;
    // a -= f0 * v;
    // b += f0 * u;
    auto k = b > a ? 1 : -1; 
    auto sols = recurrence!((s, n) => tuple(s[n-1][0] + k * v, s[n-1][1] - k * u))(tuple(a, b))
                .find!(sol => sol[0] >= 0 && sol[1] >= 0)
                .until!(sol => (sol[0] >= 0) != (sol[1] >= 0))
                .filter!((a) => A[1] * a[0] + B[1] * a[1] == P[1])
                ;
    auto res = sols.map!(a=>3UL*a[0] + a[1]).minElement(ulong.max);
    res = res == ulong.max ? 0 : res;
    return res;
}

auto solve(Inputs)(Inputs inputs)
{
    import std.algorithm: map, sum;

    return inputs.map!solveLine.sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.range: chunks;
    
    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.chunks(4);
    auto inputs = inputLines.parseInputs;
    auto ret = inputs.solve;
    writeln(ret);
    return 0;
}
