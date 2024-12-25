module day13_1;

auto parseInput(InputGroup)(InputGroup inputGroup) {
    import std.algorithm: map;
    import std.range: chunks, dropOne, front;
    import std.array: array;
    import std.format: formattedRead;
    import std.typecons: tuple;

    auto lineGroups = inputGroup.chunks(2);
    auto buttons = lineGroups.front.map!((inputLine){
        int x, y;
        inputLine.formattedRead("Button %*c: X+%d, Y+%d", x, y);
        return tuple(x, y);
    }).array;

    auto prize = tuple(0, 0);
    auto prizeLine = lineGroups.dropOne.front.front;
    prizeLine.formattedRead("Prize: X=%d, Y=%d", prize[0], prize[1]);
    return tuple(buttons[0], buttons[1], prize);
}

auto parseInputs(InputStream)(InputStream inputGroups)
{
    import std.algorithm : map;

    return inputGroups
        .map!(parseInput);
}

auto solveLine(Input)(Input input) {

    auto A = input[0];
    auto B = input[1];
    auto P = input[2];

    enum offset = 10_000_000_000_000;

    auto P0 = P[0] + offset; 
    auto P1 = P[1] + offset;
    auto x_y_test = A[0] * B[1] - A[1] * B[0];
    auto x_p_test = P0 * B[1] - B[0] * P1;
    auto y_p_test = P0 * A[1] - A[0] * P1;

    if (x_p_test % x_y_test != 0) {
        return 0;
    } 
    if (y_p_test % x_y_test != 0) {
        return 0;
    }

    if (x_y_test == 0) {
        assert(false); // special case if exists;
    }

    auto x = x_p_test / x_y_test;
    auto y = -y_p_test / x_y_test;
    auto res = 3 * x + y;
    return res;
}

auto solve(Inputs)(Inputs inputs)
{
    import std.algorithm: map, sum;

    return inputs.map!solveLine.sum;
}

int main(string[] argv)
{
    import std.stdio : File, writeln;
    import std.range: chunks;

    immutable filename = argv[1];
    auto inputFile = File(filename);
    auto inputLines = inputFile.byLine.chunks(4);
    auto inputs = inputLines.parseInputs;
    auto ret = inputs.solve;
    writeln(ret);
    return 0;
}
