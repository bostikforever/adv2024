module day18_1;

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

enum Mode {
    Sample,
    Actual    
}

// static immutable Mode mode = Mode.Sample;
static immutable Mode mode = Mode.Actual;

static if (mode == Mode.Sample) {
    enum X_LEN = 7;
    enum Y_LEN = 7;
    enum End = linear(6, 6);
}
else {
    enum X_LEN = 71;
    enum Y_LEN = 71;
    enum End = linear(70, 70);
}

enum GRID_LEN = X_LEN * Y_LEN;

auto linear(long x, long y) {
    return x + y * X_LEN;
}

enum DIR {
    UP,
    DOWN,
    LEFT,
    RIGHT
}

auto neighbors(long idx) {
    import std.algorithm: filter, map;
    import std.traits: EnumMembers;
    import std.range: only;

    auto res = only(EnumMembers!DIR).map!((a){
        final switch(a) {
            case DIR.UP:
                return idx - X_LEN < 0 ? -1 : idx - X_LEN;
            case DIR.DOWN:
                return idx + X_LEN >= GRID_LEN ? -1 : idx + X_LEN;
            case DIR.LEFT:
                return idx % X_LEN == 0 ? -1 : idx - 1;
            case DIR.RIGHT:
                return idx % X_LEN == X_LEN - 1 ? -1 : idx + 1;
        }
    }).filter!(a => a != -1);
    return res;
}

auto solveSingle(Input)(long takeBytes, Input input)
{
    import std.algorithm : map;
    import std.array: assocArray;

    import std.range: empty, front, popFront, sequence, take, zip;
    import std.typecons: tuple;

    auto occupiedAt = input.take(takeBytes).map!(a => linear(a[0], a[1]))
                         .zip(sequence!((a, n) => n))
                         .assocArray;

    // uniform cost best first search
    auto start = 0L;
    auto toVisit = [tuple(start, 0)];
    bool[long] seen = [toVisit.front[0]: true];
    while (!toVisit.empty) {
        auto currPosCost = toVisit.front;
        toVisit.popFront;
        auto currPos = currPosCost[0];
        auto currCost = currPosCost[1];
        if (currPos == End) {
            return false;
        }
        foreach (neighbor; currPos.neighbors) {
            if (neighbor in occupiedAt) {
                continue;
            }
            if (neighbor in seen) {
                continue;
            }
            toVisit.assumeSafeAppend ~= tuple(neighbor, currCost + 1);
            seen[neighbor] = true;
        }
    }
    return true;
}

auto solve(Input)(Input input)
{
    import std.range : iota, assumeSorted;

    bool[long] predResult;

    auto cachedPred = (long a) {
        auto res = a in predResult;
        if (res) {
            return *res;
        }
        return predResult[a] = (a+1).solveSingle(input);
    };

    auto pred = (long a, long b) {
        return cachedPred(a) < cachedPred(b);
    };

    auto idxRange = iota(0, input.length).assumeSorted!pred;
    auto cutIdx = idxRange.equalRange(cast(long) input.length - 1);

    // import std; input[idxRange.map!(a => (a+1).solveSingle(input)).until(true).walkLength].writeln;
    return input[cutIdx.front];
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.array : array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine;
    auto inputData = inputLines.parseLines.array;
    immutable ret = solve(inputData);
    writeln(ret);
    return 0;
}