module day21_0_really_bad;

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

auto getAllMoves(StatePair, States, Trans)(StatePair pair, States states, Trans trans)
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
    auto protoMoves  = [yMove.repeat(ySteps).chain(xMove.repeat(xSteps)),
                      xMove.repeat(xSteps).chain(yMove.repeat(ySteps))];
    
    byte[][] allMoves;
    foreach(protoMove; protoMoves) {
        if(!hasBlank(start, protoMove, trans)) {
            allMoves ~= cast(byte[])protoMove.array.dup;
        }
    }
    return allMoves;
}

enum MAX_ROBOTS = 2;
long getBestDirMoves(InputLine, States, Trans)(int i, InputLine inputLine, States states, Trans trans)
{
    import std.algorithm: map, minElement, sum;
    import std.array: array;
    import std.range: chain, front, dropOne, only, slide;
    import std.typecons: tuple; 
    
    return only('A').chain(inputLine).slide(2)
                        .map!((val) {
                            auto a = val.front;
                            auto b = val.dropOne.front;
                            auto allMoves = tuple(a, b).getAllMoves(states, trans);
                            auto allMovesA = allMoves.map!(a => a ~ [cast(byte)'A']).array;
                            if(i == MAX_ROBOTS - 1) {
                                return allMovesA.map!(a=>a.length).minElement;
                            }
                            return allMovesA.map!(a => (i+1).getBestDirMoves(a, states, trans))
                                .minElement;
                        }).sum;

}
auto getBestBaseMoves(InputLine, States, Trans)(InputLine inputLine, States states, Trans trans)
{
    import std.algorithm: map, minElement, sum;
    import std.array: array;
    import std.range: chain, front, dropOne, only, slide;
    import std.typecons: tuple; 
    
    return only('A').chain(inputLine).slide(2)
                        .map!((val) {
                            auto a = val.front;
                            auto b = val.dropOne.front;
                            auto allMoves = tuple(a, b).getAllMoves(states, trans);
                            auto allMovesA = allMoves.map!(a => a ~ [cast(byte)'A']).array;
                            return allMovesA.map!(a => 0.getBestDirMoves(a, dirKeypad, dirKeypadRev))
                                .minElement;
                        }).sum;

}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm: map, sum, joiner, sort, uniq;
    import std.array: join;
    
    import std.range: zip;
    import std.conv: parse;

    return inputLine
                .getBestBaseMoves(numericKeypad, numericKeypadRev)
                // human
                ;
}

auto solve(InputLines)(InputLines inputLines) {

    import std.algorithm: map, minElement, sum, joiner;
    import std.range: zip;
    import std.conv: parse;
    import std.array: array;

    return inputLines
                .map!solveLine
                .zip(inputLines.map!(a => a.parse!int))
                .map!(a => a[0] * a[1])
                .sum
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