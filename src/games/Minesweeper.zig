const std = @import("std");
const canvas = @import("../canvas.zig");

const Self = @This();

allocator: std.mem.Allocator,
canvas: canvas.Canvas,
width: usize,
height: usize,

x: usize = 0,
y: usize = 0,
state: []u8,
bombs: []u8,

pub fn init(allocator: std.mem.Allocator, out: std.io.AnyWriter) !Self {
    var cvs = canvas.Canvas.init(out, 16, 6, allocator);
    const state = try allocator.dupe(u8, &(.{'#'} ** (16 * 6)));
    const bombs = try allocator.dupe(u8, &(.{' '} ** (16 * 6)));

    var xoalgumacoisa = std.rand.Xoshiro256.init(@intCast(std.time.timestamp()));
    const random = xoalgumacoisa.random();

    for (0..16) |x| {
        for (0..6) |y| {
            if (random.intRangeAtMost(u8, 0, 100) < 10) {
                bombs[y * 16 + x] = 'X';
            }
        }
    }

    try cvs.addElement(canvas.ImageElement.init(0, 0, 16, 6, state));

    return Self{
        .allocator = allocator,
        .canvas = cvs,
        .width = 16,
        .height = 6,
        .state = state,
        .bombs = bombs,
    };
}

pub fn update(self: *Self, key: u8) !void {
    switch (key) {
        'j' => self.y += 1,
        'k' => self.y -= 1,
        'l' => self.x += 1,
        'h' => self.x -= 1,
        'P' => self.state[self.y * self.width + self.x] = 'P',
        ' ' => self.open(self.x, self.y),
        else => {},
    }
}

pub fn open(self: *Self, x: usize, y: usize) void {
    if (x < 0 or x >= self.width or y < 0 or y >= self.height)
        return;

    const i = y * self.width + x;
    if (self.state[i] != '#') return;

    if (self.bombs[i] == 'X') {
        for (0..self.state.len) |ii| {
            if (self.bombs[ii] == 'X') {
                self.state[ii] = 'X';
            }
        }
        return;
    }

    self.state[i] = '0';
    for (0..3) |dy| {
        for (0..3) |dx| {
            if (dx == 0 and x == 0 or dy == 0 and y == 0) continue;
            const yy = y + dy - 1;
            const xx = x + dx - 1;
            if (self.bombs[yy * self.width + xx] == 'X') {
                self.state[i] += 1;
            }
        }
    }

    if (self.state[i] == '0') {
        for (0..3) |dy| {
            for (0..3) |dx| {
                if (dx == 0 and x == 0 or dy == 0 and y == 0) continue;
                const yy = y + dy - 1;
                const xx = x + dx - 1;
                self.open(xx, yy);
            }
        }
        self.state[i] = ' ';
    }
}

pub fn render(self: *Self) !void {
    try self.canvas.render();
}

pub fn deinit(self: *Self) void {
    self.canvas.deinit();
    self.allocator.free(self.state);
}
