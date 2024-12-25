module day22_0;

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

auto solveLine(InputLine)(InputLine inputLine) {
    import std.algorithm: fold;
    import std.range: back, recurrence, takeExactly;

    return inputLine.recurrence!((a, n) {
        return a[n-1]
                  .step1
                  .step2
                  .step3;
    }).takeExactly(2001).fold!((a, b) => b);
}

auto solve(InputLines)(InputLines inputLines) {

    import std.algorithm: map, sum;

    return inputLines
                .map!solveLine
                .sum;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;
    import std.array: array;
    import std.conv: to;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(a=> a.to!long);
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}