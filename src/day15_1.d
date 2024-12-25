module day15_1;

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


const char WALL = '#';
const char SPACE = '.';
const char BLOCK_RAW = 'O';
const char BLOCK_LEFT = '[';
const char BLOCK_RIGHT = ']';

auto parseLine(InputLine)(InputLine inputLine)
{
    import std.algorithm: map, joiner;
    import std.range: only;

    return inputLine.map!((a) {
        switch(a) {
          case WALL:
            return only(WALL, WALL);
          case BLOCK_RAW:
            return only(BLOCK_LEFT, BLOCK_RIGHT);
          default:
            return only(cast(const char)a, SPACE);
        }
    }).joiner;
}

auto parseData(InputStream)(InputStream inputLines)
{
    import std.algorithm : group, map, joiner;

    return inputLines.joiner.group;
}

auto getConnected(Grid, CHAR)(long[] start, CHAR dir, Grid grid, long gridLength) {
    import std.algorithm: map, sort, uniq;
    import std.array: array, join;

    auto curr = start;
    typeof(curr) next = [];
    while (true) {
        auto newBlocks = curr.map!((a) {
            auto nextA = a.add(dir, gridLength);
            final switch(grid[nextA]) {
                case WALL:
                    return cast(typeof(curr))[];
                case SPACE:
                    return cast(typeof(curr))[];
                case BLOCK_LEFT:
                    return [nextA, nextA + 1];
                case BLOCK_RIGHT:
                    return [nextA - 1, nextA];
            }
        })
        .join;
        next = (curr ~ newBlocks)
        .sort!((a, b) => dir == '^' ? a < b : a > b)
        .uniq
        .array;

        if (curr ==  next) {
            return next;
        }
        curr = next;
    }
    assert(false);
}
auto moveVertical(Grid, CHAR)(long[] start, CHAR dir, long steps, Grid grid, long gridLength)
{
    import std.algorithm: all, each, filter, sort, swap, uniq;
    import std.range: repeat;
    import std.array: assocArray;

    auto block = getConnected(start, dir, grid, gridLength);
    auto stepsMoved = 0;
    while (stepsMoved < steps) {
        auto frontier = block.filter!((a) {
            auto next = a.add(dir, gridLength);
            return grid[next] != BLOCK_LEFT && grid[next] != BLOCK_RIGHT;
        });
        auto canMove = frontier.all!((a){
            auto next = a.add(dir, gridLength);
            return grid[next] != WALL;
        });
        if (!canMove) {
            break;
        }
        auto blocksMove = block.sort!((a, b) => dir == '^' ? a < b : a > b).uniq;
        foreach(cell; blocksMove) {
            auto cellNext = cell.add(dir, gridLength);
            swap(grid[cell], grid[cellNext]);
        }
        block.each!((ref a) => a = a.add(dir, gridLength));
        block = getConnected(block, dir, grid, gridLength);
        stepsMoved += 1;
    }
    return stepsMoved;
}

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
        if (dir == '>' || dir == '<') {
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
        else {
            auto moved = [start].moveVertical(dir, steps, grid, gridLength);
            start = start.add(dir, gridLength, moved);
        }
    }

    return grid.enumerate
            .filter!(a=> a[1] == BLOCK_LEFT)
            .map!(a=> (a[0] % gridLength) + (a[0] / gridLength) * 100)
            .sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: map, splitter;
    import std.range: dropOne, walkLength;
    import std.array: array, join;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto gridLines = inputLines.front.map!parseLine;
    auto gridLength = gridLines.front.walkLength;
    auto grid = gridLines.join.dup;
    auto inputData = inputLines.dropOne.front.parseData;
    auto ret = solve(grid, cast(int) gridLength, inputData);
    import std; grid.chunks(gridLength).each!(line => line.writeln);
    writeln(ret);
    return 0;
}

