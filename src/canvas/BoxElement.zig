const std = @import("std");
const Element = @import("element.zig");
const Self = @This();

pub const Config = struct {
    char: ?u8 = null,
    bgcolor: ?u8 = null,
    fgcolor: ?u8 = null,
    frame: bool = false,
};

x: isize,
y: isize,
width: usize,
height: usize,
config: Config = .{},

pub fn init(x: isize, y: isize, width: usize, height: usize, config: Config) Self {
    return Self{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .config = config,
    };
}

pub fn frag(self: Self, x: usize, y: usize, buf: []u8) void {
    if (x >= self.x and x < self.x + @as(isize, @intCast(self.width)) and y >= self.y and y < self.y + @as(isize, @intCast(self.height))) {
        if (self.config.char) |c| buf[0] = c;
        if (self.config.fgcolor) |c| buf[1] = c;
        if (self.config.bgcolor) |c| buf[2] = c;
        if (self.config.frame) {
            if (x == self.x and y == self.y) {
                buf[0] = '+';
            } else if (x == self.x + @as(isize, @intCast(self.width)) - 1 and y == self.y) {
                buf[0] = '+';
            } else if (x == self.x and y == self.y + @as(isize, @intCast(self.height)) - 1) {
                buf[0] = '+';
            } else if (x == self.x + @as(isize, @intCast(self.width)) - 1 and y == self.y + @as(isize, @intCast(self.height)) - 1) {
                buf[0] = '+';
            } else if (x == self.x or x == self.x + @as(isize, @intCast(self.width)) - 1) {
                buf[0] = '|';
            } else if (y == self.y or y == self.y + @as(isize, @intCast(self.height)) - 1) {
                buf[0] = '-';
            }
        }
    }
}

test "boundary" {
    const box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var buf: [3]u8 = std.mem.zeroes([3]u8);

    box.frag(15, 15, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    box.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    box.frag(16, 16, &buf);
    try std.testing.expect(buf[0] == 0);
    buf = std.mem.zeroes([3]u8);
}

test "element" {
    const box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var element = try Element.new(&box, std.testing.allocator);
    defer element.deinit();
    var buf: [3]u8 = std.mem.zeroes([3]u8);

    element.frag(15, 15, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    element.frag(16, 16, &buf);
    try std.testing.expect(buf[0] == 0);
    buf = std.mem.zeroes([3]u8);
}

test "allocated element" {
    const box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var element = try Element.new(box, std.testing.allocator);
    defer element.deinit();
    var buf: [3]u8 = std.mem.zeroes([3]u8);

    element.frag(15, 15, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    element.frag(16, 16, &buf);
    try std.testing.expect(buf[0] == 0);
    buf = std.mem.zeroes([3]u8);
}

test "moving" {
    var box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var buf: [3]u8 = std.mem.zeroes([3]u8);

    box.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    box.x += 1;

    box.frag(0, 0, &buf);
    try std.testing.expect(buf[0] == 0);
    buf = std.mem.zeroes([3]u8);

    box.frag(1, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);
}

test "moving element" {
    var box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var element = try Element.new(&box, std.testing.allocator);
    defer element.deinit();
    var buf: [3]u8 = std.mem.zeroes([3]u8);

    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);

    box.x += 1;
    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] == 0);
    buf = std.mem.zeroes([3]u8);

    element.frag(1, 0, &buf);
    try std.testing.expect(buf[0] != 0);
    buf = std.mem.zeroes([3]u8);
}
