const std = @import("std");
const Element = @import("element.zig");
const Self = @This();

x: isize,
y: isize,
width: usize,
height: usize,

pub fn init(x: isize, y: isize, width: usize, height: usize) Self {
    return Self{ .x = x, .y = y, .width = width, .height = height };
}

pub fn frag(self: Self, x: usize, y: usize, buf: []u8) void {
    if (x >= self.x and x < self.x + @as(isize, @intCast(self.width)) and y >= self.y and y < self.y + @as(isize, @intCast(self.height))) {
        buf[0] = '#';
    }
}

test "boundary" {
    const box = Self.init(0, 0, 16, 16);
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
    const box = Self.init(0, 0, 16, 16);
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
    const box = Self.init(0, 0, 16, 16);
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
    var box = Self.init(0, 0, 16, 16);
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
    var box = Self.init(0, 0, 16, 16);
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
