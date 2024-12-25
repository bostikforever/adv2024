module day3_0;

enum NEEDLE = "mul(";

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : findSplitBefore, map, until;
    import std.range: drop, dropOne, empty, recurrence;
    import std.typecons: tuple;

    return recurrence!((a, n) {
        auto found = a[n-1][1].findSplitBefore(NEEDLE);
        auto curr = found[1];
        auto next = found[1].drop(NEEDLE.length);
        return tuple(curr, next);
    })(tuple(inputLine, inputLine)).dropOne.map!(a=>a[0]).until!(a=>a.empty);
}

auto parseLines(InputStream)(InputStream inputLines)
{
    import std.algorithm : map;

    return inputLines
        .map!(parseLine);
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm : filter, map;
    import std.format : formattedRead, FormatException;
    import std.range: empty;
    import std.typecons : tuple;

    return inputLine.map!((a) {
        int lhs, rhs, read;
        try
        {
            read = a.formattedRead("mul(%d,%d)", lhs, rhs);
        }
        catch (FormatException e)
        {
            read = 0;
        }
        return tuple(lhs, rhs, read == 2);
    }).filter!(a=>a[2]);
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : joiner, map, sum;

    return inputLines.map!(solveLine).joiner.map!(a=> a[0] * a[1]).sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine;
    auto inputData = inputLines.parseLines;
    auto ret = solve(inputData);
    writeln(ret);
    return 0;
}