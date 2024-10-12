const std = @import("std");
const Buffer = @import("Canvas.zig").Buffer;

const Self = @This();

const Config = struct {
    fgmap: ?[]const u8 = null,
    bgmap: ?[]const u8 = null,
};

x: isize,
y: isize,
width: usize,
height: usize,
data: []const u8,
config: Config = .{},

pub fn init(x: isize, y: isize, width: usize, height: usize, data: []const u8, config: Config) Self {
    return Self{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .data = data,
        .config = config,
    };
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

pub fn frag(self: Self, x: usize, y: usize, buf: *Buffer) void {
    if (x < self.x or x >= self.x + @as(isize, @intCast(self.width)) or y < self.y or y >= self.y + @as(isize, @intCast(self.height))) return;
    const dx: usize = @intCast(@as(isize, @intCast(x)) - self.x);
    const dy: usize = @intCast(@as(isize, @intCast(y)) - self.y);
    buf[0] = self.data[@intCast(dy * self.width + dx)];
    if (self.config.fgmap) |fgmap| buf[1] = fgmap[@intCast(dy * self.width + dx)];
    if (self.config.bgmap) |bgmap| buf[2] = bgmap[@intCast(dy * self.width + dx)];
}
test "bounds" {
    const img = Self.init(1, 1, 1, 1, "#", .{});
    var buf: Buffer = .{null} ** 3;

    img.frag(1, 0, &buf);
    try std.testing.expectEqual(buf[0], null);
    buf = .{null} ** 3;
    img.frag(0, 1, &buf);
    try std.testing.expectEqual(buf[0], null);
    buf = .{null} ** 3;
    img.frag(1, 2, &buf);
    try std.testing.expectEqual(buf[0], null);
    buf = .{null} ** 3;
    img.frag(2, 1, &buf);
    try std.testing.expectEqual(buf[0], null);
    buf = .{null} ** 3;
    img.frag(1, 1, &buf);
    try std.testing.expectEqual(buf[0], '#');
    buf = .{null} ** 3;
}

test "projection" {
    const data = "1234";
    const img = Self.init(0, 0, 2, 2, data, .{});
    var buf: Buffer = .{null} ** 3;

    img.frag(0, 0, &buf);
    try std.testing.expectEqual(buf[0], '1');
    buf = .{null} ** 3;

    img.frag(1, 0, &buf);
    try std.testing.expectEqual(buf[0], '2');
    buf = .{null} ** 3;

    img.frag(0, 1, &buf);
    try std.testing.expectEqual(buf[0], '3');
    buf = .{null} ** 3;

    img.frag(1, 1, &buf);
    try std.testing.expectEqual(buf[0], '4');
    buf = .{null} ** 3;
}

test "colored projection" {
    const data = "1234";
    const img = Self.init(0, 0, 2, 2, data, .{ .fgmap = &.{ 'r', 'g', 'b', 'y' } });
    var buf: Buffer = .{null} ** 3;

    img.frag(0, 0, &buf);
    try std.testing.expectEqual(buf[1], 'r');
    buf = .{null} ** 3;

    img.frag(1, 0, &buf);
    try std.testing.expectEqual(buf[1], 'g');
    buf = .{null} ** 3;

    img.frag(0, 1, &buf);
    try std.testing.expectEqual(buf[1], 'b');
    buf = .{null} ** 3;

    img.frag(1, 1, &buf);
    try std.testing.expectEqual(buf[1], 'y');
    buf = .{null} ** 3;
}
