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
vline: *canvas.BoxElement,
hline: *canvas.BoxElement,

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

    const vline = try allocator.create(canvas.BoxElement);
    const hline = try allocator.create(canvas.BoxElement);
    vline.* = canvas.BoxElement.init(0, 0, 1, 6, .{ .bgcolor = 238 });
    hline.* = canvas.BoxElement.init(0, 0, 16, 1, .{ .bgcolor = 238 });

    try cvs.addElement(canvas.ImageElement.init(0, 0, 16, 6, state));
    try cvs.addElement(vline);
    try cvs.addElement(hline);

    return Self{
        .allocator = allocator,
        .canvas = cvs,
        .width = 16,
        .height = 6,
        .state = state,
        .bombs = bombs,
        .vline = vline,
        .hline = hline,
    };
}

pub fn update(self: *Self, key: u8) !void {
    switch (std.ascii.toLower(key)) {
        'j' => self.moveCursor(0, 1),
        'k' => self.moveCursor(0, -1),
        'l' => self.moveCursor(1, 0),
        'h' => self.moveCursor(-1, 0),
        'p' => {
            const i = self.y * self.width + self.x;
            switch (self.state[i]) {
                'P' => self.state[i] = '#',
                '#' => self.state[i] = 'P',
                else => {},
            }
        },
        ' ' => self.open(self.x, self.y),
        else => {},
    }
}

pub fn moveCursor(self: *Self, dx: isize, dy: isize) void {
    if (dx == 0 and dy == 0) return;
    if (dx == 0 and self.y == 0 and dy == -1) return;
    if (dx == 0 and self.y == self.height - 1 and dy == 1) return;
    if (dy == 0 and self.x == 0 and dx == -1) return;
    if (dy == 0 and self.x == self.width - 1 and dx == 1) return;
    self.x = @as(usize, @intCast(@as(isize, @intCast(self.x)) + dx));
    self.y = @as(usize, @intCast(@as(isize, @intCast(self.y)) + dy));
    self.vline.x = @intCast(self.x);
    self.hline.y = @intCast(self.y);
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
            if (yy < 0 or yy >= self.height or xx < 0 or xx >= self.width) continue;
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
                if (yy < 0 or yy >= self.height or xx < 0 or xx >= self.width) continue;
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
