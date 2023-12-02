const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var line_buffer = [_]u8{0} ** 1024;

    var total: u32 = 0;

    while (reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |maybe_line| {
        var first_num: u32 = 0;
        var second_num: u32 = 0;
        var next_num: u32 = undefined;

        if (maybe_line) |line| {
            for (line, 0..) |char, pos| {
                next_num = switch (char) {
                    '1'...'9' => char_to_number(char),
                    else => check_if_word_num(line[pos..]),
                    // else => 0,
                };

                if (next_num != 0) {
                    if (first_num == 0) first_num = next_num;
                    second_num = next_num;
                }
            }

            total += 10 * first_num + second_num;
        } else break;
    } else |err| {
        std.debug.print("{!}", .{err});
    }

    std.debug.print("The total is: {d}.\n", .{total});
}

inline fn char_to_number(char: u8) u8 {
    return char - '0';
}

const word_nums = [_][]const u8{
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

inline fn check_if_word_num(string: []u8) u8 {
    for (word_nums, 1..) |word, value| {
        if (std.mem.startsWith(u8, string, word)) return @intCast(value);
    }
    return 0;
}
