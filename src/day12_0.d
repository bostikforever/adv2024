module day12_0;

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
    auto gridPerimeter = new long[gridLength];
    auto gridArea = new long[gridLength];

    foreach (i; 0 .. gridLength)
    {
        gridParent[i] = i;
        gridPerimeter[i] = 4;
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
                gridPerimeter[iParent] -= 1;
                gridPerimeter[jParent] -= 1;
                if (iParent != jParent) {
                    gridArea[jParent] = gridArea[iParent] += gridArea[jParent];
                    gridPerimeter[jParent] = gridPerimeter[iParent] += gridPerimeter[jParent];
                }
                gridParent[jParent] = iParent;
                break;
            case 'D':
                gridArea[j] = gridArea[iParent] += 1;
                gridPerimeter[j] = gridPerimeter[iParent] += gridPerimeter[j] - 2;
                gridParent[j] = iParent;
                break;
            }
        });
    }
    auto res = iota(0, gridLength)
                    .map!findParent
                    .array
                    .sort
                    .uniq
                    .map!(a=>gridArea[a] * gridPerimeter[a]).sum(0L);
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
