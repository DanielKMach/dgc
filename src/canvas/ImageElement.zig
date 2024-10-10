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

pub fn frag(self: Self, x: usize, y: usize) ?u8 {
    const dx = @as(isize, @intCast(x)) - self.x;
    const dy = @as(isize, @intCast(y)) - self.y;
    if (dx >= 0 and dx < self.width and dy >= 0 and dy < self.height) {
        return self.data[@intCast(y * self.width + x)];
    }
    return null;
}

test "boundary" {
    const data = "1234";
    const img = Self.init(0, 0, 2, 2, data);

    try std.testing.expectEqual(img.frag(0, 0), '1');
    try std.testing.expectEqual(img.frag(1, 0), '2');
    try std.testing.expectEqual(img.frag(0, 1), '3');
    try std.testing.expectEqual(img.frag(1, 1), '4');
}
