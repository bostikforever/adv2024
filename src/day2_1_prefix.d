module day2_1_prefix;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto accumulate(State, Item)(State state, Item item)
{
    import std.typecons : tuple;
    import std.math : abs;

    auto valid = state[0];
    auto dir = state[1];
    auto edgePos = state[2];
    auto idx = state[3];

    if (!valid)
    {
        return tuple(false, 0, 0, idx + 1);
    }

    auto diff = item - edgePos;
    auto absDiff = abs(diff);
    auto inRange = idx < 1 || ((1 <= absDiff) && (absDiff <= 3));
    valid = inRange && (idx < 2 || (diff > 0) == (dir > 0));
    return tuple(valid, diff, item, idx + 1);

}

auto solveLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : cumulativeFold, reverse;
    import std.math : abs;
    import std.array : array, back, front;
    import std.typecons : tuple;

    auto fromLeft = inputLine.cumulativeFold!(accumulate)(tuple(true, 0, 0, 0)).array;

    if (fromLeft.back[0])
    {
        return true;
    }

    auto fromRight = inputLine.array.reverse.cumulativeFold!(accumulate)(tuple(true, 0, 0, 0))
        .array.reverse;

    assert(fromLeft.back[0] == fromRight.front[0]);

    foreach (i; 0 .. fromRight.length)
    {
        auto leftIdx = i - 1;
        auto rightIdx = i + 1;

        if (leftIdx == -1)
        {
            if (fromRight[rightIdx][0])
            {
                return true;
            }
            continue;
        }
        if (rightIdx == fromRight.length)
        {
            if (fromLeft[leftIdx][0])
            {
                return true;
            }
            continue;
        }

        auto leftItem = fromLeft[leftIdx];
        auto rightItem = fromRight[rightIdx];

        auto valid = leftItem[0] && rightItem[0];
        auto noCheckDir = (leftIdx == 0) || (rightIdx == (cast(int) fromRight.length - 1));
        auto diff = rightItem[2] - leftItem[2];
        auto leftDir = (leftItem[1] > 0);
        auto rightDir = (-rightItem[1] > 0); // negative because of how we work diff coming from right
        valid = valid && (noCheckDir || leftDir == rightDir);
        auto dirMatch = (leftIdx == 0) || ((diff > 0) == leftDir);
        dirMatch = dirMatch && ((rightIdx == (cast(int) fromRight.length - 1)) || (diff > 0) == rightDir);
        valid = valid && dirMatch;

        auto absDiff = abs(diff);
        auto inRange = ((1 <= absDiff) && (absDiff <= 3));

        valid = valid && inRange;
        if (valid)
        {
            return true;
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
    import std.algorithm : map;
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(parseLine);
    immutable ret = solve(inputLines);
    writeln(ret);
    return 0;
}
