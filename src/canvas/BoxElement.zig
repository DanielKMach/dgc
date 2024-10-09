const std = @import("std");
const Element = @import("element.zig");
const Self = @This();

x: u32,
y: u32,
width: u32,
height: u32,

pub fn init(x: u32, y: u32, width: u32, height: u32) Self {
    return Self{ .x = x, .y = y, .width = width, .height = height };
}

pub fn frag(self: Self, x: u32, y: u32) ?u8 {
    if (x >= self.x and x < self.x + self.width and y >= self.y and y < self.y + self.height) {
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
