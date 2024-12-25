module day3_1;

enum DONT =  "don't()";
enum DO = "do()";
enum MUL = "mul(";

auto parseLine(InputLine)(InputLine inputLine)
{

    import std.algorithm : find, map, startsWith, splitWhen, until;
    import std.range: drop, dropOne, empty, recurrence;
    import std.typecons: tuple;
    import std.meta: AliasSeq;

    pragma(msg, typeof(inputLine));
    auto ret =  recurrence!((a, n) {
        alias needles = AliasSeq!(DO, DONT, MUL);
        auto foundTup = a[n-1][1].find(needles);
        auto found = foundTup[0];
        auto next = found;
        if (foundTup[1] > 0) {
            next = next.drop([needles][foundTup[1] - 1].length);
        }
        return tuple(found, next);
    })(tuple(inputLine, inputLine))
    .dropOne
    .map!(a=>a[0])
    .until!(a=>a.empty)
    .splitWhen!((a, b)=>b.startsWith(DO, DONT))
    ;
    return ret;
}

auto parseLines(InputStream)(InputStream inputLines)
{
    import std.array:join;
    return inputLines.join.parseLine;
}

auto solveChunk(Chunk)(Chunk chunk) {
    import std.algorithm : filter, map;
    import std.format : formattedRead, FormatException;
    import std.typecons : tuple;

    return chunk.map!((a) {
        int lhs, rhs, read;
        try
        {
            read = a.formattedRead("mul(%d,%d)", lhs, rhs);
        }
        catch (FormatException e)
        {
            read = 0;
        }
        return tuple(lhs, rhs, read == 2);
    }).filter!(a=>a[2]);
}

auto solveLine(InputLine)(InputLine inputLine) {

    import std.algorithm : filter, map, joiner, startsWith;

    auto ret = inputLine.filter!(a=>!a.startsWith!((b) => b.startsWith(DONT))).map!(solveChunk).joiner;
    return ret;
}

auto solve(InputLines)(InputLines inputLines)
{
    import std.algorithm : map, sum;

    return inputLines.solveLine.map!(a=> a[0] * a[1]).sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine;
    auto inputData = inputLines.parseLines;
    auto ret = solve(inputData);
    writeln(ret);
    return 0;
}