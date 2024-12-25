module day20_1_bad;

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

import std.typecons: Tuple;
alias Cheat = Tuple!(long, "start", long, "end");

auto solveSingle(Grid)(Grid grid, long gridLength, Cheat cheat, long baseLine = long.max)
{
    import std.algorithm : find, map;
    import std.array: assocArray;
    import std.container : heapify;

    import std.range: enumerate; //, empty, front, popFront;
    import std.typecons: tuple;


    auto labelledGrid = grid.enumerate;
    long start = labelledGrid
        .find!(a => a[1] == 'S').front[0];
    long end = labelledGrid
        .find!(a => a[1] == 'E').front[0];

    // uniform cost best first search
    auto toVisit = [tuple(start, 0)].heapify!((a,b) => a[1] > b[1]);
    bool[long] seen;
    while (toVisit.length > 0) {
        auto currPosCost = toVisit.front;
        toVisit.popFront;
        auto currPos = currPosCost[0];
        auto currCost = currPosCost[1];
        if (currPos in seen) {
            continue;
        }
        if (currPos == end) {
            return currCost;
        }
        if (currCost > baseLine) {
            return long.max;
        }
        seen[currPos] = true;
        foreach (neighbor; currPos.neighbors(gridLength)) {
            auto nextCost = currCost + 1;
            if (grid[neighbor] == WALL && neighbor != cheat.start) {
                continue;
            }
            if (neighbor == cheat.start) {
                neighbor = cheat.end;
                nextCost = currCost + 2;
            }
            if (neighbor in seen) {
                continue;
            }
            toVisit.insert(tuple(neighbor, nextCost));
        }
    }
    assert(false, (){import std; return cheat.to!string; }());
}
auto solve(Grid)(Grid grid, long gridLength) {
    import std.algorithm: cartesianProduct, filter, map, uniq;
    import std.range: iota, only, repeat, walkLength, zip;
    import std.array: array, assocArray, join;
    import std.typecons: tuple;

    enum THRESH = 100;
    auto baseLine = grid.solveSingle(gridLength, Cheat(-1, -1));
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
                                 .map!Cheat;
        return cheats.map!((c)
               => tuple(c, grid.solveSingle(gridLength, c, baseLine - THRESH)));
    })
    .join
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