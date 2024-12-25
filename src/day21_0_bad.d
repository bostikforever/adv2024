module day21_0_bad;

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


auto convertWithMap(InputLine, MovesMap)(InputLine inputLine, MovesMap movesMap) {
    import std.algorithm: map;
    import std.array: join;
    import std.range: chain, dropOne, only, slide;
    import std.typecons: tuple;

    auto moves = only('A').chain(inputLine).slide(2)
                        .map!((val) {
                            auto a = val.front;
                            auto b = val.dropOne.front;
                            auto moves = cast(char[])movesMap[tuple(a, b)];
                            auto movesA = moves.chain("A"); 
                            return movesA;
                        }).join;
    return moves;

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
    import std.algorithm: minElement, nextPermutation, sort;
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
    auto ySteps = yDiff > 
    0 ? yDiff : -yDiff;
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
        return only('A').chain(a, only('A')).slide(2).map!((fromTo) {
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
    return inputLines
                // robot 1
                .map!(a => a.convertWithMap(numPairsOpt)) // robot 1
                // robot 2
                .map!(a => a.convertWithMap(keyPairsOpt)) // robot 2
                // robot 3
                .map!(a => a.convertWithMap(keyPairsOpt)) 
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