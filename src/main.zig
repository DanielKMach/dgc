const std = @import("std");
const Game = @import("Game.zig");

pub fn main() !void {
    var game = Game.init(std.io.getStdIn(), std.io.getStdOut());
    defer game.deinit();

    _ = try std.Thread.spawn(.{}, Game.tick, .{&game});
    try game.update();

    std.process.exit(0);
}
