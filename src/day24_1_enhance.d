module day24_1_enhance;

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

struct EvaledOp {
    string lhs, rhs, op, res;
}

auto eval(String)(String op, String lhs, String rhs) {
    import std.algorithm: sort;
    import std.array: join;
    import std.range: only;

    String[2] args = [lhs, rhs];
    args[].sort;
    return EvaledOp(args[0], args[1], op, only(op, args[0], args[1]).join(""));
}

auto eval(String)(String op, EvaledOp lhs, EvaledOp rhs) {
    return eval(op, lhs.res, rhs.res);
}

auto literal(String)(String s) {
    return EvaledOp("", s, "", s);
}

struct Var {
    static auto opDispatch(string base)(int num) {
        import std.array: appender;
        import std.format: formattedWrite;

        auto writer = appender!string;
        formattedWrite(writer, "%s%02d", base, num);
        return writer[];
    }
}

auto getAdder(int numBits) {
    import std.array: assocArray, byPair;
    import std.algorithm: filter;
    import std.typecons: tuple;

    EvaledOp[string] values;
    bool[EvaledOp] allExpressions;
    string cNext;
    foreach(i; 0..numBits) {
        auto x = Var.x(i);
        auto xVal = literal(x);
        allExpressions[xVal] = true;

        auto y = Var.y(i);
        auto yVal = literal(y);
        allExpressions[yVal] = true;

        auto xXorY = eval("XOR", xVal, yVal);
        allExpressions[xXorY] = true;

        auto xAndY = eval("AND", xVal, yVal);
        allExpressions[xAndY] = true;

        auto z = Var.z(i);
        cNext = Var.c(i);
        if (i == 0) {
            values[z] = xXorY;
            values[cNext] = xAndY;
            continue;
        }
        auto c = Var.c(i - 1);
        auto cVal = values[c];

        auto cXorxXorY = eval("XOR", cVal, xXorY);
        allExpressions[cXorxXorY] = true;
        values[z] = cXorxXorY;

        auto cAndxXorY = eval("AND", cVal, xXorY);
        allExpressions[cAndxXorY] = true;

        auto cNextExpr = eval("OR", cAndxXorY, xAndY);
        allExpressions[cNextExpr] = true;
        values[cNext] = cNextExpr;
    }

    values[Var.z(numBits)] = values[cNext];
    auto zExpressions = values.byPair.filter!(a => a.key[0] == 'z').assocArray;
    return tuple(allExpressions, zExpressions);
}

auto solve(Inits, Ops)(Inits inits, Ops ops)
{
    import std.algorithm: chunkBy, filter, map, joiner, sort;
    import std.array: array, assocArray;
    import std.range: chain, front, only, popFront;
    import std.typecons: tuple;

    auto values = inits.map!(a=>tuple(a.var, literal(a.var))).assocArray;
    auto revValues = inits.map!(a=>tuple(literal(a.var), a.var)).assocArray;
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
    auto findCandidates = (EvaledOp oper) {
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
            if (dep.res in values) {
                continue;
            }
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
                    resVal = candidates[0];
                    auto offending = only(*lhsVal, *rhsVal)
                            .filter!(a => a.res != resVal.lhs && a.res != resVal.rhs)
                            .array
                            ;
                    assert(offending.length == 1);
                    outOfPlace[revValues[offending[0]]] = true;
                }
                values[dep.res] = resVal;
                revValues[resVal] = dep.res;
                toVisit.assumeSafeAppend ~= dep.res;
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
