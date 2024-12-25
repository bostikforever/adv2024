module day21_0.bak;

import std.typecons: Tuple;
alias Coord = Tuple!(int, "x", int, "y");

// +---+---+---+
// | 7 | 8 | 9 |
// +---+---+---+
// | 4 | 5 | 6 |
// +---+---+---+
// | 1 | 2 | 3 |
// +---+---+---+
//     | 0 | A |
//     +---+---+

import std.range: zip;
import std.array: assocArray;
static immutable Coord[dchar] numericKeypad = [
                              '7': Coord(0, 0), '8': Coord(1, 0), '9': Coord(2, 0), 
                              '4': Coord(0, 1), '5': Coord(1, 1), '6': Coord(2, 1), 
                              '1': Coord(0, 2), '2': Coord(1, 2), '3': Coord(2, 2), 
                              ' ': Coord(0, 3), '0': Coord(1, 3), 'A': Coord(2, 3), 
                             ];
static immutable numericKeypadRev = numericKeypad.values
                                        .zip(numericKeypad.keys)
                                        .assocArray;
// v<<A>>^AvA^Av<<A>>^AAv<A<A>>^AAvAA^<A>Av<A>^AA<A>Av<A<A>>^AAAvA^<A>A
// <A>A<A
// <v<A>>^AvA^A<vA<AA>>^AAvA<^A>AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A
// <A>Av
//     +---+---+
//     | ^ | A |
// +---+---+---+
// | < | v | > |
// +---+---+---+

static immutable Coord[dchar] dirKeypad = [
                          ' ': Coord(0, 0), '^': Coord(1, 0), 'A': Coord(2, 0), 
                          '<': Coord(0, 1), 'v': Coord(1, 1), '>': Coord(2, 1), 
                          ];
static immutable dirKeypadRev = dirKeypad.values
                                        .zip(dirKeypad.keys)
                                        .assocArray;

auto toMoves(Keypad, String)(String str, Keypad keypad) {
    import std.algorithm: find;
    import std.range: enumerate, front;
    char[] ret;
    auto startAIdx = keypad.keys.length - keypad.keys.find!(a => a == 'A').length;
    Coord pos = keypad.values[startAIdx];
    foreach(ch; str) {
        final switch(ch) {
            case '^':
                pos = Coord(pos.x, pos.y - 1);
                break;
            case 'v':
                pos = Coord(pos.x, pos.y + 1);
                break;
            case '>':
                pos = Coord(pos.x + 1, pos.y);
                break;
            case '<':
                pos = Coord(pos.x - 1, pos.y);
                break;
            case 'A':
                auto idx = keypad.values.length - keypad.values.find!(a => a == pos).length;
                ret ~= keypad.keys[idx];
                break;
        }
    }
    return ret;
}
auto backwards(String)(String str) {
    String[4] res;
    res[0] = str;
    foreach(i; 1..3) {
        res[i]= res[i-1].toMoves(dirKeypad);
    }
    res[3] = res[2].toMoves(numericKeypad);
    return res;
}
pragma(msg, "v<<A>>^AvA^Av<<A>>^AAv<A<A>>^AAvAA^<A>Av<A>^AA<A>Av<A<A>>^AAAvA^<A>A".backwards);
pragma(msg, "<v<A>>^AvA^A<vA<AA>>^AAvA<^A>AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A".backwards);
pragma(msg, "<<vAA>A^>AA<Av>A^AAvA^A<vA^>A<A>A<vA^>A<A>A<<vA>A^>AA<Av>A^A".backwards);
auto diffAndMoves(Coord a, Coord b) {
    import std.range: chain, repeat;
    
    auto xDiff = b.x - a.x;
    auto yDiff = b.y - a.y;
    auto xMove = xDiff > 0 ? '>' : '<';
    auto xSteps = xDiff > 0 ? xDiff : -xDiff;
    auto yMove = yDiff > 0 ? 'v' : '^';
    auto ySteps = yDiff > 0 ? yDiff : -yDiff;
    if (xDiff > 0) {
    return yMove.repeat(ySteps).chain(xMove.repeat(xSteps));
    }
        return xMove.repeat(xSteps).chain(yMove.repeat(ySteps));
}

