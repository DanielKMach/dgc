const std = @import("std");
const builtin = @import("builtin");

const DGC = @import("DGC.zig");

const c = if (builtin.os.tag == .windows) @cImport({
    @cInclude("conio.h");
}) else @cImport({
    @cInclude("ncurses.h");
});

pub fn main() !void {
    var game = DGC.new(std.io.getStdIn(), std.io.getStdOut(), std.heap.page_allocator);
    defer game.deinit();

    _ = try std.Thread.spawn(.{}, handleInputs, .{game});

    while (true) {
        std.time.sleep(std.time.ns_per_s / 60);
        {
            try game.tick();
        }
    }
}

fn handleInputs(game: *DGC) !void {
    while (true) {
        const key = c.getch();

        if (key == 'q') break;
        try game.update(@intCast(key));
    }
    std.process.exit(0);
}
