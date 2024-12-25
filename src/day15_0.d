module day15_0;

import std.typecons: tuple;

static immutable DIRS = ['v': tuple(1, 0), '^': tuple(-1, 0), '>': tuple(0, 1), '<': tuple(0, -1)];

auto add(CoordL, CoordR, NUM)(CoordL left, CoordR right, NUM mul = 1) {
    auto ret = CoordL(left[0] + mul * right[0], left[1] + mul * right[1]);
    return ret;
}

auto sub(CoordL, CoordR, NUM)(CoordL left, CoordR right, NUM mul = 1) {
    return  add(left, CoordR(- right[0], - right[1]), mul);
}

auto parseData(InputStream)(InputStream inputLines)
{
    import std.algorithm : group, map, joiner;

    return inputLines.joiner.group;
}

const char WALL = '#';
const char SPACE = '.';
const char BLOCK = 'O';

auto solve(Grid, InputData)(Grid grid, InputData inputData)
{
    import std.algorithm: filter, find, joiner, map, sum, swap;
    import std.range: enumerate;

    auto labelledGrid = grid.map!(a => a.enumerate)
        .enumerate.map!(a => a[1].map!(b => tuple(tuple(a[0], b[0]), b[1])))
        .joiner;

    auto start = labelledGrid
        .find!(a => a[1] == '@').front[0];

    foreach(dirSteps; inputData) {
        auto steps = dirSteps[1];
        auto dir = DIRS[cast(char)dirSteps[0]];
        int spaces = 0;
        auto next = start;
        int moved = 0;
        next = next.add(dir);
        
        while(spaces != steps && grid[next[0]][next[1]] != WALL) {
            spaces += grid[next[0]][next[1]] == SPACE;
            moved += 1;
            next = next.add(dir);
        }
        if (spaces == 0) {
            continue;
        }

        auto fillPoint = next = sub(next, dir);
        while ( moved >= 0 )
        {
            auto isSpace = grid[next[0]][next[1]] == SPACE;
            if (!isSpace) {
                swap(cast(char) grid[next[0]][next[1]], cast(char) grid[fillPoint[0]][fillPoint[1]]);  
                next = sub(next, dir);
                fillPoint = sub(fillPoint, dir);
            }
            else {
                next = sub(next, dir);
            }
            moved -= 1;
        }
        start = fillPoint.add(dir);
    }

    return labelledGrid
            .filter!(a=> a[1] == BLOCK)
            .map!(a=> a[0][1] + a[0][0] * 100)
            .sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: splitter;
    import std.range: dropOne;
    import std.array: array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto grid = inputLines.front.array;
    auto inputData = inputLines.dropOne.front.parseData;
    auto ret = solve(grid, inputData);
    import std; grid.each!(line => line.writeln);
    writeln(ret);
    return 0;
}

