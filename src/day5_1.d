module day5_1;

import std.array;

auto parseRules(InputStream)(InputStream inputLines)
{
    import std.algorithm : map;
    import std.format: formattedRead;
    import std.typecons: tuple;

    return inputLines
        .map!((a) {
            int left, right;
            a.formattedRead("%d|%d", left, right);
            return tuple(left, right);
        });
}

auto parseDataLine(InputLine)(InputLine inputLine) {
    import std.algorithm: map, splitter;
    import std.array: array;
    import std.conv: to;

    return inputLine.splitter(",").map!(to!int).array;
}

auto parseData(InputStream)(InputStream inputLines)
{
    import std.algorithm : map;

    return inputLines
        .map!(parseDataLine);
}

auto getOrder(Rules)(Rules rules) {
    import std.array: assocArray;
    import std.range: repeat;

    return rules.assocArray(repeat(true));
}

auto validLine(InputLine, Order)(InputLine inputLine, Order order) {
    import std.algorithm: all, cartesianProduct, filter, map;
    import std.range: enumerate;
    import std.typecons: tuple;

    auto inputEnum = inputLine.enumerate;
    auto allPairs = inputEnum.cartesianProduct(inputEnum)
                        .filter!(a=> a[0] < a[1])
                        .map!(a=>tuple(a[0][1], a[1][1]));
    return allPairs.all!(a => a in order);
}

auto makeValid(InputLine, Order)(InputLine inputLine, Order order) {
    import std.algorithm: all, cartesianProduct, map, sort, sum;
    import std.range: only;
    import std.typecons: tuple;

    auto res = inputLine.map!((a) {
        return tuple(a, only(a).cartesianProduct(inputLine)
                               .map!(a=> cast(bool)(a in order))
                               .sum);
    }).array;
    return res.sort!((a, b) => a[1] > b[1]).map!(a=>a[0]);
}

auto solve(Rules, InputData)(Rules rules, InputData inputData)
{
    import std.algorithm: filter, map, sum;

    auto order = rules.getOrder;
    return inputData.filter!(a => !a.validLine(order))
                    .map!(a => a.makeValid(order))
                    .map!(a => a[a.length/2])
                    .sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.algorithm: splitter;
    import std.range: dropOne;
    import std.array: array;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLineCopy.array.splitter("");
    auto rules = inputLines.front.parseRules;
    auto inputData = inputLines.dropOne.front.parseData;
    auto ret = solve(rules, inputData);
    writeln(ret);
    return 0;
}

