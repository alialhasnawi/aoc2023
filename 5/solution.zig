const std = @import("std");
const assert = std.debug.assert;

pub fn solve(comptime part: u32, reader: std.io.AnyReader, allocator: std.mem.Allocator) !u64 {
    return if (part == 1) part1(reader, allocator) else part2(reader, allocator);
}

const ValueBuffer = std.BoundedArray(u64, 32);

fn part1(reader: std.io.AnyReader, allocator: std.mem.Allocator) !u64 {
    _ = allocator;

    var answer: u64 = 0;

    var line_buffer = [_]u8{'.'} ** 1024;
    var line_buffer_stream = std.io.fixedBufferStream(&line_buffer);
    const line_buffer_writer = line_buffer_stream.writer();

    try reader.streamUntilDelimiter(line_buffer_writer, '\n', null);
    var line = line_buffer_writer.context.getWritten();

    var buffers = [_]ValueBuffer{ try ValueBuffer.init(0), try ValueBuffer.init(0) };

    var prev = &buffers[0];
    const next = &buffers[1];

    // Get all the seeds.
    var token_iter = std.mem.tokenizeScalar(u8, line, ' ');
    _ = token_iter.next(); // Throw away "seeds:"
    while (token_iter.next()) |seed_str| {
        try prev.append(try std.fmt.parseInt(u32, seed_str, 10));
    }

    try reader.skipUntilDelimiterOrEof('\n');

    while (true) {
        // Iterate over each type of value.
        try reader.skipUntilDelimiterOrEof('\n'); // Skip header with useless info.

        const eof: bool = while (true) {
            // Iterate over each range entry.
            line_buffer_writer.context.reset();
            reader.streamUntilDelimiter(line_buffer_writer, '\n', null) catch break true;
            line = line_buffer_writer.context.getWritten();

            // if (debug) std.debug.print("line: {s}\n", .{line});
            if (line.len == 0) {
                break false;
            }

            token_iter = std.mem.tokenizeScalar(u8, line, ' ');
            const dest_start = try std.fmt.parseInt(u64, token_iter.next() orelse return error.BadInput, 10);
            const src_start = try std.fmt.parseInt(u64, token_iter.next() orelse return error.BadInput, 10);
            const span = try std.fmt.parseInt(u64, token_iter.next() orelse return error.BadInput, 10);
            const src_end = src_start + span;

            const slice = prev.slice(); // Hmm... is marking this const UB?
            var i: u16 = @intCast(slice.len);
            while (i > 0) { // Iterate backwards in case elements are removed.
                i -= 1;
                const src = slice[i];
                if (src_start <= src and src < src_end) {
                    try next.append(src - src_start + dest_start);
                    _ = prev.swapRemove(i);
                }
            }
        };

        for (prev.slice()) |value| {
            try next.append(value);
        }

        if (debug) std.debug.print("prev: {any}\n", .{prev.slice()});
        std.mem.swap(ValueBuffer, prev, next); // Swap previous and next buffers.
        next.resize(0) catch unreachable;

        if (eof) break;
    }

    if (debug) std.debug.print("last: {any}\n", .{prev.slice()});

    answer = std.mem.min(u64, prev.slice());

    return answer;
}

const RangeInt = u32;
const _Range = struct {
    start: u64,
    ///Not inclusive.
    end: u64,

    pub fn to_Range(self: _Range) Range {
        return Range{ .start = @intCast(self.start), .span = @intCast(self.end - self.start) };
    }
};
const Range = struct {
    start: RangeInt,
    ///Not inclusive.
    span: RangeInt,

    pub fn to__Range(self: Range) _Range {
        return _Range{ .start = self.start, .end = self.start + self.span };
    }
};

const RangeBuffer = std.BoundedArray(Range, 128);

/// Return `r1` $\cap$ `r2`
fn set_intersect(r1: _Range, r2: _Range) ?_Range {
    // Cases: r2 is entirely in r1 or vice verse, r1 and r2 partially intersect.
    if (r1.start <= r2.start and r2.start < r1.end) {
        return _Range{ .start = r2.start, .end = @min(r1.end, r2.end) };
    } else if (r2.start <= r1.start and r1.start < r2.end) {
        return _Range{ .start = r1.start, .end = @min(r1.end, r2.end) };
    } else return null;
}

/// Return `r1` \ `r2`
fn set_minus(r1: _Range, r2: _Range) [2]?_Range {
    var ret = [2]?_Range{ null, null };

    // Start of r1 is kept
    if (r1.start < r2.start) {
        ret[0] = _Range{ .start = r1.start, .end = @min(r1.end, r2.start) };
    }

    // End of r1 is kept
    if (r2.end < r1.end) {
        ret[1] = _Range{ .start = @max(r2.end, r1.start), .end = r1.end };
    }

    // Don't duplicate ranges
    if (std.meta.eql(ret[0], ret[1])) {
        ret[1] = null;
    }

    return ret;
}

