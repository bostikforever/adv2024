module day14_0;

auto parseLine(InputLine)(InputLine inputLine)
{
    import std.format: formattedRead;
    import std.typecons: tuple, Tuple;

    alias Coord = Tuple!(int, "x", int, "y");
    Coord pos, vel;
    inputLine.formattedRead("p=%d,%d v=%d,%d", pos.x, pos.y, vel.x, vel.y);
    return tuple(pos, vel);
}


enum SECONDS = 100;
// enum X_LEN = 11;
// enum Y_LEN = 7;

enum X_LEN = 101;
enum Y_LEN = 103;

auto solveLine(InputLine)(InputLine inputLine) {
    auto pos = inputLine[0];
    auto vel = inputLine[1];

    pos.x += (SECONDS * vel.x) % X_LEN;
    pos.x += X_LEN;
    pos.x %= X_LEN;

    pos.y += (SECONDS * vel.y) % Y_LEN;
    pos.y += Y_LEN;
    pos.y %= Y_LEN;

    return pos;
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : each, filter, fold, map, sum;
    import std.typecons: tuple;

    auto quandCount = [tuple(false, false): 0, tuple(false, true): 0,
                       tuple(true, false): 0, tuple(true, true): 0];
    inputLines.map!solveLine
                .filter!(a=> a.x != (X_LEN/2) && a.y != (Y_LEN/2))
                .map!(a=> tuple(a.x < X_LEN/2, a.y < Y_LEN / 2))
                .each!(a => quandCount[a] += 1)
                ;
    return quandCount.byValue.fold!((a, b) => a*b);
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(parseLine);
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}