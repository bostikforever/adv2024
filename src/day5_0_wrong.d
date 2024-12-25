module day5_0_wrong;

import std.array;

auto parseRules(InputStream)(InputStream inputLines)
{
    import std.algorithm : map;
    import std.format: formattedRead;

    return inputLines
        .map!((a) {
            int left, right;
            a.formattedRead("%d|%d", left, right);
            return [left, right];
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
    import std.algorithm: each, filter, map, max;
    import std.typecons: Tuple;
    import std.array: array, assocArray, popBack;

    alias NodeOrder = Tuple!(int, int);
    alias CountOrder = Tuple!(int, int);
    NodeOrder[] order;

    CountOrder[int] edgeCountOrder;

    int[][int] graph;

    rules.each!((a) {
        edgeCountOrder.require(a[1], CountOrder())[0] += 1;
        edgeCountOrder.require(a[0], CountOrder());
        graph.require(a[0], []) ~= a[1];
    });

    
    auto noIncoming = edgeCountOrder.byKeyValue.filter!((a) {
        return a.value[0] == 0;
    }).map!((a) {
        return NodeOrder(a.key, a.value[1]);
    }).array;

    while (!noIncoming.empty) {
        auto curr = noIncoming.back;
        noIncoming.popBack;
        order.assumeSafeAppend ~= curr;
        auto nextNodes = curr[0] in graph;
        if (!nextNodes) {
            continue;
        }
        foreach(edge; *nextNodes) {
            auto countOrder = edge in edgeCountOrder;
            pragma(msg, typeof(countOrder));
            (*countOrder)[0] -= 1;
            (*countOrder)[1] = max((*countOrder)[1], curr[1] + 1);
            if ((*countOrder)[0] == 0) {
                noIncoming.assumeSafeAppend ~= NodeOrder(edge, (*countOrder)[1]);
            }
        }
    }
    return order.assocArray;
}

auto validLine(InputLine, Order)(InputLine inputLine, Order order) {
    import std.algorithm: isSorted;
    return inputLine.isSorted!((a, b) => order[a] < order[b]);
}

auto solve(Rules, InputData)(Rules rules, InputData inputData)
{
    import std.algorithm: filter, map, sum;

    auto order = rules.getOrder;
    return inputData.filter!(a => a.validLine(order)).map!(a => a[a.length/2]).sum;
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

