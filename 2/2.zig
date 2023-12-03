const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var line_buffer = [_]u8{0} ** 1024;

    var id_sum: u32 = 0;
    var power_sum: u32 = 0;

    while (reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |maybe_line| {
        if (maybe_line) |line| {
            var game: Game = .{};

            const colon_pos = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidFormat;
            const id_str = line["Game ".len..colon_pos];
            game.id = try std.fmt.parseInt(u32, id_str, 10);

            var run_iter = std.mem.tokenizeSequence(u8, line[colon_pos + 2 ..], "; ");
            while (run_iter.next()) |run_str| {
                var colour_iter = std.mem.tokenizeSequence(u8, run_str, ", ");
                while (colour_iter.next()) |choice_str| {
                    const space_pos = std.mem.indexOfScalar(u8, choice_str, ' ') orelse return error.InvalidFormat;
                    const colour_str = choice_str[space_pos + 1 ..];
                    const colour_value_str = choice_str[0..space_pos];
                    const colour_value = try std.fmt.parseInt(u32, colour_value_str, 10);

                    if (std.mem.eql(u8, colour_str, "red")) {
                        game.red = @max(game.red, colour_value);
                    } else if (std.mem.eql(u8, colour_str, "green")) {
                        game.green = @max(game.green, colour_value);
                    } else if (std.mem.eql(u8, colour_str, "blue")) {
                        game.blue = @max(game.blue, colour_value);
                    }
                }
            }

            if (game.red <= 12 and game.green <= 13 and game.blue <= 14) id_sum += game.id;
            power_sum += game.red * game.blue * game.green;
        } else break;
    } else |err| {
        std.debug.print("{!}", .{err});
    }

    std.debug.print("Part 1: The ID sum is {d}\n", .{id_sum});
    std.debug.print("Part 2: The power sum is {d}\n", .{power_sum});
}

const Game = struct { id: u32 = 0, red: u32 = 0, green: u32 = 0, blue: u32 = 0 };
