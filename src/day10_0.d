module day10_0;

import std.range: only;


enum DIRS = only('L', 'R', 'U', 'D');

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter("").map!(a => a.to!int);
    return lineNums;
}

auto parseInput(InputLines)(InputLines inputLines)
{

    import std.algorithm : map;
    import std.array: join;
    import std.typecons: tuple;

    auto numLines = inputLines.front.length;
    auto gridAsLine = inputLines.map!parseLine.join;
    return tuple(numLines, gridAsLine);
}

auto solve(Input)(Input input)
{
    import std.algorithm : each, filter, map, sort, sum, uniq;
    import std.range: dropOne, empty, enumerate, iota, retro, stride;
    import std.typecons: tuple;

    auto rowLength = cast(int) input[0];
    auto gridLevels = input[1];
    int[][10] gridCellsByLevel;

    foreach(idx, level; gridLevels.enumerate) {
        gridCellsByLevel[level] ~= cast(int)idx;
    }

    // I know this is prob guaranteed to just be rowLength ^^ 2;
    auto gridLength = gridCellsByLevel[].map!(a=>a.length).sum;

    auto gridScore = new bool[int][gridLength];

    foreach(i, level; gridLevels) {
        if (level == 9) {
            gridScore[i] = [cast(int)i: true];
        }
        else {
            gridScore[i] = new bool[int];
        }
    }

    foreach(level; iota(9, -1, -1)) {
        auto cells = gridCellsByLevel[level];
        foreach(cell; cells) {
            auto cellScore = gridScore[cell]; 
            auto neighbors = DIRS.map!((a) {
                final switch(a) {
                    case 'L':
                        return cell % rowLength == 0 ? -1 : cell - 1;
                    case 'R':
                        return cell % rowLength == rowLength - 1 ? -1 : cell + 1;
                    case 'U':
                        return cell - rowLength < 0 ? -1 : cell - rowLength;
                    case 'D':
                        return cell + rowLength >= gridLength ? -1 : cell + rowLength;
                }
            }).filter!(a=> a != -1);
            auto neighborsNextLevel = neighbors.filter!(a => gridLevels[a] == level - 1);
            neighborsNextLevel.each!((a) {
                auto neighborCellScore = gridScore[a];
                cellScore.byKey.each!((score) {
                    neighborCellScore[score] = true;
                });
            });
        }
    }

    return gridCellsByLevel[0].map!(a=>gridScore[a].length).sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputData = inputFile.byLine.parseInput;
    immutable ret = solve(inputData);
    writeln(ret);
    return 0;
}