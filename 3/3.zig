const std = @import("std");
const assert = std.debug.assert;

pub fn solve(comptime part: u32, reader: std.io.AnyReader, allocator: std.mem.Allocator) !u32 {
    _ = allocator;

    var answer: u32 = 0;

    // Original buffer to read into initially.
    var line_buffer = [_]u8{'.'} ** 1024;
    var line_buffer_stream = std.io.fixedBufferStream(&line_buffer);
    var line_buffer_writer = line_buffer_stream.writer();

    // Determine how much of the line buffer is needed to store 3 lines at a time.
    // We only need to know 3 lines rather than reading the entire input into memory.
    try reader.streamUntilDelimiter(line_buffer_writer, '\n', null);
    const line_length = try line_buffer_writer.context.getPos();
    const max_stream_pos = 3 * line_length;
    const three_line_buffer = line_buffer[0..max_stream_pos];

    while (true) {
        if (try line_buffer_writer.context.getPos() >= max_stream_pos) try line_buffer_writer.context.seekTo(0);
        const current_pos = try line_buffer_writer.context.getPos();

        const previous = three_line_buffer[(current_pos + line_length) % max_stream_pos ..][0..line_length];
        const current = three_line_buffer[(current_pos + 2 * line_length) % max_stream_pos ..][0..line_length];
        const next = three_line_buffer[current_pos..][0..line_length];

        if (reader.streamUntilDelimiter(line_buffer_writer, '\n', null)) {
            answer += try get_partial_total(part, previous, current, next);
        } else |_| break;
    }

    // Deal with last line.
    const current_pos = try line_buffer_writer.context.getPos();
    const next = three_line_buffer[current_pos..][0..line_length];
    const prev = three_line_buffer[(current_pos + line_length) % max_stream_pos ..][0..line_length];
    const curr = three_line_buffer[(current_pos + 2 * line_length) % max_stream_pos ..][0..line_length];
    @memset(next, '.');
    answer += try get_partial_total(part, prev, curr, next);

    return answer;
}

const debug = true;

fn get_partial_total(comptime part: u32, prev: []u8, curr: []u8, next: []u8) !u32 {
    assert(prev.len == curr.len and curr.len == next.len);

    if (debug) {
        std.debug.print(
            \\
            \\previous: {s}
            \\current:  {s}
            \\next:     {s}
            \\
        , .{ prev, curr, next });
    }

    var subtotal: u32 = 0;

    // Iterate over the line.
    var index: u32 = 0;
    while (index < curr.len) : (index += 1) {
        const char = curr[index];

        if (part == 1) {
            switch (char) {
                '0'...'9' => {
                    const start = index;
                    while (index < curr.len and is_digit(curr[index])) index += 1;
                    const end = index;

                    var part_found = false;

                    // Check above number.
                    for (prev[start..end]) |check_char| {
                        if (is_symbol(check_char)) {
                            part_found = true;
                            break;
                        }
                    }

                    if (!part_found) {
                        // Check below number.
                        for (next[start..end]) |check_char| {
                            if (is_symbol(check_char)) {
                                part_found = true;
                                break;
                            }
                        }
                    }

                    // Check left side.
                    if (!part_found and start != 0) {
                        const check_index = start - 1;
                        if (is_symbol(prev[check_index]) or is_symbol(curr[check_index]) or is_symbol(next[check_index])) part_found = true;
                    }

                    // Check right side.
                    if (!part_found and end != curr.len) {
                        const check_index = end;
                        if (is_symbol(prev[check_index]) or is_symbol(curr[check_index]) or is_symbol(next[check_index])) part_found = true;
                    }

                    if (part_found) {
                        if (debug) {
                            // std.debug.print("Using: {s}\n", .{curr[start..end]});
                        }
                        subtotal += try std.fmt.parseInt(u32, curr[start..end], 10);
                    }
                },
                else => {},
            }
        } else if (part == 2) {
            if (char != '*') continue;

            var num_parts: u8 = 0;
            var sub_subtotal: u32 = 1;

            if (debug) std.debug.print("\nindex: {d}: ", .{index});
            // Check above.
            var part_result = try get_product_at_index(prev, index);
            num_parts += part_result.num_parts;
            sub_subtotal *= part_result.product;
            // Check below.
            part_result = try get_product_at_index(next, index);
            num_parts += part_result.num_parts;
            sub_subtotal *= part_result.product;
            // Check to the left.
            var maybe_result = blk: {
                if (index == 0 or !is_digit(curr[index - 1])) break :blk null;
                var i: u32 = index - 1;
                while (i > 0) : (i -= 1) {
                    if (!is_digit(curr[i - 1])) break;
                }
                if (debug) std.debug.print("'{s}', ", .{curr[i..index]});
                break :blk try std.fmt.parseInt(u32, curr[i..index], 10);
            };
            if (maybe_result) |result| {
                num_parts += 1;
                sub_subtotal *= result;
            }
            // Check to the right.
            maybe_result = blk: {
                if (index == curr.len or !is_digit(curr[index + 1])) break :blk null;
                var i: u32 = index + 1;
                while (i < curr.len) : (i += 1) {
                    if (!is_digit(curr[i])) break;
                }
                if (debug) std.debug.print("'{s}', ", .{curr[index + 1 .. i]});
                break :blk if (i == index + 1) 1 else try std.fmt.parseInt(u32, curr[index + 1 .. i], 10);
            };

            if (maybe_result) |result| {
                num_parts += 1;
                sub_subtotal *= result;
            }

            if (num_parts == 2) {
                subtotal += sub_subtotal;
                if (debug) std.debug.print("        USED = {d}", .{sub_subtotal});
            }

            if (debug) std.debug.print("\n", .{});
        }
    }

    return subtotal;
}

const PartResult = struct {
    product: u32 = 1,
    num_parts: u8 = 0,
};

inline fn get_product_at_index(line: []u8, index: u32) !PartResult {
    var result: PartResult = .{};
    var relevant_start_index: u32 = index - 1;
    var relevant_end_index: u32 = index + 1;

    while (relevant_start_index > 0 and is_digit(line[relevant_start_index])) relevant_start_index -= 1;
    while (relevant_end_index < line.len and is_digit(line[relevant_end_index])) relevant_end_index += 1;

    var i: u32 = relevant_start_index;

    outer: while (i < relevant_end_index) : (i += 1) {
        // Skip non-digit segments.

        while (!is_digit(line[i])) continue :outer;

        const num_start = i;
        var num_end = i;

        // Find end of digit segment.
        while (i < relevant_end_index and is_digit(line[i])) {
            i += 1;
        }
        num_end = i;

        if (debug) std.debug.print("'{s}', ", .{line[num_start..num_end]});

        result.num_parts += 1;
        result.product *= try std.fmt.parseInt(u32, line[num_start..num_end], 10);
    }

    return result;
}

inline fn is_symbol(char: u8) bool {
    return switch (char) {
        '.' => false,
        '0'...'9' => false,
        else => true,
    };
}

inline fn is_digit(char: u8) bool {
    return switch (char) {
        '0'...'9' => true,
        else => false,
    };
}

test "part 1" {
    const example =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
        \\
    ;

    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const answer = try solve(1, reader, std.testing.allocator);
    try std.testing.expect(4361 == answer);
}

test "part 2" {
    const example =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
        \\
    ;

    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const answer = try solve(2, reader, std.testing.allocator);
    if (debug) std.debug.print("Answer: {d}\n", .{answer});
    try std.testing.expect(467835 == answer);
}
