module day20_0_bad;

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

auto solveSingle(Grid, Cheat)(Grid grid, long gridLength, Cheat cheat, long baseLine = long.max)
{
    import std.algorithm : find, map;
    import std.array: assocArray;

    import std.range: enumerate, empty, front, popFront;
    import std.typecons: tuple;



    auto labelledGrid = grid.enumerate;
    long start = labelledGrid
        .find!(a => a[1] == 'S').front[0];
    long end = labelledGrid
        .find!(a => a[1] == 'E').front[0];

    // uniform cost best first search
    auto toVisit = [tuple(start, 0)];
    bool[long] seen = [toVisit.front[0]: true];
    while (!toVisit.empty) {
        auto currPosCost = toVisit.front;
        toVisit.popFront;
        auto currPos = currPosCost[0];
        auto currCost = currPosCost[1];
        if (currPos == end) {
            return currCost;
        }
        if (currCost > baseLine) {
            return long.max;
        }
        foreach (neighbor; currPos.neighbors(gridLength)) {
            if (grid[neighbor] == WALL && neighbor !in cheat) {
                continue;
            }
            if (neighbor in seen) {
                continue;
            }
            toVisit.assumeSafeAppend ~= tuple(neighbor, currCost + 1);
            seen[neighbor] = true;
        }
    }
    assert(false);
}
auto solve(Grid)(Grid grid, long gridLength) {
    import std.algorithm: cartesianProduct, filter, joiner, map, uniq;
    import std.range: iota, only, repeat, zip;
    import std.array: array, assocArray;
    import std.typecons: tuple;

    auto baseLine = grid.solveSingle(gridLength, new bool[long]);
    auto saves = iota(grid.length)
    // .filter!(a => (a % gridLength != 0) && 
    //               (a % gridLength != gridLength - 1) && 
    //               (a / gridLength != 0) &&
    //               (a / gridLength != gridLength - 1))
    .map!((i) {
        auto cheats = only(i).cartesianProduct(i.neighbors(gridLength))
                .filter!((a) => grid[a[0]] == WALL)
                .map!((a) => only(a.expand).filter!(b => grid[b] == WALL).array).uniq;
        // import std; cheats.writeln;
        return cheats.map!(c => 
                    tuple(c, grid.solveSingle(gridLength, c.zip(repeat(true)).assocArray))); //baseLine - 100)));
    }).joiner
    .map!(a => tuple(a[0], baseLine - a[1]))
    // .filter!(a => a + )
    ;
    import std; saves.array.sort.group.writeln;
    return baseLine;
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