auto convertWithKeypad(InputLine, Keypad)(InputLine inputLine, Keypad keypad) {
    import std.algorithm: map;
    import std.array: join;
    import std.range: chain, dropOne, only, slide;

    auto moves = only('A').chain(inputLine).slide(2)
                        .map!((val) {
                            auto a = val.front;
                            auto b = val.dropOne.front;
                            auto aCoord = keypad[a];
                            auto bCoord = keypad[b];
                            auto moves = aCoord.diffAndMoves(bCoord).chain("A"); 
                            return moves;
                        }).join;
    return moves;

}

auto numericToDir(InputLine)(InputLine inputLine) {
    return inputLine.convertWithKeypad(numericKeypad);
}

auto dirToDir(InputLine)(InputLine inputLine) {
    return inputLine.convertWithKeypad(dirKeypad);
}

auto hasBlank(Moves, Start, Trans)(Start start, Moves moves, Trans trans) {
    import std.algorithm: any, cumulativeFold;
    auto allPos = moves.cumulativeFold!((pos, move){
        Coord res;
        final switch(move) {
            case '^':
                res = Coord(pos.x, pos.y - 1);
                break;
            case 'v':
                res = Coord(pos.x, pos.y + 1);
                break;
            case '>':
                res = Coord(pos.x + 1, pos.y);
                break;
            case '<':
                res = Coord(pos.x - 1, pos.y);
                break;
        }
        return res;
    })(start);
    return allPos.any!(a => trans[a] == ' ');
}
auto findOptimalPair(StatePair, States, Trans, Costs)(StatePair pair, States states, Trans trans, Costs costs)
{
    import std.algorithm: cartesianProduct, map, minElement, nextPermutation, sort;
    import std.range: chain, empty, repeat;
    import std.conv: to;
    import std.array: array, assocArray;
    auto start = states[pair[0]];
    auto end = states[pair[1]];
    
    auto xDiff = end.x - start.x;
    auto yDiff = end.y - start.y;
    auto xMove = xDiff > 0 ? '>' : '<';
    auto xSteps = xDiff > 0 ? xDiff : -xDiff;
    auto yMove = yDiff > 0 ? 'v' : '^';
    auto ySteps = yDiff > 0 ? yDiff : -yDiff;
    auto moves = cast(byte[]) yMove.repeat(ySteps).chain(xMove.repeat(xSteps))
                    .array;
                    moves
                    .sort;
    typeof(moves)[] allMoves;
    pragma(msg, typeof(moves), typeof(allMoves));
    bool hasNext = true;
    if(moves.empty) {
        return [];
    }
    while(hasNext) {
        if(!hasBlank(start, moves, trans)) {
            allMoves ~= moves.dup;
        }
        hasNext = moves.nextPermutation;
    }
    if(allMoves.empty) {
        return [];
    }
    
    auto optimalMove = allMoves.minElement!((a) {
        import std.algorithm: map, sum;
        import std.range: chain, only, slide;
        import std.math: abs;
        import std; a.writeln;
        return only('A').chain(a).slide(2).map!((fromTo) {
            auto from = costs[fromTo[0]];
            auto to = costs[fromTo[1]];
            return abs(from.x - to.x) + abs(from.y - to.y);
        }).sum;
    });
    return optimalMove;
}

auto findOptimal(States, Trans, Costs)(States states, Trans trans, Costs costs) {
    import std.algorithm: cartesianProduct, map;
    import std.typecons: tuple;
    import std.array: assocArray;

    return states.byKey.cartesianProduct(states.byKey).map!(a => tuple(a, 
        a.findOptimalPair(states, trans, costs)
    )).assocArray;
}

auto solve(InputLines)(InputLines inputLines) {

    import std.algorithm: map, sum;
    import std.range: zip;
    import std.conv: parse;

    auto numPairsOpt = numericKeypad.findOptimal(numericKeypadRev, dirKeypad);
    auto keyPairsOpt = dirKeypad.findOptimal(dirKeypadRev, dirKeypad);
    import std; numPairsOpt.writeln; keyPairsOpt.writeln;
    return inputLines
                // robot 1
                .map!numericToDir // robot 1
                // robot 2
                .map!dirToDir // robot 2
                // robot 3
                .map!dirToDir 
                // human
                .map!(a => a.length)
                .zip(inputLines.map!(a => a.parse!int))
                // .map!(a => a[0] * a[1])
                // .sum
                ;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.array: array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array;
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}