module day2_1_dp;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm : map;
    import std.array: popBack;
    import std.math: abs;
    import std.range: dropOne, empty, enumerate;
    import std.typecons: Tuple, tuple;


    alias State = Tuple!(long, "length", long, "omitted", int, "dir", int, "front");


    State[] excluded = [State(0, -1, 0, 0)];
    State[] included = [State(1, 0, 0, inputLine.front)];
    inputLine = inputLine.dropOne;

    auto willMatch = (ref State old, int newFront) {
        if (old.length == 0) {
            return tuple(true, State(1, 0, 0, newFront));
        }

        auto diff = old.front - newFront;
        auto absDiff = abs(diff);
        auto inRange = ((1 <= absDiff) && (absDiff <= 3));
        auto dir = diff > 0 ? -1 : 1;
        auto res = old;
        res.front = newFront;
        res.length += 1;
        if (old.length == 1) {
            res.dir = dir;
            return tuple(inRange, res);
        }
        auto dirMatch = dir == old.dir;
        return tuple(inRange && dirMatch, res);
    };

    foreach(i, newFront; inputLine.enumerate) {
        if (included.empty && excluded.empty) {
            break;
        }
        inputLine = inputLine.dropOne;
        State[] newExcluded;
        foreach(oldExclude; excluded) {
            auto matchNew = willMatch(oldExclude, newFront);
            auto match = matchNew[0];
            auto newState = matchNew[1];
            if (match) {
                newExcluded ~= newState;
            }
        }
        excluded = newExcluded;

        if (included.empty) {
            continue;
        }
        auto excludeTip = included[0];
        excludeTip.omitted = i + 1;
        excluded ~= excludeTip;
        auto newIncluded = willMatch(included[0], newFront);
        if (newIncluded[0]) {
            included[0] = newIncluded[1];
        }
        else {
            included.popBack;
        }
    }
    return !included.empty || !excluded.empty;
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