const std = @import("std");

const Self = @This();

x: isize,
y: isize,
width: usize,
height: usize,
data: []const u8,

pub fn init(x: isize, y: isize, width: usize, height: usize, data: []const u8) Self {
    return Self{ .x = x, .y = y, .width = width, .height = height, .data = data };
}

pub fn from(x: isize, y: isize, comptime path: []const u8) Self {
    const data = @embedFile(path);
    const width = std.mem.indexOf(u8, data, &"\n");

    if (width) |w| {
        return Self{ .x = x, .y = y, .width = w, .height = @divFloor(data.len, w), .data = &data };
    } else {
        return Self{ .x = x, .y = y, .width = data.len, .height = 1, .data = &data };
    }
}

pub fn frag(self: Self, x: usize, y: usize, buf: []u8) void {
    const dx = @as(isize, @intCast(x)) - self.x;
    const dy = @as(isize, @intCast(y)) - self.y;
    if (dx >= 0 and dx < self.width and dy >= 0 and dy < self.height) {
        buf[0] = self.data[@intCast(y * self.width + x)];
    }
}

test "boundary" {
    const data = "1234";
    const img = Self.init(0, 0, 2, 2, data);
    var buf: [3]u8 = std.mem.zeroes([3]u8);

    img.frag(0, 0, &buf);
    try std.testing.expectEqual(buf[0], '1');
    buf = std.mem.zeroes([3]u8);

    img.frag(1, 0, &buf);
    try std.testing.expectEqual(buf[0], '2');
    buf = std.mem.zeroes([3]u8);

    img.frag(0, 1, &buf);
    try std.testing.expectEqual(buf[0], '3');
    buf = std.mem.zeroes([3]u8);

    img.frag(1, 1, &buf);
    try std.testing.expectEqual(buf[0], '4');
    buf = std.mem.zeroes([3]u8);
}
