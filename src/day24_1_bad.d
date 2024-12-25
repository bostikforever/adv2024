module day24_1;

auto parseInit(InputLine)(InputLine inputLine)
{
    import std.format: formattedRead;
    import std.typecons: Tuple;

    alias Init = Tuple!(string, "var", bool, "val");
    Init init;
    inputLine.formattedRead("%s: %b", init.var, init.val);
    return init;
}

auto parseInits(InputLines)(InputLines inputLines)
{
    import std.algorithm: map;

    return inputLines.map!parseInit;
}

auto parseOperation(InputLine)(InputLine inputLine)
{
    import std.format: formattedRead;
    import std.typecons: Tuple;

    alias Operation = Tuple!(string, "lhs", string, "rhs", string, "op", string, "res");
    Operation op;
    inputLine.formattedRead("%s %s %s -> %s", op.lhs, op.op, op.rhs, op.res);
    return op;
}

auto parseOperations(InputLines)(InputLines inputLines)
{
    import std.algorithm: map;

    return inputLines.map!parseOperation;
}

auto solveSingle(Tokens, Line)(Tokens tokens, Line line)
{
    import std.algorithm : map, sort, uniq;
    import std.array: array, assocArray;

    import std.range: iota, repeat, retro;

    auto tokenLengths = tokens.map!(a=>a.length).array.sort.uniq;
    auto tokensSet = tokens.assocArray(repeat(true));
    bool[] valids = new bool[line.length + 1];
    valids[line.length] = true;
    foreach(begin; iota(0, line.length).retro) {
        foreach(tokenLength; tokenLengths) {
            auto end = begin + tokenLength;
            if (end > line.length) {
                continue;
            }
            auto frag = line[begin..end];
            if (frag !in tokensSet) {
                continue;
            }
            valids[begin] = true && valids[end];
            if (valids[begin]) {
                break;
            }
        }
    }
    return valids[0];
}

auto solveSingle(Inits, Ops, Swaps)(Inits inits, Ops ops, Swaps swaps)
{
    import std.algorithm: chunkBy, filter, fold, joiner, map, sort;
    import std.array: array, assocArray;
    import std.conv: to;
    import std.range: back, only, popBack;
    import std.typecons: tuple;

    auto values = inits.assocArray;
    auto opsMap = ops.map!(a => only(tuple(a.lhs, a), tuple(a.rhs, a)))
                     .joiner.array.sort
                     .chunkBy!(a => a[0])
                     .map!(a => tuple(a[0], a[1].map!(b => b[1]).array))
                     .assocArray
                     ;

    auto toVisit = values.keys;

    auto swapMap = swaps.map!(a => only(a, tuple(a[1], a[0]))).joiner.assocArray;

    while(toVisit.length > 0) {
        auto curr = toVisit.back;
        toVisit.popBack;
        auto deps = curr in opsMap;
        if (!deps) {
            continue;
        }
        foreach(dep; *deps) {
            auto lhsVal = dep.lhs in values;
            auto rhsVal = dep.rhs in values;
            if (lhsVal && rhsVal) {
                bool resVal;
                final switch(dep.op) {
                    case "XOR":
                        resVal = *lhsVal ^ *rhsVal;
                        break;
                    case "OR":
                        resVal = *lhsVal | *rhsVal;
                        break;
                    case "AND":
                        resVal = *lhsVal & *rhsVal;
                        break;
                }
                auto swapRes = dep.res in swapMap;
                auto res = swapRes ? *swapRes : dep.res;
                values[res] = resVal;
                toVisit ~= res;
            }
        }
    }

    auto readVal = (char label) {
        auto vals = values.byKeyValue.filter!(a=>a.key[0] == label)
                                    .map!(a => tuple(a.key[1..$].to!int, a.value))
                                    .array
                                    .sort;
        auto val = vals.fold!((a, b) => a | 1L * b[1] << b[0])(0L);
        return val;
    };
    auto xVal = readVal('x');
    auto yVal = readVal('y');
    auto zVal = readVal('z');
    return xVal + yVal == zVal;
}

auto solve(Inits, Ops)(Inits inits, Ops ops)
{
    import std.algorithm: all, cartesianProduct, filter, map, sort, joiner;
    import std.range: enumerate, slide, only;
    import std.array: array, join;

    auto resArr = ops.map!(a => a.res).array.sort;
    auto resPairs = resArr.cartesianProduct(resArr).filter!(a => a[0] < a[1]).array;

    auto allPairs = cartesianProduct(
            resPairs.enumerate,
            resPairs.enumerate,
            resPairs.enumerate,
            resPairs.enumerate,
    ).filter!((a) {
        auto pairsPairsOrdered = only(a.expand).slide(2).all!(b => b[0][0] < b[1][0]);
        return pairsPairsOrdered;
    }).map!(a=>only(a.expand).map!(b=>b[1]));

    foreach(swaps; allPairs) {
        auto res = solveSingle(inits, ops, swaps);
        if (res) {
            return swaps.map!(a => only(a.expand)).join.sort.joiner(",");
        }
    }
    assert(false);
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: splitter;
    import std.range: dropOne;
    import std.array: array, front;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto inits = inputLines.front.parseInits.array;
    auto operations = inputLines.dropOne.front.parseOperations.array;

    auto ret = solve(inits, operations);
    writeln(ret);
    return 0;
}