auto parseLine(InputLine)(InputLine inputLine) {
    import std.algorithm: splitter, map;
    import std.array: array;
    import std.conv: to;
    import std.range: dropOne;
    import std.typecons: tuple;

    auto targetArgs = inputLine.splitter(": ");
    auto target = targetArgs.front.to!long;
    auto args = targetArgs.dropOne.front.splitter.map!(to!int).array;

    return tuple(target, args);
}

auto parseInput(InputLines)(InputLines inputLines) {
    import std.algorithm: map;

    return inputLines.map!parseLine;
}

auto solveLine(Target, Args)(Target target, Args args) {
    import std.array: back;

    if (args.length == 1) {
        return target == args.back;
    }
    foreach(i; 0..3) {
        auto right = args.back;
        long newTarget = 0;
        final switch(i){
          case 0: // multiplication
            if (target % right != 0) {
                continue;
            }
            newTarget = target/right;
            break;
          case 1: // addition
            newTarget = target - right;
            break;
          case 2: // ||
            auto n = right.numDigits;
            auto scale = 10^^n;
            if (target % scale != right) {
                continue;
            }
            newTarget = target / scale;
        }
        auto match = solveLine(newTarget, args[0..$-1]);
        if (match) {
            return true;
        }
    }
    return false;
}

auto solve(InputLines)(InputLines inputLines) {
    import std.algorithm: filter, map, sum;

    return inputLines.filter!(a=>solveLine(a.expand)).map!(a=>a[0]).sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.parseInput;
    auto ret = solve(inputLines);
    writeln(ret);
    return 0;
}
