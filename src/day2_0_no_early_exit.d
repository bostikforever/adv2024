module day2_0_no_early_exit;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm : map, sum;
    import std.math: abs;
    import std.range: dropOne, slide;
    import std.typecons: tuple;

    auto invalids = inputLine.slide(2).map!((leftRight) {
        auto left = leftRight.front;
        auto right = leftRight.dropOne.front;
        return left - right;
    }).map!((diff) {
        auto absDiff = abs(diff);
        auto inRange = (1 <= absDiff) && (absDiff <= 3);
        return tuple(inRange, diff);
    }).slide(2).map!((leftRight) {
        auto left = leftRight.front;
        auto right = leftRight.dropOne.front;
        if (!left[0] || !right[0]) {
            return 1;
        }
        if ((left[1] > 0) != (right[1] > 0)) {
            return 1;
        }
        return 0;
    }).sum;
    return invalids == 0;
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : map, sum;

    auto ret = inputLines.map!solveLine.sum;
    return ret;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(parseLine);
    immutable ret = solve(inputLines);
    writeln(ret);
    return 0;
}