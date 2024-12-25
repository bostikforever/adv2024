module day8_1;

auto parseLine(InputLine)(InputLine inputLine) {
    import std.algorithm: filter, map;
    import std.range: enumerate;

    return inputLine.enumerate.filter!((idxVal)=> idxVal[1] !='.');
}

auto parseInput(InputLines)(InputLines inputLines) {
    import std.algorithm: each, joiner, map;
    import std.range: enumerate,tee;
    import std.typecons: tuple, Tuple;

    alias Pos = Tuple!(int, int);
    int length0, length1;
    Pos[][char] ret;
    inputLines
      .tee!(a=> length1 = cast(int) a.length)
      .map!parseLine.enumerate.map!((idx0Line){
        auto idx0 = idx0Line[0];
        auto line = idx0Line[1];
        return line.map!((idx1Val) {
            auto idx1 = idx1Val[0];
            auto val = idx1Val[1];
            return tuple(val, Pos(cast(int) idx0, cast(int) idx1));
        });
    })
    .tee!(a=>length0 += 1)
    .joiner
    .each!((item) {
        auto c = item[0];
        auto pos = item[1];
        ret.require(cast(char)c, cast(Pos[])[]) ~= pos;
    });

    return tuple(Pos(length0, length1), ret);
}

auto solve(InputData)(InputData inputData) {
    import std.algorithm: cartesianProduct, each, filter, map, sum, until;
    import std.functional: not;
    import std.math: abs;
    import std.numeric: gcd;
    import std.typecons: tuple, Tuple, Yes;
    import std.range: chain, enumerate, only, recurrence;


    alias Pos = Tuple!(int, int);
    bool[Pos] res;

    auto extent = inputData[0];
    auto inputLines = inputData[1];
    auto inBoard = (Pos node) {
                    return 0 <= node[0] && node[0] < extent[0] &&
                           0 <= node[1] && node[1] < extent[1];
                };
    auto add = (Pos left, Pos right) {
        return Pos(left[0] + right[0], left[1] + right[1]);
    };

    auto sub = (Pos left, Pos right) {
        return Pos(left[0] - right[0], left[1] - right[1]);
    };

    inputLines.byValue.each!((item) {
        item.enumerate
            .cartesianProduct(item.enumerate)
            .filter!((a) => a[0][0] < a[1][0])
            .each!((item){
                auto left = item[0][1];
                auto right = item[1][1];
                auto diff = sub(left, right);
                auto diffGcd = gcd(diff[0], diff[1]);
                diff[0] /= diffGcd;
                diff[1] /= diffGcd;
                auto nodesLeft = left.recurrence!((a, n) => add(a[n-1], diff)).until!(a => !inBoard(a));
                auto nodesRight = right.recurrence!((a, n) => sub(a[n-1], diff)).until!(a => !inBoard(a));
                auto nodes = nodesLeft.chain(nodesRight);
                nodes.each!((node) {
                    res[node] = true;
                });
                return Yes.each;
            })
            ;
    });
    
    return res.length;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputData = inputFile.byLine.parseInput;
    auto ret = solve(inputData);
    writeln(ret);
    return 0;
}
