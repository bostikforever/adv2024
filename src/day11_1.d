module day11_1;

auto numDigits(Num)(Num num)
{
    import std.math : log10;

    int digits = cast(int)(log10(cast(double) num)) + 1;
    return digits;
}

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter(" ").map!(a => a.to!ulong);
    return lineNums;
}

auto solve(Input)(Input input)
{
    import std.algorithm : each, joiner, map, sum;
    import std.array : byPair;
    import std.range : only, inputRangeObject, InputRange, RandomAccessFinite;
    import std.typecons : tuple, Tuple;

    alias NumCount = Tuple!(long, long);

    InputRange!NumCount inputRange = input.map!(a => NumCount(a, 1UL)).inputRangeObject;

    foreach (i; 0 .. 75)
    {
        InputRange!NumCount next = cast(InputRange!NumCount) inputRange.map!((numCount) {
            auto a = numCount[0];
            auto count = numCount[1];
            if (a == 0)
            {
                return cast(RandomAccessFinite!NumCount) only(tuple(1L, count))
                    .inputRangeObject;
            }
            auto n = a.numDigits;
            if (n % 2 == 0)
            {
                auto n_2 = n / 2;
                auto tens = 10 ^^ n_2;
                return cast(RandomAccessFinite!NumCount) only(
                    tuple(a / tens, count),
                    tuple(a % tens, count)
                )
                    .inputRangeObject;
            }
            return cast(RandomAccessFinite!NumCount) only(tuple(a * 2024L, count))
                .inputRangeObject;
        }).joiner.inputRangeObject;

        long[long] counts;
        next.each!((numCount) {
            auto num = numCount[0];
            auto count = numCount[1];
            counts[num] += count;
        });

        inputRange = counts.byPair.map!NumCount.inputRangeObject;
    }

    return inputRange.map!(a => a[1]).sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLine = inputFile.byLine.front;
    auto inputData = inputLine.parseLine;
    auto ret = solve(inputData);
    writeln(ret);
    return 0;
}
