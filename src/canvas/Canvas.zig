const std = @import("std");
const Element = @import("element.zig");

const Self = @This();

const Writer = std.io.BufferedWriter(2048, std.io.AnyWriter);

allocator: std.mem.Allocator,
writer: Writer,

elements: std.ArrayList(Element),
width: u32,
height: u32,

pub fn init(writer: std.io.AnyWriter, width: u32, height: u32, allocator: std.mem.Allocator) Self {
    const bw = Writer{ .unbuffered_writer = writer };
    writer.print("\x1b 7\x1b[s\x1b[?25l", .{}) catch unreachable;
    return Self{
        .writer = bw,
        .width = width,
        .height = height,
        .allocator = allocator,
        .elements = std.ArrayList(Element).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    const writer = self.writer.writer();
    writer.print("\x1b 8\x1b[u\x1b[{d}E\x1b[?25h", .{self.height}) catch unreachable;
    self.writer.flush() catch unreachable;

    for (self.elements.items) |*element| {
        element.deinit();
    }
    self.elements.deinit();

    self.* = undefined;
}

pub fn addElement(self: *Self, element: anytype) !void {
    if (@TypeOf(element) == Element) {
        try self.elements.append(element);
    } else {
        const el = try Element.new(element, self.allocator);
        try self.elements.append(el);
    }
}

pub fn render(self: *Self) !void {
    defer self.writer.flush() catch unreachable;

    const writer = self.writer.writer();
    defer writer.print("\x1b 8\x1b[u", .{}) catch unreachable;

    for (0..self.height) |y| {
        for (0..self.width) |x| {
            var c: ?u8 = null;
            for (self.elements.items) |*element| {
                const f = element.frag(x, y);
                if (f) |_| c = f;
            }
            writer.print("{c}", .{c orelse '.'}) catch unreachable;
        }
        writer.print("\r\n", .{}) catch unreachable;
    }
}
