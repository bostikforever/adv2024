module day14_1;

auto parseLine(InputLine)(InputLine inputLine)
{
    import std.format: formattedRead;
    import std.typecons: tuple, Tuple;

    alias Coord = Tuple!(int, "x", int, "y");
    Coord pos, vel;
    inputLine.formattedRead("p=%d,%d v=%d,%d", pos.x, pos.y, vel.x, vel.y);
    return tuple(pos, vel);
}


// enum X_LEN = 11;
// enum Y_LEN = 7;

enum X_LEN = 101;
enum Y_LEN = 103;

auto solveLine(InputLine, Num)(InputLine inputLine, Num seconds) {
    auto pos = inputLine[0];
    auto vel = inputLine[1];

    pos.x += (seconds * vel.x) % X_LEN;
    pos.x += X_LEN;
    pos.x %= X_LEN;

    pos.y += (seconds * vel.y) % Y_LEN;
    pos.y += Y_LEN;
    pos.y %= Y_LEN;

    return pos;
}

auto solveNum(InputLines, Num)(InputLines inputLines, Num seconds)
{
    import std.algorithm : all, chunkBy, each, filter, group, map, sort, sum, startsWith, joiner;
    import std.array: array, assocArray;
    import std.range: chain, repeat, only;
    import std.typecons: tuple;

    auto moved = inputLines.map!(a=>a.solveLine(seconds))
                .array
                .sort.release.group.assocArray;

    alias Pixel = typeof(moved.byKey.front);
    

    auto treeLike = false;
    foreach(i; 0..X_LEN) {
        foreach(j; 0..Y_LEN) {
            auto treeTop = [                   Pixel(i, j),
                            Pixel(i - 1, j+1), Pixel(i, j+1), Pixel(i + 1, j+1),
         Pixel(i - 2, j+2), Pixel(i - 1, j+2), Pixel(i, j+2), Pixel(i + 1, j+2), Pixel(i, j+2), Pixel(i + 1, j+2),
                            ];
            treeLike = treeLike || treeTop.all!(a=> cast(bool) (a in moved));
            if (treeLike) {
                break;
            }
        }
    }
    if (!treeLike) {
        return false;
    }
    auto pixels = moved.keys.sort!((a, b) => tuple(a.y, a.x) < tuple(b.y, b.x))
                .chunkBy!((a, b) => a.y == b.y)
                ;

    import std.stdio: write, writeln;
    auto lastLine = 0;
    foreach(line; pixels) {
        auto lineNum = line.front.y;
        '\n'.repeat(lineNum - lastLine).write;
        lastLine = lineNum;
        auto lastCol = 0;
        foreach(pixel; line) {
            auto colNum = pixel.x;
            ' '.repeat(colNum - lastCol).write;
            lastCol = colNum;
            '*'.write;
        }
        ' '.repeat(X_LEN - lastCol).writeln;
    }
    '\n'.repeat(Y_LEN - lastLine).writeln;
    return true;
}

auto solve(InputLines, Num)(InputLines inputLines, Num num) {
    import std.stdio: writeln;
    import std.array: array;
    import std.range: repeat;

    auto lines = inputLines.array;
    foreach(i; 0..num + 1) {
        auto isPossiblyTree = lines.solveNum(i);
        if (isPossiblyTree) {
            writeln(i);
            writeln('\n'.repeat(5));
        }
    }
    return 0;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;
    import std.conv: to;

    immutable filename = argv[1];
    immutable count = argv.length > 2 ? argv[2].to!int: 100;
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(parseLine);
    auto ret = solve(inputLines, count);
    writeln(ret);
    return 0;
}