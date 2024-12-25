module day23_0;

auto parseLine(InputLine)(InputLine inputLine) {
    import std.format: formattedRead;
    import std.typecons: tuple;

    string first, second;

    inputLine.formattedRead("%s-%s", first, second);
    return tuple(first, second);
}

auto solve(InputLines)(InputLines inputLines) {

    import std.algorithm: all, cartesianProduct, filter, joiner, map, sort, uniq;
    import std.array: array;

    alias Pair = typeof(inputLines[0]);

    bool[Pair] connected;
    bool[string] nodes;

    foreach(pair; inputLines) {
        nodes[pair[0]] = true;
        nodes[pair[1]] = true;
        connected[pair] = true;
        connected[Pair(pair[1], pair[0])] = true;
    }
    auto doubles = connected.byKey
                            .filter!(a => a[0] < a[1])
                            .map!(a => [a.expand])
                            .array.sort.release
                            ;
    auto allNodes = nodes.keys;
    auto curr = doubles;
    typeof(curr) prev;

    while(curr.length > 0) {
        prev = curr;
        curr = allNodes.cartesianProduct(curr)
                        .filter!((a){
                            auto single = a[0];
                            auto rest = a[1];
                            return rest.all!(b => Pair(single, b) in connected);
                        })
                        .map!((a) {
                            auto rest = a[1];
                            rest ~= a[0];
                            rest.sort;
                            return rest;
                        })
                        .array
                        .sort
                        .uniq
                        .array;
    }
    return prev[0].joiner(",");
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