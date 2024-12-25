module day4_1;

import std.typecons: tuple;

static immutable DIRS = [tuple(1, 1), tuple(-1, -1), // main diagonal
                         tuple(-1, 1), tuple(1, -1) // anti diagonal
                         ];
enum XMAS = "XMAS";

auto nextStep(Pos, Diff)(Pos pos, Diff diff) {
    pragma(msg, typeof(pos), typeof(diff));
    import std.typecons: tuple;
    return tuple(pos[0] + diff[0], pos[1] + diff[1]);
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : all, equal, filter, map, sort, sum, cartesianProduct;
    import std.range: chunks, iota, array;

    auto x0 = cast(int) inputLines.length;
    auto x1 = cast(int) inputLines[0].length;
    auto allPos = iota(x0).cartesianProduct(iota(x1));

    auto allCounts = allPos.map!((pos) {
        auto startingPos = DIRS.map!((dir)=> nextStep(pos, dir));
        auto validPos = startingPos.filter!((pos) {
            return 0 <= pos[0] && pos[0] < x0 && 0 <= pos[1] && pos[1] < x1;
        }).array;
        return inputLines[pos[0]][pos[1]] == 'A' &&
               validPos.length == 4 &&
               validPos
               .map!(a=>inputLines[a[0]][a[1]])
               .chunks(2)
               .all!((diag) {
                    auto diagSorted = cast(ubyte[])(diag.array);
                    diagSorted.sort;
                    return diagSorted.equal("MS");
               });
    });

    return allCounts.sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.array: array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputData = inputFile.byLineCopy.array;
    auto ret = solve(inputData);
    writeln(ret);
    return 0;
}