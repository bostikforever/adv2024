module day25_0;

enum KeyLock {
    KEY,
    LOCK
}

auto parseKeyLock(KeyLockLines)(KeyLockLines keyLockLines)
{
    import std.algorithm: all, map, sum;
    import std.array: array;
    import std.typecons: tuple;
    import std.range: front, transposed;

    KeyLock keyLock = keyLockLines.front.all!(a => a == '#') ? KeyLock.LOCK : KeyLock.KEY;
    auto counts = keyLockLines.transposed.map!(a => a.map!(b => b == '#').sum).array;

    return tuple(keyLock, counts);
}

auto parseKeyLocks(InputLines)(InputLines inputLines)
{
    import std.algorithm: chunkBy, map, sort;
    import std.array: array;
    import std.range: dropOne;
    import std.typecons: tuple;

    auto keyLocks = inputLines.map!parseKeyLock.array.sort.chunkBy!(a => a[0]);

    return tuple(keyLocks.front, keyLocks.dropOne.front);
}

enum GROOOVE_HEIGHT = 7;

auto solve(KeyLocks)(KeyLocks keyLocks) {
    import std.algorithm: all, cartesianProduct, filter;
    import std.range: walkLength, zip;

    auto matchingPairs = keyLocks[0][1]
                    .cartesianProduct(keyLocks[1][1])
                    .filter!(a => a[0][1].zip(a[1][1])
                                         .all!(b => b[0] + b[1] <= GROOOVE_HEIGHT))
                    .walkLength
                    ;
    return matchingPairs;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: splitter;
    import std.array: array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto keyLocks = inputLines.parseKeyLocks;
    auto ret = solve(keyLocks);
    writeln(ret);
    return 0;
}
