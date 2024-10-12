const std = @import("std");
const canvas = @import("../canvas.zig");

const Self = @This();

const Cell = struct {
    const filled = '@';
    const flag = 'P';
    const empty = '.';
    const bomb = 'X';
};

const palette = blk: {
    var colors: [256]u8 = undefined;
    colors[Cell.empty] = 234;
    colors[Cell.filled] = 15;
    colors[Cell.flag] = 15;
    colors[Cell.bomb] = 52;
    colors['1'] = 12;
    colors['2'] = 2;
    colors['3'] = 9;
    colors['4'] = 4;
    colors['5'] = 1;
    colors['6'] = 6;
    colors['7'] = 0;
    colors['8'] = 7;
    break :blk colors;
};

allocator: std.mem.Allocator,
canvas: canvas.Canvas,
width: usize,
height: usize,

x: usize = 0,
y: usize = 0,
state: []u8,
colors: []u8,
bombs: []u8,
vline: *canvas.BoxElement,
hline: *canvas.BoxElement,

pub fn init(allocator: std.mem.Allocator, out: std.io.AnyWriter) !Self {
    const width = 8;
    const height = 8;

    var cvs = canvas.Canvas.init(out, width * 2 + 3, height + 2, allocator);
    const state = try allocator.dupe(u8, &(.{Cell.filled} ** (width * height)));
    const colors = try allocator.dupe(u8, &(.{palette[Cell.filled]} ** (width * height)));
    const bombs = try allocator.dupe(u8, &(.{Cell.empty} ** (width * height)));

    const vline = try allocator.create(canvas.BoxElement);
    const hline = try allocator.create(canvas.BoxElement);
    vline.* = canvas.BoxElement.init(2, 0, 1, height + 2, .{ .bgcolor = 234 });
    hline.* = canvas.BoxElement.init(0, 1, width * 2 + 3, 1, .{ .bgcolor = 234 });

    try cvs.addElement(vline);
    try cvs.addElement(hline);
    try cvs.addElement(canvas.FrameElement.init(0, 0, width * 2 + 3, height + 2, .{}));
    for (0..width) |x| {
        try cvs.addElement(canvas.ImageElement.init(
            @intCast(x * 2 + 2),
            1,
            1,
            height,
            state[x * height .. (x + 1) * height],
            .{ .fgmap = colors[x * height .. (x + 1) * height] },
        ));
    }

    var game = Self{
        .allocator = allocator,
        .canvas = cvs,
        .width = width,
        .height = height,
        .state = state,
        .colors = colors,
        .bombs = bombs,
        .vline = vline,
        .hline = hline,
    };

    game.reset();
    return game;
}

pub fn update(self: *Self, key: u8) !void {
    switch (std.ascii.toLower(key)) {
        'j' => self.moveCursor(0, 1),
        'k' => self.moveCursor(0, -1),
        'l' => self.moveCursor(1, 0),
        'h' => self.moveCursor(-1, 0),
        'f' => {
            const i = self.x * self.height + self.y;
            switch (self.state[i]) {
                Cell.flag => self.state[i] = Cell.filled,
                Cell.filled => self.state[i] = Cell.flag,
                else => {},
            }
        },
        ' ' => self.open(self.x, self.y),
        'r' => self.reset(),
        else => {},
    }
}

pub fn reset(self: *Self) void {
    var xoalgumacoisa = std.rand.Xoshiro256.init(@intCast(std.time.timestamp()));
    const random = xoalgumacoisa.random();
    const bombCount = 10;

    for (0..self.state.len) |i| {
        self.state[i] = Cell.filled;
        self.colors[i] = palette[Cell.filled];
        self.bombs[i] = Cell.empty;
    }
    for (0..bombCount) |_| while (true) {
        const rx = random.intRangeLessThan(usize, 0, self.width);
        const ry = random.intRangeLessThan(usize, 0, self.height);
        if (self.bombs[rx * self.height + ry] != Cell.bomb) {
            self.bombs[rx * self.height + ry] = Cell.bomb;
            break;
        }
    };
}

pub fn moveCursor(self: *Self, dx: isize, dy: isize) void {
    if (dx == 0 and dy == 0) return;
    if (dx == 0 and self.y == 0 and dy == -1) return;
    if (dx == 0 and self.y == self.height - 1 and dy == 1) return;
    if (dy == 0 and self.x == 0 and dx == -1) return;
    if (dy == 0 and self.x == self.width - 1 and dx == 1) return;
    self.x = @as(usize, @intCast(@as(isize, @intCast(self.x)) + dx));
    self.y = @as(usize, @intCast(@as(isize, @intCast(self.y)) + dy));
    self.vline.x = @intCast(self.x * 2 + 2);
    self.hline.y = @intCast(self.y + 1);
}

pub fn open(self: *Self, x: usize, y: usize) void {
    if (x < 0 or x >= self.width or y < 0 or y >= self.height)
        return;

    const i = x * self.height + y;
    if (self.state[i] != Cell.filled) return;

    if (self.bombs[i] == Cell.bomb) {
        for (0..self.state.len) |ii| {
            if (self.bombs[ii] == Cell.bomb) {
                self.state[ii] = Cell.bomb;
                self.colors[ii] = palette[Cell.bomb];
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
            if (self.bombs[xx * self.height + yy] == Cell.bomb) {
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
        self.state[i] = Cell.empty;
    }

    self.colors[i] = palette[self.state[i]];
}

pub fn render(self: *Self) !void {
    try self.canvas.render();
}

pub fn deinit(self: *Self) void {
    self.canvas.deinit();
    self.allocator.free(self.state);
}