fn part2(reader: std.io.AnyReader, allocator: std.mem.Allocator) !u64 {
    _ = allocator;

    var answer: u64 = 0;

    var line_buffer = [_]u8{'.'} ** 1024;
    var line_buffer_stream = std.io.fixedBufferStream(&line_buffer);
    const line_buffer_writer = line_buffer_stream.writer();

    try reader.streamUntilDelimiter(line_buffer_writer, '\n', null);
    var line = line_buffer_writer.context.getWritten();

    var buffers = [_]RangeBuffer{ try RangeBuffer.init(0), try RangeBuffer.init(0) };

    var prev = &buffers[0];
    const next = &buffers[1];

    // Get all the seeds.
    var token_iter = std.mem.tokenizeScalar(u8, line, ' ');
    _ = token_iter.next(); // Throw away "seeds:"
    while (token_iter.next()) |seed_str| {
        const start = try std.fmt.parseInt(RangeInt, seed_str, 10);
        const span = try std.fmt.parseInt(RangeInt, token_iter.next() orelse return error.BadInput, 10);
        try prev.append(.{
            .start = start,
            .span = span,
        });
    }

    try reader.skipUntilDelimiterOrEof('\n');

    while (true) {
        // Iterate over each type of value.
        try reader.skipUntilDelimiterOrEof('\n'); // Skip header with useless info.

        const eof: bool = while (true) {
            // Iterate over each range entry.
            line_buffer_writer.context.reset();
            reader.streamUntilDelimiter(line_buffer_writer, '\n', null) catch break true;
            line = line_buffer_writer.context.getWritten();

            if (debug) std.debug.print("line: {s}\n", .{line});
            if (line.len == 0) {
                break false;
            }

            token_iter = std.mem.tokenizeScalar(u8, line, ' ');
            const dest_start = try std.fmt.parseInt(RangeInt, token_iter.next() orelse return error.BadInput, 10);
            const src_start = try std.fmt.parseInt(RangeInt, token_iter.next() orelse return error.BadInput, 10);
            const span = try std.fmt.parseInt(RangeInt, token_iter.next() orelse return error.BadInput, 10);
            const src_range = _Range{ .start = src_start, .end = @as(u64, src_start) + span };

            const slice = prev.slice(); // Hmm... is marking this const UB?
            var i: u16 = @intCast(slice.len);
            while (i > 0) { // Iterate backwards in case elements are removed.
                i -= 1;
                const check_range = slice[i];

                if (debug) std.debug.print("checking: {}\n", .{check_range});

                if (set_intersect(check_range.to__Range(), src_range)) |intersecting_range| {
                    // Remove this range for now.
                    _ = prev.swapRemove(i);

                    // Add where the intersection ends up to the next set of intervals.
                    // Split to deal with signed correctness
                    var out_range: _Range = undefined;
                    if (dest_start > src_start) {
                        const offset: RangeInt = dest_start - src_start;
                        out_range = _Range{ .start = intersecting_range.start + offset, .end = intersecting_range.end + offset };
                    } else {
                        const offset: RangeInt = src_start - dest_start;
                        if (debug) std.debug.print("intersecting_range.end=({}), offset=({})\n", .{ intersecting_range.end, offset });
                        out_range = _Range{ .start = intersecting_range.start - offset, .end = intersecting_range.end - offset };
                    }
                    try next.append(out_range.to_Range());

                    const remaining = set_minus(check_range.to__Range(), src_range);

                    for (remaining) |maybe_range| {
                        if (maybe_range) |range| {
                            try prev.append(range.to_Range());
                        }
                    }
                }
            }
        };

        for (prev.slice()) |value| {
            try next.append(value);
        }

        if (debug) std.debug.print("prev: {any}\n", .{prev.slice()});
        std.mem.swap(RangeBuffer, prev, next); // Swap previous and next buffers.
        next.resize(0) catch unreachable;

        if (eof) break;
    }

    if (debug) std.debug.print("last: {any}\n", .{prev.slice()});

    answer = blk: {
        const slice = prev.slice();
        var min = slice[0].start;
        for (slice) |range| {
            if (range.start < min) {
                min = range.start;
            }
        }
        break :blk min;
    };

    return answer;
}

const debug = false;

const example =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
    \\
;

test "part 1" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const expected: u64 = 35;
    const actual = try solve(1, reader, std.testing.allocator);
    try std.testing.expectEqual(expected, actual);
}

test "part 2" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const expected: u64 = 46;
    const actual = try solve(2, reader, std.testing.allocator);
    try std.testing.expectEqual(expected, actual);
}
