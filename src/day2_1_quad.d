module day2_1_quad;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm: filter, map;
    import std.array: array;
    import std.math: abs;
    import std.range: dropOne, enumerate;

    int dir;
    
    auto isValid = (int left, int right) {
        auto diff = left - right;
        auto absDiff = abs(diff);
        auto inRange = (1 <= absDiff) && (absDiff <= 3);
        if (dir == 0) {
            dir = diff;
        }
        return inRange && ((dir > 0) == (diff > 0));
    };
    auto inputArr = inputLine.array;
    foreach(i; 0..inputArr.length + 1) {
        dir = 0;
        auto sInputLine = inputArr.enumerate.filter!(a => a[0] != i - 1).map!(a => a[1]);
        while(!sInputLine.empty) {
            auto left = sInputLine.front;
            sInputLine = sInputLine.dropOne;
            if (sInputLine.empty) {
                return true;
            }
            auto right = sInputLine.front;
            if (!isValid(left, right)) {
                break;
            }
        }
    }
    return false;
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