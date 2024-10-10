const std = @import("std");
const canvas = @import("canvas.zig");
const Minesweeper = @import("games/Minesweeper.zig");

const Self = @This();

allocator: std.mem.Allocator,
in: std.io.AnyReader,
out: std.io.AnyWriter,
game: Minesweeper,

stateMtx: std.Thread.Mutex = std.Thread.Mutex{},

pub fn new(in: std.fs.File, out: std.fs.File, allocator: std.mem.Allocator) *Self {
    const writer = out.writer().any();
    const reader = in.reader().any();

    const game = Minesweeper.init(allocator, writer) catch unreachable;

    const self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .game = game,
        .in = reader,
        .out = writer,
    };

    return self;
}

pub fn update(self: *Self, key: u8) !void {
    self.stateMtx.lock();
    defer self.stateMtx.unlock();

    try self.game.update(key);
}

pub fn tick(self: *Self) !void {
    self.stateMtx.lock();
    defer self.stateMtx.unlock();

    try self.game.render();
}

pub fn deinit(self: *Self) void {
    self.stateMtx.lock();
    self.game.deinit();

    self.allocator.destroy(self);
}
