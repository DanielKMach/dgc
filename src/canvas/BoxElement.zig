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

pub fn frag(self: Self, x: usize, y: usize) ?u8 {
    if (x >= self.x and x < self.x + @as(isize, @intCast(self.width)) and y >= self.y and y < self.y + @as(isize, @intCast(self.height))) {
        return '#';
    }
    return null;
}

test "boundary" {
    const box = Self.init(0, 0, 16, 16);

    var c = box.frag(15, 15);
    try std.testing.expect(c != null);

    c = box.frag(0, 0);
    try std.testing.expect(c != null);

    c = box.frag(16, 16);
    try std.testing.expect(c == null);
}

test "element" {
    const box = Self.init(0, 0, 16, 16);
    var element = try Element.new(&box, std.testing.allocator);
    defer element.deinit();

    var c = element.frag(15, 15);
    try std.testing.expect(c != null);

    c = element.frag(0, 0);
    try std.testing.expect(c != null);

    c = element.frag(16, 16);
    try std.testing.expect(c == null);
}

test "allocated element" {
    const box = Self.init(0, 0, 16, 16);
    var element = try Element.new(box, std.testing.allocator);
    defer element.deinit();

    var c = element.frag(15, 15);
    try std.testing.expect(c != null);

    c = element.frag(0, 0);
    try std.testing.expect(c != null);

    c = element.frag(16, 16);
    try std.testing.expect(c == null);
}

test "moving" {
    var box = Self.init(0, 0, 16, 16);

    try std.testing.expect(box.frag(0, 0) != null);

    box.x += 1;
    try std.testing.expect(box.frag(0, 0) == null);
    try std.testing.expect(box.frag(1, 0) != null);
}

test "moving element" {
    var box = Self.init(0, 0, 16, 16);
    var element = try Element.new(&box, std.testing.allocator);
    defer element.deinit();

    try std.testing.expect(element.frag(0, 0) != null);

    box.x += 1;
    try std.testing.expect(element.frag(0, 0) == null);
    try std.testing.expect(element.frag(1, 0) != null);
}
