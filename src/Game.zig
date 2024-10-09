const std = @import("std");
const builtin = @import("builtin");
const canvas = @import("canvas.zig");
const c = if (builtin.os.tag == .windows) @cImport({
    @cInclude("conio.h");
}) else @cImport({
    @cInclude("ncurses.h");
});

const Self = @This();

allocator: std.mem.Allocator,
canvas: canvas.Canvas,
in: std.io.AnyReader,
out: std.io.AnyWriter,
box: canvas.BoxElement,

stateMtx: std.Thread.Mutex = std.Thread.Mutex{},

pub fn new(in: std.fs.File, out: std.fs.File, allocator: std.mem.Allocator) *Self {
    const writer = out.writer().any();
    const reader = in.reader().any();

    const box = canvas.BoxElement.init(0, 0, 4, 4);
    const cvs = canvas.Canvas.init(writer, 8, 8, allocator);

    const self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .canvas = cvs,
        .box = box,
        .in = reader,
        .out = writer,
    };

    self.canvas.addElement(&self.box) catch unreachable;
    return self;
}

pub fn update(self: *Self) !void {
    while (true) {
        const key = c.getch();

        self.stateMtx.lock();
        defer self.stateMtx.unlock();

        switch (key) {
            'j' => self.box.y += 1,
            'k' => self.box.y -= 1,
            'l' => self.box.x += 1,
            'h' => self.box.x -= 1,
            else => {},
        }
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

    self.allocator.destroy(self);
}
