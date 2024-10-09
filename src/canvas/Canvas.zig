const std = @import("std");

const Self = @This();

const Writer = std.io.BufferedWriter(2048, std.io.AnyWriter);

writer: Writer,
width: u32,
height: u32,

pub fn init(writer: std.io.AnyWriter, width: u32, height: u32) Self {
    const bw = Writer{ .unbuffered_writer = writer };
    writer.print("\x1b 7\x1b[s\x1b[?25l", .{}) catch unreachable;
    return Self{ .writer = bw, .width = width, .height = height };
}

pub fn deinit(self: *Self) void {
    const writer = self.writer.writer();
    defer writer.print("\x1b 8\x1b[u\x1b[{d}E\x1b[?25h", .{self.height}) catch unreachable;
    self.writer.flush() catch unreachable;
    self.* = undefined;
}

pub fn render(self: *Self) !void {
    defer self.writer.flush() catch unreachable;

    const writer = self.writer.writer();
    defer writer.print("\x1b 8\x1b[u", .{}) catch unreachable;

    writer.print("{d}:{d}:{d}\r\n", .{ @rem(@divFloor(std.time.timestamp(), std.time.s_per_hour), 24), @rem(@divFloor(std.time.timestamp(), std.time.s_per_min), 60), @rem(std.time.timestamp(), 60) }) catch unreachable;
}
