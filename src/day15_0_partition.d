module day15_0_partition;

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
const char SPACE = '.';
const char BLOCK = 'O';

auto solve(Grid, InputData)(Grid grid, long gridLength, InputData inputData)
{
    import std.algorithm: count, cumulativeFold, filter, find, joiner, map, partition, 
                            sum, SwapStrategy, until;
    import std.range: enumerate, indexed, iota, sequence;

    auto labelledGrid = grid.enumerate;

    long start = labelledGrid
        .find!(a => a[1] == '@').front[0];

    foreach(dirSteps; inputData) {
        auto steps = dirSteps[1];
        auto dir = dirSteps[0];
        auto moved = sequence!((a, n) => n).map!((a) => start.add(dir, gridLength, a))
                    .map!(a => grid[a])
                    .until!(a => a == WALL)
                    .map!(a => a == SPACE)
                    .cumulativeFold!((a, b) => a + b)
                    .until!(a => a > steps)
                    .count
                    ;
        auto index = iota(0, moved).map!((a) => start.add(dir, gridLength, a));
        auto toPartition = (cast(byte[])grid).indexed(index);
        auto partitioned = toPartition.partition!(a=> a == '.', SwapStrategy.stable);
        start = partitioned.physicalIndex(0);
    }

    return labelledGrid
            .filter!(a=> a[1] == BLOCK)
            .map!(a=> (a[0] % gridLength) + (a[0] / gridLength) * 100)
            .sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: splitter;
    import std.range: dropOne;
    import std.array: array, join;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto gridLength = inputLines.front.length;
    auto grid = inputLines.front.join;
    auto inputData = inputLines.dropOne.front.parseData;
    auto ret = solve(grid, cast(int) gridLength, inputData);
    import std; grid.chunks(gridLength).each!(line => line.writeln);
    writeln(ret);
    return 0;
}

