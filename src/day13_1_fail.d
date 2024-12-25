module day13_1_fail;

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
    import std.typecons: tuple, Tuple;

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
    return Tuple!(
        // Bézout coefficients:
        Num, "a", Num, "b",
        // quotients by the gcd:
        Num, "u", Num, "v",
        // greatest common divisor:
        Num, "gcd")(
        // Bézout coefficients:
        old_s, old_t,
        // quotients by the gcd:
        abs(t), abs(s),
        // greatest common divisor:
        old_r.abs);
}

auto solveLine(Input)(Input input) {
    import std.algorithm: filter, find, map, max, min, minElement, until;
    import std.math: ceil;
    import std.range: iota, recurrence;
    import std.typecons: tuple, Tuple;

    auto A = input[0];
    auto B = input[1];
    auto P = input[2];

    alias ExtGCD =  typeof(extendedGcd!long(A[0], B[0]));
    Tuple!(ExtGCD, "X", ExtGCD, "Y") extGcd, kextGcd;

    enum offset = 0*10_000_000_000_000;
    extGcd.X = extendedGcd!long(A[0], B[0]);
    auto P0 = P[0] + offset; 
    if ((P0 % extGcd.X.gcd) != 0) {
        return 0;
    }

    extGcd.Y = extendedGcd!long(A[1], B[1]);
    auto P1 = P[1] + offset;
    if ((P1 % extGcd.Y.gcd) != 0) {
        return 0;
    }

    extGcd.X.a *= P0 / extGcd.X.gcd;
    extGcd.X.b *= P0 / extGcd.X.gcd;

    extGcd.Y.a *= P1 / extGcd.Y.gcd;
    extGcd.Y.b *= P1 / extGcd.Y.gcd;

    // solve for k's
    // v1 * k1 - v2 * k2 = x2 - x1
    // -u1 *k1 + u2 * k2 = y2 - y1
    // k1(v1 - u1) + k2(u2 - v2) = (x2 - x1) + (y2 - y1)
    // k1 * ak + k2 * bk = t
    // ak = (v1 - u1)
    // bk = (u2 - v2)
    // t = (x2 - x1) + (y2 - y1)
    auto ak = extGcd.X.v - extGcd.X.u;
    auto bk = extGcd.Y.u - extGcd.Y.v;
    auto t = (extGcd.Y.a - extGcd.X.a) + (extGcd.Y.b - extGcd.X.b);
    auto kextGcd = extendedGcd!long(ak, bk);
    // import std; kextGcd.writeln(" ", t, " ", ak, " ", bk);
    if (t % kextGcd.gcd != 0) {
        return 0;
    }

    kextGcd.a *= t / kextGcd.gcd; 
    kextGcd.b *= t / kextGcd.gcd;


    // extGcd.X.a += kextGcd.a * extGcd.X.v;
    // extGcd.X.b -= kextGcd.a * extGcd.X.u;

    // auto vv = kextGcd.v * extGcd.X.v;
    // auto uv = kextGcd.v * extGcd.X.u;

    long minMult = cast(long) min(-extGcd.X.a * 1f/vv, extGcd.X.b * 1f/uv).ceil;
    long maxMult = cast(long) max(-extGcd.X.a * 1f/vv, extGcd.X.b * 1f/uv).ceil;
    import std; kextGcd.writeln(" ", minMult, " ", maxMult, " ", vv, " ", uv);

    // import std; extGcd.X.writeln;
    // import std; kextGcd.writeln(" ", t, " ", vv, " ", uv);

    import std;
    auto sols = iota(minMult, maxMult + 1)
                .map!((i) => tuple(extGcd.X.a + i * vv, extGcd.X.b - i * uv))
                .tee!(a => a.writeln)
                .filter!(a => a[0] >= 0 && a[1] >= 0)
                // .filter!(a => a[0] * A[1] + a[1] * B[1] == P1)
                ;

    auto res = sols.map!(a=>3UL*a[0] + a[1]).minElement(ulong.max);
    res = res == ulong.max ? 0 : res;
    return res;
}

auto solve(Inputs)(Inputs inputs)
{
    import std.algorithm: map, sum;

    return inputs.map!solveLine;
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
