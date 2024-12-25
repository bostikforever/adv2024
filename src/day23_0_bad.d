module day23_0_bad;

auto parseLine(InputLine)(InputLine inputLine) {
    import std.format: formattedRead;
    import std.typecons: tuple;

    string first, second;

    inputLine.formattedRead("%s-%s", first, second);
    return tuple(first, second);
}

auto solve(InputLines)(InputLines inputLines) {

    import std.algorithm: each;

    string[string] parents;
    int[string] sizes;
    
    string findParent(string x)
    {
        if (x !in parents) {
            parents[x] = x;
            sizes[x] = 1;
            return x;
        }
        string y = x;
        while (parents[y] != y)
            y = parents[y];

        while (parents[x] != x)
        {
            string z = parents[x];
            parents[x] = y;
            x = z;
        }

        return y;
    }
    auto setUnion(string x, string y) {
        x = findParent(x);
        y = findParent(y);
        if (x == y) {
            return;
        }
        string bigger = x, smaller = y;
        if (bigger < smaller) {
            bigger = y;
            smaller = x;
        }
        parents[smaller] = bigger;
        sizes[bigger] += sizes[smaller];
    }

    inputLines.each!(a => setUnion(a.expand));
    parents.byKey.each!(a => parents[a] = findParent(a));


    return parents;
}

int main(string[] argv)
{
    import std.algorithm: map;
    import std.stdio : File, writeln;
    import std.array: array;
    import std.conv: to;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.map!parseLine;
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}