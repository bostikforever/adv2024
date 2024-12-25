module day12_1;

import std.range : only;

enum DIRS = only('R', 'D');

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : map, splitter;
    import std.conv : to;

    auto lineNums = inputLine.splitter("").map!(a => a.to!char);
    return lineNums;
}

auto parseInput(InputLines)(InputLines inputLines)
{

    import std.algorithm : map;
    import std.array : join;
    import std.typecons : tuple;

    auto numLines = inputLines.front.length;
    auto gridAsLine = inputLines.map!parseLine.join;
    return tuple(numLines, gridAsLine);
}

auto solve(Input)(Input input)
{
    import std.algorithm : each, filter, map, sort, sum, uniq;
    import std.array: array;
    import std.range : iota, zip;

    auto rowLength = cast(int) input[0];
    auto gridColors = input[1];
    auto gridLength = gridColors.length;

    auto gridParent = new ulong[gridLength];
    auto gridArea = new long[gridLength];

    foreach (i; 0 .. gridLength)
    {
        gridParent[i] = i;
        gridArea[i] = 1;
    }

    ulong findParent(ulong x)
    {
        ulong y = x;

        while (gridParent[y] != y)
            y = gridParent[y];

        while (gridParent[x] != x)
        {
            ulong z = gridParent[x];
            gridParent[x] = y;
            x = z;
        }

        return y;
    }

    foreach (i, color; gridColors)
    {        
        auto cellIdx = cast(int) i;
        auto neighbors = DIRS.map!((a) {
            final switch (a)
            {
            case 'R':
                return cellIdx % rowLength == rowLength - 1 ? -1 : cellIdx + 1;
            case 'D':
                return cellIdx + rowLength >= gridLength ? -1 : cellIdx + rowLength;
            }
        }).zip(DIRS).filter!(a => a[0] != -1);
        auto neighborsMatch = neighbors.filter!(a => gridColors[a[0]] == color);
        neighborsMatch.each!((j, dir) {
            auto iParent = findParent(i);
            final switch (dir)
            {
            case 'R':
                auto jParent = findParent(j);
                if (iParent != jParent) {
                    gridArea[jParent] = gridArea[iParent] += gridArea[jParent];
                }
                gridParent[jParent] = iParent;
                break;
            case 'D':
                gridArea[j] = gridArea[iParent] += 1;
                gridParent[j] = iParent;
                break;
            }
        });
    }
    long[ulong] gridSides;

    foreach(long col; 0..rowLength) {
        auto leftEdge = false;
        auto rightEdge = false;
        auto prevParent = col;
        foreach(i; iota(col, gridLength, rowLength)) {
            auto iParent = findParent(i);
            auto currLeftEdge = i % rowLength == 0 ? true : findParent(i-1) != iParent;
            auto currRightEdge = i % rowLength == rowLength - 1 ? true : findParent(i+1) != iParent;

            auto changedRegion = prevParent != iParent;
            gridSides[iParent] += (changedRegion || !leftEdge) && currLeftEdge;
            gridSides[iParent] += (changedRegion || !rightEdge) && currRightEdge;
            leftEdge = currLeftEdge;
            rightEdge = currRightEdge;
            prevParent = iParent;
        }
    }
    foreach(row; iota(0, gridLength, rowLength)) {
        auto topEdge = false;
        auto bottomEdge = false;
        auto prevParent = row;
        foreach(long i; row..row + rowLength) {
            auto iParent = findParent(i);
            auto currTopEdge = i - rowLength < 0  ? true : findParent(i-rowLength) != iParent;
            auto currBottomEdge = i + rowLength >= gridLength ? true : findParent(i+rowLength) != iParent;

            auto changedRegion = prevParent != iParent;
            gridSides[iParent] += (changedRegion || !topEdge) && currTopEdge;
            gridSides[iParent] += (changedRegion || !bottomEdge) && currBottomEdge;
            topEdge = currTopEdge;
            bottomEdge = currBottomEdge;
            prevParent = iParent;
        }
    }
    auto res = iota(0, gridLength)
                    .map!findParent
                    .array
                    .sort
                    .uniq
                    .map!(a=>gridArea[a] * gridSides[a]).sum(0L);
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
