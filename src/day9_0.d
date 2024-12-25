module day9_0;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.array: array;
    import std.conv : to;

    auto lineNums = inputLine.splitter("").map!(a => a.to!int);
    return lineNums.array;
}

auto solve(Input)(Input input)
{
    import std.algorithm : min;
    import std.range: dropOne, stride;

    long res = 0;

    auto files = input.stride(2);
    auto spaces = input.dropOne.stride(2);

    auto checkSumFrag = (long fileId, long blockIdx, long blockSize) {
        return fileId * (blockIdx * blockSize + (blockSize * (blockSize - 1))/2);
    };

    int blockIdx = 0;
    int fileId = 0;
    while (fileId < files.length) {
        // files pass
        auto blockSize = files[fileId];
        res += checkSumFrag(fileId, blockIdx, blockSize);
        fileId += 1;
        blockIdx += blockSize;

        // spaces pass
        if (spaces.empty) {
            continue;
        }
        auto space = spaces.front;
        while (space > 0 && files.length > fileId) {
            int backFileId = cast(int) files.length - 1;
            int* backBlockSize = &files[backFileId];
            int spaceToUse = min(space, *backBlockSize);
            res += checkSumFrag(backFileId, blockIdx, spaceToUse);
            *backBlockSize -= spaceToUse;
            if (*backBlockSize == 0) {
                files = files[0..$-1];
            }
            space -= spaceToUse;
            blockIdx += spaceToUse;
        }
        spaces = spaces.dropOne;
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