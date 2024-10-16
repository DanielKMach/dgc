const std = @import("std");
const Element = @import("element.zig");
const Buffer = @import("Canvas.zig").Buffer;
const Self = @This();

pub const Config = struct {
    char: ?u8 = null,
    bgcolor: ?u8 = null,
    fgcolor: ?u8 = null,
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

pub fn frag(self: Self, x: usize, y: usize, buf: *Buffer) void {
    if (x >= self.x and x < self.x + @as(isize, @intCast(self.width)) and y >= self.y and y < self.y + @as(isize, @intCast(self.height))) {
        if (self.config.char) |c| buf[0] = c;
        if (self.config.fgcolor) |c| buf[1] = c;
        if (self.config.bgcolor) |c| buf[2] = c;
    }
}

test "boundary" {
    const box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var buf: Buffer = .{null} ** 3;

    box.frag(15, 15, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    box.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    box.frag(16, 16, &buf);
    try std.testing.expect(buf[0] == null);
    buf = .{null} ** 3;
}

test "element" {
    const box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var element = try Element.new(&box, std.testing.allocator);
    defer element.deinit();
    var buf: Buffer = .{null} ** 3;

    element.frag(15, 15, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    element.frag(16, 16, &buf);
    try std.testing.expect(buf[0] == null);
    buf = .{null} ** 3;
}

test "allocated element" {
    const box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var element = try Element.new(box, std.testing.allocator);
    defer element.deinit();
    var buf: Buffer = .{null} ** 3;

    element.frag(15, 15, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    element.frag(16, 16, &buf);
    try std.testing.expect(buf[0] == null);
    buf = .{null} ** 3;
}

test "moving" {
    var box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var buf: Buffer = .{null} ** 3;

    box.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    box.x += 1;

    box.frag(0, 0, &buf);
    try std.testing.expect(buf[0] == null);
    buf = .{null} ** 3;

    box.frag(1, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;
}

test "moving element" {
    var box = Self.init(0, 0, 16, 16, .{ .char = '#' });
    var element = try Element.new(&box, std.testing.allocator);
    defer element.deinit();
    var buf: Buffer = .{null} ** 3;

    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;

    box.x += 1;
    element.frag(0, 0, &buf);
    try std.testing.expect(buf[0] == null);
    buf = .{null} ** 3;

    element.frag(1, 0, &buf);
    try std.testing.expect(buf[0] != null);
    buf = .{null} ** 3;
}
