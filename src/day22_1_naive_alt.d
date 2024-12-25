module day22_1_naive_alt;

// Each step of the above process involves mixing and pruning:

//     To mix a value into the secret number, calculate the bitwise XOR of the given value and the secret number. Then, the secret number becomes the result of that operation. (If the secret number is 42 and you were to mix 15 into the secret number, the secret number would become 37.)
//     To prune the secret number, calculate the value of the secret number modulo 16777216. Then, the secret number becomes the result of that operation. (If the secret number is 100000000 and you were to prune the secret number, the secret number would become 16113920.)

auto mix(long lhs, long rhs) {
    return lhs ^ rhs;
}

auto prune(long num) {
    return num % 16777216;
}

    // Calculate the result of multiplying the secret number by 64. Then, mix this result into the secret number. Finally, prune the secret number.
    // Calculate the result of dividing the secret number by 32. Round the result down to the nearest integer. Then, mix this result into the secret number. Finally, prune the secret number.
    // Calculate the result of multiplying the secret number by 2048. Then, mix this result into the secret number. Finally, prune the secret number.
auto step1(long num) {
    return (num * 64).mix(num).prune;
}
auto step2(long num) {
    return (num / 32).mix(num).prune;
}

auto step3(long num) {
    return (num * 2048).mix(num).prune;
}

auto getPrices(InputLine)(InputLine inputLine) {
    import std.algorithm: map, fold;
    import std.range: back, recurrence, takeExactly;
    import std.array: array;

    return inputLine.recurrence!((a, n) {
        return a[n-1]
                  .step1
                  .step2
                  .step3;
    })
    .map!(a=>a%10)
    .takeExactly(2001).array;
}

enum PRICE_SEQ_LEN = 4;

auto lin(Arr)(Arr arr) {
    import std.algorithm: map, sum;
    import std.range: enumerate;

    return arr.enumerate.map!(a => 20^^a[0] * (a[1] + 10)).sum;
}

auto solve(InputLines)(InputLines inputLines) {
    import std.algorithm: chunkBy, map, sort, sum, maxElement, SwapStrategy;
    import std.range: enumerate, slide;
    import std.array: array;
    import std.typecons: Tuple, tuple;

    auto prices = inputLines
                .map!getPrices.array;
    auto priceChanges = prices.map!(a => a.slide(2).map!(b => b[1] - b[0]));
    auto priceChangeSeqs = priceChanges.map!(a => a.slide(PRICE_SEQ_LEN).map!(a => a.lin));
    
    Tuple!(ulong, ulong, long)[] seqPrices;
    foreach(i, priceChangeSeq; priceChangeSeqs.enumerate) {
        foreach(j, changeSeq; priceChangeSeq.enumerate) {
            seqPrices ~= tuple(i, changeSeq, prices[i][j + PRICE_SEQ_LEN]);
        }
    }

    seqPrices.sort!((a, b) => a[1] < b[1], SwapStrategy.stable);
    auto res =  seqPrices.chunkBy!((a, b) => a[1] == b[1])
                        .map!(a => a.chunkBy!((a, b) => a[0] == b[0]).map!(a => a.front))
                         .map!(a => tuple(a.front[1], a.map!(b => b[2]).sum))
                         .maxElement!(a=>a[1])
                         ;
    return res;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;
    import std.array: array;
    import std.conv: to;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(a=> a.to!long).array;
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}