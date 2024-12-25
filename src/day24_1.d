module day24_1_final;

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

import std.typecons: Tuple;
alias Oper = Tuple!(string, "lhs", string, "rhs", string, "op", string, "res");


auto eval(String)(String op, String lhs, String rhs) {
    import std.algorithm: sort;
    import std.array: join;
    import std.range:  only;
    auto args = [lhs, rhs].sort;
    return Oper(args[0], args[1], op, only(op, args[0], args[1]).join(""));
}

auto eval(String)(String op, Oper lhs, Oper rhs) {
    return eval(op, lhs.res, rhs.res);
}

auto literal(String)(String s) {
    return Oper("", s, "", s);
}
auto getAdder(int numBits) {
    import std.conv: to;
    import std.format: formattedWrite;
    import std.array: appender, assocArray, byPair;
    import std.algorithm: filter;
    import std.typecons: tuple;

    Oper[string] values;
    bool[Oper] allExpressions;
    string cNext;
    foreach(i; 0..numBits) {
        auto writer1 = appender!string;
        formattedWrite(writer1, "%02d", i);
        auto suffix = writer1[];
        auto x = "x"~suffix;
        auto y = "y"~suffix;
        allExpressions[literal(x)] = true;
        allExpressions[literal(y)] = true;
        values[x] = literal(x);
        values[y] = literal(y);
        auto xXorY = eval("XOR", values[x], values[y]);
        allExpressions[xXorY] = true;
        auto xAndY = eval("AND", values[x], values[y]);
        allExpressions[xAndY] = true;
        auto z = "z" ~ suffix;
        cNext = "c" ~ suffix;
        if (i == 0) {
            values[z] = xXorY;
            values[cNext] = xAndY;
            continue;
        }

        auto writer2 = appender!string;
        formattedWrite(writer2, "%02d", i - 1);
        auto suffixPrev = writer2[];
        auto c = "c"~suffixPrev;
        auto cXorxXorY = eval("XOR", values[c], xXorY);
        allExpressions[cXorxXorY] = true;
        auto cAndxXorY = eval("AND", values[c], xXorY);
        allExpressions[cAndxXorY] = true;
        auto cNextExpr = eval("OR", cAndxXorY, xAndY);
        allExpressions[cNextExpr] = true;
        values[z] = cXorxXorY;
        values[cNext] = cNextExpr;
    }
    auto zExpressions = values.byPair.filter!(a => a.key[0] == 'z').assocArray;
    return tuple(allExpressions, zExpressions);
}

auto solve(Inits, Ops)(Inits inits, Ops ops)
{
    import std.algorithm: chunkBy, filter, fold, map, joiner, sort;
    import std.array: array, assocArray;
    import std.conv: to;
    import std.range: chain, front, enumerate, only, popFront;
    import std.typecons: tuple;

    auto values = inits.map!(a=>tuple(a[0], literal(a[0]))).assocArray;
    auto revValues = inits.map!(a=>tuple(literal(a[0]), a[0])).assocArray;
    auto opsMap = ops.map!(a => only(tuple(a.lhs, a), tuple(a.rhs, a)))
                     .joiner.array.sort
                     .chunkBy!(a => a[0])
                     .map!(a => tuple(a[0], a[1].map!(b => b[1]).array))
                     .assocArray
                     ;

    auto toVisit = values.keys;
    auto expectedAndZExprs = getAdder(45);
    auto expected = expectedAndZExprs[0];
    auto zExpressions = expectedAndZExprs[1];
    bool[string] outOfPlace;
    auto findCandidates = (Oper oper) {
        import std.algorithm: filter;
        return expected.byKey.filter!(a => a.lhs == oper.res || a.rhs == oper.res);
    };

    while(toVisit.length > 0) {
        auto curr = toVisit.front;
        toVisit.popFront;
        auto deps = curr in opsMap;
        if (!deps) {
            continue;
        }
        foreach(dep; *deps) {
            auto lhsVal = dep.lhs in values;
            auto rhsVal = dep.rhs in values;
            if (lhsVal && rhsVal) {
                auto resVal = eval(dep.op, *lhsVal, *rhsVal);
                if (resVal !in expected) {
                    auto lhsCandidates = findCandidates(*lhsVal);
                    auto rhsCandidates = findCandidates(*rhsVal);
                    auto candidates = lhsCandidates.chain(rhsCandidates)
                                      .filter!(a => a.op == dep.op).array;
                    assert(candidates.length == 1);
                    auto candidate = candidates[0];
                    resVal = candidate;
                    auto offending = only(*lhsVal, *rhsVal)
                            .filter!(a => a.res != resVal.lhs && a.res != resVal.rhs)
                            .array
                            ;
                    assert(offending.length == 1);
                    outOfPlace[revValues[offending[0]]] = true;
                }
                values[dep.res] = resVal;
                revValues[resVal] = dep.res;
                toVisit ~= dep.res;
            }
        }
    }

    foreach(zKey, zVal; zExpressions) {
        if (zVal != values[zKey]) {
            outOfPlace[zKey] = true;
        }
    }

    return outOfPlace.keys.sort.joiner(",");
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
    auto inits = inputLines.front.parseInits;
    auto operations = inputLines.dropOne.front.parseOperations;

    auto ret = solve(inits, operations);
    writeln(ret);
    return 0;
}
