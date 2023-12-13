const std = @import("std");
const assert = std.debug.assert;

const MAX_CARDS = 16;

pub fn solve(comptime part: u32, reader: std.io.AnyReader, allocator: std.mem.Allocator) !u32 {
    _ = allocator;

    var answer: u32 = 0;

    // Original buffer to read into initially.
    var line_buffer = [_]u8{'.'} ** 1024;
    var line_buffer_stream = std.io.fixedBufferStream(&line_buffer);
    const line_buffer_writer = line_buffer_stream.writer();

    var card_count_ring_buffer = [_]u32{1} ** MAX_CARDS;
    var card_count_ring: Ring(u32) = .{ .backing_slice = &card_count_ring_buffer };

    while (true) {
        line_buffer_writer.context.reset();
        if (reader.streamUntilDelimiter(line_buffer_writer, '\n', null)) {
            const winning_number_count = try get_matching_number_count(line_buffer_writer.context.getWritten());
            if (part == 1) {
                if (winning_number_count > 0) answer += std.math.pow(u32, 2, winning_number_count - 1);
            } else {
                const curr_copies = card_count_ring.pop(1);

                // Add copies for each of the next scratch tickets.
                for (0..winning_number_count) |i_usize| {
                    const i: u8 = @intCast(i_usize);
                    if (debug) std.debug.print("curr_copies={d} + card_count_ring.get(i)={d}\n", .{ curr_copies, card_count_ring.get(i) });
                    card_count_ring.set(i, curr_copies + card_count_ring.get(i));
                }

                answer += curr_copies;
            }
        } else |_| break; // Ignore end of stream.
    }

    return answer;
}

fn Ring(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Slice storing T items.
        backing_slice: []T,
        /// Index of first used slot in slice.
        start_index: u8 = 0,
        /// Number of items currently stored.
        len: u8 = 0,

        inline fn realIndex(self: Self, index: u8) u8 {
            return @intCast((self.start_index + index) % self.backing_slice.len);
        }

        /// Get the element at the 0-based index in this ring.
        pub fn get(self: Self, index: u8) T {
            return self.backing_slice[self.realIndex(index)];
        }

        /// Set the element at the 0-based index in this ring.
        pub fn set(self: *Self, index: u8, item: T) void {
            self.backing_slice[self.realIndex(index)] = item;
        }

        /// Return and remove the first item from the front of this ring.
        /// Also sets that position to a reset value.
        pub fn pop(self: *Self, reset: T) T {
            const item = self.backing_slice[self.start_index];
            self.backing_slice[self.start_index] = reset;
            self.start_index = @intCast((self.start_index + 1) % self.backing_slice.len);
            return item;
        }
    };
}

inline fn get_matching_number_count(line: []u8) !u8 {
    var winning_number_count: u8 = 0;
    const colon_index = std.mem.indexOfScalar(u8, line, ':') orelse return error.BadFormat;
    const pipe_index = std.mem.indexOfScalar(u8, line, '|') orelse return error.BadFormat;

    var winning_numbers = try std.BoundedArray(u8, MAX_CARDS).init(0);

    var winning_numbers_iterator = std.mem.tokenizeScalar(u8, line[colon_index + 1 .. pipe_index], ' ');
    while (winning_numbers_iterator.next()) |winning_number_str| {
        try winning_numbers.append(try std.fmt.parseInt(u8, winning_number_str, 10));
    }

    var own_numbers_iterator = std.mem.tokenizeScalar(u8, line[pipe_index + 1 ..], ' ');
    while (own_numbers_iterator.next()) |own_number_str| {
        // if (debug) std.debug.print("Own number '{s}'\n", .{own_number_str});
        const own_number = try std.fmt.parseInt(u8, own_number_str, 10);
        if (std.mem.indexOfScalar(u8, winning_numbers.slice(), own_number) != null)
            winning_number_count += 1;
    }

    return winning_number_count;
}

const debug = false;

const example =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    \\
;

test "part 1" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const answer = try solve(1, reader, std.testing.allocator);
    try std.testing.expect(13 == answer);
}

test "part 2" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const answer = try solve(2, reader, std.testing.allocator);
    try std.testing.expect(30 == answer);
}
