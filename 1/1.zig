const std = @import("std");

pub fn solve(comptime part: u32, reader: std.io.AnyReader, allocator: std.mem.Allocator) !u32 {
    _ = allocator;

    var line_buffer = [_]u8{0} ** 1024;

    var total: u32 = 0;

    while (reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |maybe_line| {
        var first_num: u32 = 0;
        var second_num: u32 = 0;
        var next_num: u32 = undefined;

        if (maybe_line) |line| {
            for (line, 0..) |char, pos| {
                next_num = switch (char) {
                    '1'...'9' => char - '0',
                    // In part 1, don't do the word to number conversion.
                    else => if (part == 2) check_if_word_num(line[pos..]) else 0,
                };

                if (next_num != 0) {
                    if (first_num == 0) first_num = next_num;
                    second_num = next_num;
                }
            }

            total += 10 * first_num + second_num;
        } else break;
    } else |err| std.debug.print("{!}", .{err});

    return total;
}

const word_nums = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

inline fn check_if_word_num(string: []u8) u8 {
    for (word_nums, 1..) |word, value|
        if (std.mem.startsWith(u8, string, word)) return @intCast(value);

    return 0;
}
