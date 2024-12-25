module day16_0;

static immutable DIRS = ['>', 'v', '<', '^'];
auto add(CHAR)(long left, CHAR dir, long gridLength, long mul = 1) {
    final switch (dir) {
        case '>':
            return left + mul;
        case '<':
            return left - mul;
        case '^':
            return left - mul * gridLength;
        case 'v':
            return left + mul * gridLength;
    }
}

auto parseData(InputStream)(InputStream inputLines)
{
    import std.algorithm : group, map, joiner;

    return inputLines.joiner.group;
}

const char WALL = '#';

// auto costToGo(State)(State state, long endPos, long gridLength) {
//     import std.math: abs;
//     auto res = abs((endPos - state.pos.pos)/gridLength) + abs((gridLength + endPos - state.pos.pos)%gridLength);
//     return res;
// }
// auto costFunc(State)(State lhs, State rhs, long endPos, long gridLength) {
//     return lhs.cost + lhs.costToGo(endPos, gridLength) > rhs.cost + rhs.costToGo(endPos, gridLength);
// }

auto solve(Grid)(Grid grid, long gridLength)
{
    import std.algorithm : count, filter, find, map, minElement, sum;
    import std.container : heapify;
    import std.range : enumerate, only;
    import std.string: indexOf;
    import std.typecons : tuple, Tuple;


    auto labelledGrid = grid.enumerate;
    long start = labelledGrid
        .find!(a => a[1] == 'S').front[0];
    long end = labelledGrid
        .find!(a => a[1] == 'E').front[0];

    alias State = Tuple!(long, "pos", char, "dir");
    auto StartState = State(start, '>');
    alias Next = Tuple!(State, "pos", State, "from", long, "cost");
    auto toVisit = [Next(StartState, StartState, 0)].heapify!((a,b) => /+costFunc(a, b, end, gridLength)+/ a.cost > b.cost);
    alias PathFrag = Tuple!(State, "from", long, "cost");
    PathFrag[State] paths;
    while (toVisit.length > 0)
    {
        auto curr = toVisit.front;
        toVisit.popFront();
        if (curr.pos in paths)
        {
            continue;
        }
        paths[curr.pos] = PathFrag(curr.from, curr.cost);
        if (curr.pos.pos == end)
        {
            break;
        }
        auto currPos = curr.pos.pos;
        auto currDir = curr.pos.dir;
        long currDirIndex = DIRS.indexOf(currDir);
        auto prevIdx = (currDirIndex + 3) % DIRS.length;
        auto nextIdx = (currDirIndex + 1) % DIRS.length;
        char cwDir = DIRS[nextIdx % DIRS.length];
        char ccwDir = DIRS[prevIdx % DIRS.length];
        auto nextPaths = only(
                        tuple(currPos.add(currDir, gridLength), currDir, 1), 
                        tuple(currPos, ccwDir, 1000),
                        tuple(currPos, cwDir, 1000),
                        );
        foreach (nextPath; nextPaths)
        {
            // import std; nextPath.writeln;
            if (grid[nextPath[0]] == WALL) {
                continue;
            }
            auto nextPos = State(nextPath[0], nextPath[1]);
            auto cost = nextPath[2];
            if (nextPos in paths) {
                continue;
            }
            toVisit.insert(Next(nextPos, curr.pos, curr.cost + cost));
        }
    }
    return *DIRS.map!((a){
                auto state = State(end, cast(char)a);
                return state in paths;
            })
            .filter!(a => cast(bool) (a))
            // .map!(a => a.cost)
            .minElement!(a=>a.cost);
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