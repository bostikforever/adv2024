module day4_0;

import std.typecons: tuple;

static immutable DIRS = [tuple(0, 1), tuple(0, -1),
                         tuple(1, 0), tuple(-1, 0),
                         tuple(1, 1), tuple(1, -1),
                         tuple(-1, 1), tuple(-1, -1)];
enum XMAS = "XMAS";

auto nextStep(Pos, Diff)(Pos pos, Diff diff) {
    pragma(msg, typeof(pos), typeof(diff));
    import std.typecons: tuple;
    return tuple(pos[0] + diff[0], pos[1] + diff[1]);
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : filter, fold, joiner, map, sum, cartesianProduct;
    import std.typecons: tuple;
    import std.range: iota, array;

    auto x0 = cast(int) inputLines.length;
    auto x1 = cast(int) inputLines[0].length;
    auto allPos = iota(x0).cartesianProduct(iota(x1));

    auto allCounts = allPos.map!((pos) {
        auto startingPos = DIRS.map!((dir)=> tuple(pos, dir)).array;
        auto res = XMAS.fold!((candidatePos, letter){
            auto validPos = candidatePos.filter!((posDir) {
                auto pos = posDir[0];
                return 0 <= pos[0] && pos[0] < x0 && 0 <= pos[1] && pos[1] < x1;
            });
            auto matchingPos = validPos.filter!((posDir) {
                auto pos = posDir[0];
                return letter == inputLines[pos[0]][pos[1]];
            });
            return matchingPos.map!((posDir) {
                return tuple(nextStep(posDir.expand), posDir[1]);
            }).array;

        })(startingPos);
        return res.length;
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