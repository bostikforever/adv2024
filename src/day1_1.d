module day1_1;

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
    import std.algorithm : group, map, sort, sum;
    import std.array: assocArray;
    import std.math: abs;
    import std.range: dropOne, stride;

    auto leftLines = input.stride(2).sort;
    auto rightLines = input.dropOne.stride(2).sort;
    auto rightCounts = rightLines.group.assocArray;
    auto ret = leftLines.map!(a=> a * rightCounts.get(a,0)).sum;
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