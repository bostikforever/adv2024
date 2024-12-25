module day20_0;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;
    import std.range: dropOne;
    import std.typecons: tuple;

    auto lineNums = inputLine.splitter(",").map!(a => a.to!int);
    return tuple(lineNums.front, lineNums.dropOne.front);
}

auto parseLines(InputStream)(InputStream inputLines)
{
    import std.algorithm : map;

    return inputLines
        .map!(parseLine);
}

enum DIR {
    UP,
    DOWN,
    LEFT,
    RIGHT
}

enum WALL = '#';

auto neighbors(long idx, long gridLength) {
    import std.algorithm: filter, map;
    import std.traits: EnumMembers;
    import std.range: only;

    auto res = only(EnumMembers!DIR).map!((a){
        final switch(a) {
            case DIR.UP:
                return idx - gridLength < 0 ? -1 : idx - gridLength;
            case DIR.DOWN:
                return idx + gridLength >= gridLength ^^ 2 ? -1 : idx + gridLength;
            case DIR.LEFT:
                return idx % gridLength == 0 ? -1 : idx - 1;
            case DIR.RIGHT:
                return idx % gridLength == gridLength - 1 ? -1 : idx + 1;
        }
    }).filter!(a => a != -1);
    return res;
}


auto solveAll(Grid)(Grid grid, long gridLength, long start)
{
    import std.array: array;
    import std.range: empty, repeat, front, popFront, take;
    import std.typecons: tuple;

    auto costs = repeat(int.max).take(grid.length).array;
    // uniform cost best first search
    auto toVisit = [tuple(start, 0)];
    while (!toVisit.empty) {
        auto currPosCost = toVisit.front;
        toVisit.popFront;
        auto currPos = currPosCost[0];
        auto currCost = currPosCost[1];
        foreach (neighbor; currPos.neighbors(gridLength)) {
            if (costs[neighbor] != int.max) { // seen
                continue;
            }
            costs[neighbor] = currCost + 1;
            if (grid[neighbor] == WALL) {
                continue;
            }
            toVisit.assumeSafeAppend ~= tuple(neighbor, currCost + 1);
        }
    }
    return costs;
}

auto solve(Grid)(Grid grid, long gridLength) {
    import std.algorithm: cartesianProduct, filter, find, map, joiner;
    import std.range: enumerate, iota, only, walkLength;
    import std.typecons: tuple;

    auto labelledGrid = grid.enumerate;
    long start = labelledGrid
        .find!(a => a[1] == 'S').front[0];
    long end = labelledGrid
        .find!(a => a[1] == 'E').front[0];

    auto fromStart = grid.solveAll(gridLength, start);
    auto toEnd = grid.solveAll(gridLength, end);
    import std; fromStart.writeln(", ", toEnd);

    enum THRESH = 100;
    auto baseLine = fromStart[end];
    auto saves = iota(grid.length)
    .filter!((i){
        auto x = i % gridLength;
        auto y = i / gridLength;
        return x != 0 && x != gridLength - 1 && y != 0 && y != gridLength - 1;
    })
    .filter!((cheat) => grid[cheat] == WALL)
    .map!((cheat) {
        auto cheats = only(cheat).cartesianProduct(cheat.neighbors(gridLength))
                                 .filter!(a => grid[a[1]] != WALL)
                                 ;
        return cheats.map!(a=> tuple(a, fromStart[a[0]] + toEnd[a[1]] + 1));

    })
    .joiner
    .map!(a => baseLine - a[1])
    .filter!(a => a >= THRESH)
    ;
    return saves.walkLength;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.array: array, join;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy;
    auto gridLength = inputLines.front.length;
    auto grid = inputLines.join;
    auto ret = solve(grid, cast(int) gridLength);
    import std; grid.chunks(gridLength).each!(line => line.writeln);
    writeln(ret);
    return 0;
}