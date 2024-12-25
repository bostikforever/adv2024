module day19_1;

auto parseTokens(InputLine)(InputLine inputLine)
{
    import std.algorithm: splitter;

    return inputLine.splitter(", ");
}

auto solveSingle(Tokens, Line)(Tokens tokens, Line line)
{
    import std.algorithm : map, sort, uniq;
    import std.array: array, assocArray;

    import std.range: iota, repeat, retro;

    auto tokenLengths = tokens.map!(a=>a.length).array.sort.uniq;
    auto tokensSet = tokens.assocArray(repeat(true));

    long[] valids = new long[line.length + 1];
    valids[line.length] = 1;
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
            valids[begin] += valids[end];
        }
    }
    return valids[0];
}

auto solve(Tokens, Lines)(Tokens tokens, Lines lines)
{
    import std.algorithm: map, sum;
    return lines.map!(a=>tokens.solveSingle(a)).sum;
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
    auto tokens = inputLines.front.front.parseTokens;
    auto lines = inputLines.dropOne.front;

    auto ret = solve(tokens, lines);
    writeln(ret);
    return 0;
}
