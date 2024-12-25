module day20_1;

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

    enum UNSEEN = int.max;
    auto costs = repeat(cast(long) UNSEEN).take(grid.length).array;
    // uniform cost best first search
    pragma(msg, typeof(costs));
    costs[start]= 0L;
    auto toVisit = [tuple(start, 0)];
    while (!toVisit.empty) {
        auto currPosCost = toVisit.front;
        toVisit.popFront;
        auto currPos = currPosCost[0];
        auto currCost = currPosCost[1];
        foreach (neighbor; currPos.neighbors(gridLength)) {
            if (costs[neighbor] != UNSEEN) { // seen
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

auto cheatReachable(Grid)(Grid grid, long gridLength, long start, long steps)
{
    import std.array: array;
    import std.range: empty, repeat, front, popFront;
    import std.typecons: tuple;

    // uniform cost best first search
    auto toVisit = [tuple(start, 0)];
    bool[long] seen = [toVisit.front[0]: true];
    long[long] costs;
    while (!toVisit.empty) {
        auto currPosCost = toVisit.front;
        toVisit.popFront;
        auto currPos = currPosCost[0];
        auto currCost = currPosCost[1];
        if (currCost + 1 > steps) {
            break;
        }
        foreach (neighbor; currPos.neighbors(gridLength)) {
            if (neighbor in seen) {
                continue;
            }
            seen[neighbor] = true;
            if (grid[neighbor] != WALL) {
                costs[neighbor] = currCost + 1;
            }
            toVisit.assumeSafeAppend ~= tuple(neighbor, currCost + 1);
        }
    }
    return costs;
}

auto solve(Grid)(Grid grid, long gridLength) {
    import std.algorithm: any, cartesianProduct, filter, find, map, joiner;
    import std.array: join;
    import std.range: enumerate, iota, only, walkLength;
    import std.typecons: tuple;

    auto labelledGrid = grid.enumerate;
    long start = labelledGrid
        .find!(a => a[1] == 'S').front[0];
    long end = labelledGrid
        .find!(a => a[1] == 'E').front[0];

    auto fromStart = grid.solveAll(gridLength, start);
    auto toEnd = grid.solveAll(gridLength, end);

    enum THRESH = 100;
    enum STEPS = 20;
    auto baseLine = fromStart[end];
    auto saves = iota(grid.length)
    .filter!((cheatStart) => grid[cheatStart] != WALL)
    .map!((cheatStart) {
        auto reachable = cheatReachable(grid, gridLength, cheatStart, STEPS);
        return reachable
        .byKeyValue
        // .filter!(a => a.key != cheatStart)
        .map!(a=> tuple(tuple(cheatStart, a.key), fromStart[cheatStart] + toEnd[a.key] + a.value));
    })
    .join
    .map!(a => tuple(a[0], baseLine - a[1]))
    .filter!(a => a[1] >= THRESH)
    .map!( a=> a[1])
    ;
    return saves
             .walkLength;
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