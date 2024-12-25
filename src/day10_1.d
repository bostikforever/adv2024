module day10_1;

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
    import std.algorithm : each, filter, map, sum;
    import std.range: enumerate, iota;

    auto rowLength = cast(int) input[0];
    auto gridLevels = input[1];
    int[][10] gridCellsByLevel;

    foreach(idx, level; gridLevels.enumerate) {
        gridCellsByLevel[level] ~= cast(int)idx;
    }

    // I know this is prob guaranteed to just be rowLength ^^ 2;
    auto gridLength = gridCellsByLevel[].map!(a=>a.length).sum;

    auto gridCounts = new int[gridLength];

    foreach(cell; gridCellsByLevel[9]) {
        gridCounts[cell] = 1;
    }

    foreach(level; iota(9, -1, -1)) {
        auto cells = gridCellsByLevel[level];
        foreach(cell; cells) {
            auto cellCount = gridCounts[cell]; 
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
                gridCounts[a] += cellCount;
            });
        }
    }

    long res = gridCellsByLevel[0].map!(a => gridCounts[a]).sum;
    return res;
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