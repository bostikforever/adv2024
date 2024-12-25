module day24_0;

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

auto solve(Inits, Ops)(Inits inits, Ops ops)
{
    import std.algorithm: chunkBy, filter, fold, map, joiner, sort;
    import std.array: array, assocArray;
    import std.conv: to;
    import std.range: back, enumerate, only, popBack;
    import std.typecons: tuple;

    auto values = inits.assocArray;
    auto opsMap = ops.map!(a => only(tuple(a.lhs, a), tuple(a.rhs, a)))
                     .joiner.array.sort
                     .chunkBy!(a => a[0])
                     .map!(a => tuple(a[0], a[1].map!(b => b[1]).array))
                     .assocArray
                     ;

    auto toVisit = values.keys;

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
                values[dep.res] = resVal;
                toVisit ~= dep.res;
            }
        }
    }

    auto zVals = values.byKeyValue.filter!(a=>a.key[0] == 'z')
                                  .map!(a => tuple(a.key[1..$].to!int, a.value))
                                  .array
                                  .sort;
    auto zVal = zVals.fold!((a, b) => a | 1L * b[1] << b[0])(0L);
    return zVal;
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
