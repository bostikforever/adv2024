module day11_0;
import core.internal.string;

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

    auto lineNums = inputLine.splitter(" ").map!(a => a.to!long);
    return lineNums;
}

auto solve(Input)(Input input)
{
    import std.algorithm : joiner, map;
    import std.range : only, inputRangeObject, InputRange, RandomAccessFinite, walkLength;

    InputRange!long inputRange = input.inputRangeObject;
    foreach (i; 0 .. 25)
    {
        InputRange!long next = cast(InputRange!long) inputRange.map!((a) {
            if (a == 0)
            {
                return cast(RandomAccessFinite!long) only(1L).inputRangeObject;
            }
            auto n = a.numDigits;
            if (n % 2 == 0)
            {
                auto n_2 = n / 2;
                auto tens = 10 ^^ n_2;
                return cast(RandomAccessFinite!long) only(a / tens, a % tens)
                    .inputRangeObject;
            }
            return cast(RandomAccessFinite!long) only(a * 2024L).inputRangeObject;
        }).joiner.inputRangeObject;
        inputRange = next;
    }

    return inputRange.walkLength;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLine = inputFile.byLine.front;
    auto inputData = inputLine.parseLine;
    immutable ret = solve(inputData);
    writeln(ret);
    return 0;
}
