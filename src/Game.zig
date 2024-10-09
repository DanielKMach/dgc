const std = @import("std");
const builtin = @import("builtin");
const Canvas = @import("Canvas.zig");
const c = if (builtin.os.tag == .windows) @cImport({
    @cInclude("conio.h");
}) else @cImport({
    @cInclude("ncurses.h");
});

const Self = @This();

canvas: Canvas,
in: std.io.AnyReader,
out: std.io.AnyWriter,

stateMtx: std.Thread.Mutex = std.Thread.Mutex{},

pub fn init(in: std.fs.File, out: std.fs.File) Self {
    const writer = out.writer().any();
    const reader = in.reader().any();

    return Self{
        .canvas = Canvas.init(writer, 16, 16),
        .in = reader,
        .out = writer,
    };
}

pub fn update(self: Self) !void {
    _ = self;
    while (true) {
        const cs = c.getch();
        if (cs == 'q') return;
    }
}

pub fn tick(self: *Self) !void {
    while (true) {
        std.time.sleep(std.time.ns_per_s / 60);
        {
            self.stateMtx.lock();
            defer self.stateMtx.unlock();

            try self.canvas.render();
        }
    }
}

pub fn deinit(self: *Self) void {
    self.stateMtx.lock();
    self.canvas.deinit();
    self.* = undefined;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
