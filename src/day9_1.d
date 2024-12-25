module day9_1;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter("").map!(a => a.to!int);
    return lineNums;
}

auto solve(Input)(Input input)
{
    import std.algorithm : cumulativeFold, find, min;
    import std.array: array;
    import std.range: dropOne, empty, enumerate, retro, stride;
    import std.typecons: tuple;

    long res = 0;

    auto withBlockIndexes = input.cumulativeFold!((state, x) {
        return tuple(state[0] +  state[1], x);
    })(tuple(0, 0)).array;

    auto files = withBlockIndexes.stride(2);
    auto spaces = withBlockIndexes.dropOne.stride(2);


    auto checkSumFrag = (long fileId, long blockIdx, long blockSize) {
        return fileId * (blockIdx * blockSize + (blockSize * (blockSize - 1))/2);
    };

    foreach(fileId, blockIdxAndSize; files.enumerate.retro) {
        spaces = spaces[0..fileId];
        auto blockSize = blockIdxAndSize[1];
        auto space = spaces.find!(a=>a[1] >= blockSize);
        if (space.empty) {
            res += checkSumFrag(fileId, blockIdxAndSize.expand);
            continue;
        }
        // else
        auto spaceBlockIdx = &(space[0][0]);
        auto spaceLeft = &(space[0][1]);
        res += checkSumFrag(fileId, *spaceBlockIdx, blockSize);
        *spaceBlockIdx += blockSize;
        *spaceLeft -= blockSize;
    }
    return res;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLine = inputFile.byLine.front;
    auto inputData = inputLine.parseLine;
    immutable ret = solve(inputData);
    writeln(ret);
    return 0;
}