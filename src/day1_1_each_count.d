module day1_1_each;

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
    import std.algorithm : each, find, group, sort;
    import std.range: dropOne, stride, No, Yes;

    auto leftLines = input.stride(2).sort.group;
    auto rightLines = input.dropOne.stride(2).sort.group;

    auto ret = 0;
    leftLines.each!((leftAndCount){
        auto left = leftAndCount[0];
        auto leftCount = leftAndCount[1];
        rightLines = rightLines.find!(a => a[0] >= left);
        if (rightLines.empty) {
            return No.each;
        }
        if (rightLines.front[0] != left) {
            return Yes.each;
        }
        auto rightCount = rightLines.front[1];
        ret += rightCount * left * leftCount;
        return Yes.each;
    });
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