module day1_0_chunk;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto parseLines(InputStream)(InputStream inputLines)
{
    import std.algorithm : map;
    import std.array: join;

    return inputLines
        .map!(parseLine).join;
}

auto solve(Input)(Input input)
{
    import std.algorithm : map, sort, sum;
    import std.math: abs;
    import std.range: chunks, dropOne, stride, zip;

    input.stride(2).sort;
    input.dropOne.stride(2).sort;
    auto ret = input.chunks(2).map!((a) => abs(a[0] - a[1])).sum;
    return ret;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine;
    auto inputData = inputLines.parseLines;
    immutable ret = solve(inputData);
    writeln(ret);
    return 0;
}