const std = @import("std");
const builtin = @import("builtin");
const canvas = @import("canvas.zig");
const c = if (builtin.os.tag == .windows) @cImport({
    @cInclude("conio.h");
}) else @cImport({
    @cInclude("ncurses.h");
});

const Self = @This();

canvas: canvas.Canvas,
in: std.io.AnyReader,
out: std.io.AnyWriter,

stateMtx: std.Thread.Mutex = std.Thread.Mutex{},

pub fn init(in: std.fs.File, out: std.fs.File) Self {
    const writer = out.writer().any();
    const reader = in.reader().any();

    return Self{
        .canvas = canvas.Canvas.init(writer, 16, 16),
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
