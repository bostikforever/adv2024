module day2_0_for;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.math: abs;
    import std.range: dropOne;

    int dir = 0;
    
    auto isValid = (int left, int right) {
        auto diff = left - right;
        auto absDiff = abs(diff);
        auto inRange = (1 <= absDiff) && (absDiff <= 3);
        if (dir == 0) {
            dir = diff;
        }
        return inRange && ((dir > 0) == (diff > 0));
    };
    while(!inputLine.empty) {
        auto left = inputLine.front;
        inputLine = inputLine.dropOne;
        if (inputLine.empty) {
            return true;
        }
        auto right = inputLine.front;
        if (!isValid(left, right)) {
            return false;
        }
    }
    assert(false);
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