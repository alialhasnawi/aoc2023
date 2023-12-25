const std = @import("std");
const print = std.debug.print;

const solution = @import("5/solution.zig");
const input = @embedFile("5/input.txt");

pub fn main() !void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) std.debug.print("Skill issue.\n", .{});
    }
    const buffer = try gpa_alloc.alloc(u8, 1_000_000);
    defer gpa_alloc.free(buffer);

    var fixed_buffer = std.heap.FixedBufferAllocator.init(buffer);
    const fixed_buffer_alloc = fixed_buffer.allocator();

    inline for (1..3) |part| {
        var memory_usage: usize = 0;
        var answer: u128 = 0;

        var stream = std.io.fixedBufferStream(input);
        const reader = stream.reader().any();

        answer = try solution.solve(part, reader, fixed_buffer_alloc);
        memory_usage = fixed_buffer.end_index;

        print("Part {d}: answer: {d: >8}    using {d: >6.1} kB\n", .{ part, answer, @as(f32, @floatFromInt(memory_usage)) / 1024 });
    }
}
