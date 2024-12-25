module day2_1_bad;

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter.map!(a => a.to!int);
    return lineNums;
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm : any, each, map, sum;
    import std.math: abs;
    import std.range: dropOne, enumerate, iota, zip;
    import std.typecons: tuple, Yes, No;

    bool[2] s = [true, true];
    int[2] prev = [0, 0];
    int[2] dir = [0, 0];
    // s_i_0 = s_i_1_0 && A(i_1, i)
    // s_i_1 = s_i_1_0 || s_i_1_1 && A(i_1, i)
    // 7 4 5
    // 7: s [true, true], prev [7, 0], dir [0, 0]
    // 4: s [true, true], prev [4, 7], dir [-3, 0]
    // 5: s [false, true], prev [5, 4], dir [-3, -3]
    // 7 3 5 6
    // 7: s [true, true], prev [7, 0], dir [0, 0]
    // 3: s [false, true], prev [3, 7], dir [-4, 0]
    // 5: s [false, true], prev [5, 5], dir [-4, -2]
    // 6: s [false, true], prev [6, 6], dir [-4, -2]
    import std; writeln;
    foreach (idx, item; enumerate(inputLine))
    {
        foreach(i; iota(1, -1, -1)) {
            if (idx > 0 && (i != 1 || !s[0])) {
                auto diff = prev[i] - item;
                auto absDiff = abs(diff);
                auto inRange = ((1 <= absDiff) && (absDiff <= 3));
                if (dir[i] == 0) {
                    dir[i] = diff;
                }
                s[i] = s[i] && inRange && ((diff > 0) == (dir[i] > 0));
                // import std; writeln(i, diff, dir, s);
                prev[i] = item;
            }
            else {
                s[i] = s[0];
                prev[i] = i == 0 ? item : prev[0];
                dir[i] = dir[0];
            }
        }
        import std; writeln(prev, dir, s);
    }
    return s[].zip(prev[]).any!(a => a[0] && a[1] != 0);
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : map, sum;

    auto ret = inputLines.map!solveLine.sum;
    return ret;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!(parseLine);
    immutable ret = solve(inputLines);
    writeln(ret);
    return 0;
}