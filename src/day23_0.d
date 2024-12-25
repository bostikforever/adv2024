module day23_0.bak;

auto parseLine(InputLine)(InputLine inputLine) {
    import std.format: formattedRead;
    import std.typecons: tuple;

    string first, second;

    inputLine.formattedRead("%s-%s", first, second);
    return tuple(first, second);
}

auto solve(InputLines)(InputLines inputLines) {

    import std.algorithm: cartesianProduct, each, filter;
    import std.range: walkLength;

    alias Pair = typeof(inputLines[0]);

    bool[Pair] connected;
    bool[string] nodes;

    foreach(pair; inputLines) {
        nodes[pair[0]] = true;
        nodes[pair[1]] = true;
        connected[pair] = true;
        connected[Pair(pair[1], pair[0])] = true;
    }
    auto allNodes = nodes.keys;
    auto ts = allNodes.filter!(a => a[0] == 't');
    auto tsTriple = ts.cartesianProduct(allNodes, allNodes)
                                .filter!(a => a[1] < a[2]
                                && (a[1][0] != 't' || a[0] < a[1])
                                && (a[2][0] != 't' || a[0] < a[2]))
                                .filter!(a => Pair(a[0], a[1]) in connected &&
                                              Pair(a[1], a[2]) in connected &&
                                              Pair(a[2], a[0]) in connected)
                                ;
    bool[typeof(tsTriple.front)] uniq;
    tsTriple.each!(a => uniq[a] = true);
    return tsTriple.walkLength;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;
    import std.array: array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!parseLine.array;
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}