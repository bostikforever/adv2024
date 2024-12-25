module day6_1;
import std.typecons: Tuple;
alias Dir = Tuple!(int, int);
static immutable DIR  = ['^', '>', 'v', '<'];

auto parseLine(InputLine)(InputLine inputLine) {
    import std.algorithm: filter, map;
    import std.range: enumerate;
    import std.string: indexOf;
    import std.typecons: tuple;
    import std.array: array;

    auto guardIdx = tuple(-1, -1);
    auto obstacles = inputLine.enumerate.filter!((a) {
        auto ch = cast(char) a[1];
        // hacky filter should not have side effect
        auto idxGuard = DIR.indexOf(ch);
        if (idxGuard != -1) {
            guardIdx = tuple(cast(int) idxGuard, cast(int) a[0]);
        }
        return ch == '#';
    }).map!(a => cast(int) a[0]).array;

    return tuple(obstacles, guardIdx);
}

auto parseInput(InputLines)(InputLines inputLines) {
    import std.algorithm: each, map;
    import std.range: enumerate, repeat;
    import std.typecons: tuple, Tuple;
    import std.array: array;

    int numColumns = cast(int) inputLines.front.length;
    auto columnView = (cast(int[]) []).repeat(numColumns).array;

    alias Pos = Tuple!(int, int);
    auto guardPos = tuple(-1, Pos(-1, -1));
    auto rowView = inputLines.map!parseLine.enumerate.map!((a) {
        auto idx = a[0];
        auto obsGuard = a[1];
        if (guardPos[0] == -1) {
            auto guard = obsGuard[1];
            guardPos = tuple(guard[0], Pos(cast(int) idx, guard[1]));
        }
        return obsGuard[0];
    }).array;
    rowView.enumerate.each!((idx, a) {
        a.each!((b) {
            columnView[b].assumeSafeAppend ~= cast(int) idx;
        });
    });

    return tuple(tuple(rowView, columnView), guardPos);
}

auto eval(Obstacles, GuardPos)(Obstacles obstacles, GuardPos guardPos) {
    import std.range: assumeSorted;
    import std.typecons: tuple, Tuple;

    auto rowView = obstacles[0];
    auto columnView = obstacles[1];
    alias Pos = Tuple!(int, int);
    bool loops = false;
    int[Pos] res;

  outer:
    while(true) {
        typeof(rowView[0]) view;
        typeof(view.assumeSorted.trisect(0)) triRes;
        auto guardDir = DIR[guardPos[0]];
        int* idx;
        int viewIdx;
        typeof(rowView) viewArr;
        final switch(guardDir) {
            case '>':
                goto case;
            case '<':
                idx = &guardPos[1][1];
                viewArr = rowView;
                viewIdx = guardPos[1][0];
                view = viewArr[viewIdx];
                triRes = view.assumeSorted.trisect(*idx);
                break;
            case '^':
                goto case;
            case 'v':
                idx = &guardPos[1][0];
                viewArr = columnView;
                viewIdx = guardPos[1][1];
                view = viewArr[viewIdx];
                triRes = view.assumeSorted.trisect(*idx);
                break;
        }
        final switch(guardDir) {
            case '>':
                goto case;
            case 'v':
                auto found = triRes[2];
                auto nextIdx = found.empty ? cast(int) viewArr.length - 1: found.front - 1;
                while(*idx != nextIdx) {
                    *idx+=1;
                    auto mask = 1 << 1 << guardPos[0];
                    loops = cast(bool)(res.require(guardPos[1], 0) & mask);
                    res[guardPos[1]] |= mask;
                }
                if (found.empty || loops) {
                    break outer;
                }
                break;
            case '^':
                goto case;
            case '<':
                auto found = triRes[0];
                auto nextIdx = found.empty ? 0 : found.back + 1;
                while(*idx != nextIdx) {
                    *idx -= 1;
                    auto mask = 1 << 1 << guardPos[0];
                    loops = cast(bool)(res.require(guardPos[1], 0) & mask);
                    res[guardPos[1]] |= mask;
                }
                if (found.empty || loops) {
                    break outer;
                }
                break;
        }
        guardPos[0] = (guardPos[0] + 1) % DIR.length;
    }
    return tuple(res, loops);
}


auto solve(Obstacles, GuardPos)(Obstacles obstacles, GuardPos guardPos) {
    import std.algorithm: sort;
    import std.typecons: tuple;

    auto trajectory = obstacles.eval(guardPos)[0];
    int res = 0;
    foreach(pos; trajectory.byKey) {
        auto rowView = obstacles[0].dup;
        auto colView = obstacles[1].dup;
        rowView[pos[0]] = (rowView[pos[0]] ~ pos[1]).sort.release;
        colView[pos[1]] = (colView[pos[1]] ~ pos[0]).sort.release;
        res += guardPos[1] != pos && tuple(rowView, colView).eval(guardPos)[1];
    }
    return res;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine;
    auto inputData = inputLines.parseInput;
    auto obstacles = inputData[0];
    auto guardStart = inputData[1];
    auto ret = solve(obstacles, guardStart);
    writeln(ret);
    return 0;
}

