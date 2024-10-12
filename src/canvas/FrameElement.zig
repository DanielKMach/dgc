const std = @import("std");
const Buffer = @import("Canvas.zig").Buffer;

const Self = @This();

const Config = struct {
    frameColor: ?u8 = null,
    textColor: ?u8 = null,
    text: ?[]const u8 = null,
    frame: bool = true,
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
    if (x < self.x or x >= self.x + @as(isize, @intCast(self.width)) or
        y < self.y or y >= self.y + @as(isize, @intCast(self.height)))
    {
        return;
    }
    const xx = @as(isize, @intCast(x)) - self.x;
    const yy = @as(isize, @intCast(y)) - self.y;
    if (xx == 0 or xx == self.width - 1 or yy == 0 or yy == self.height - 1) {
        if (!self.config.frame) return;
        if (self.config.frameColor) |c| {
            buf[1] = c;
        }
        if (xx == 0 and yy == 0 or
            xx == 0 and yy == self.height - 1 or
            xx == self.width - 1 and yy == 0 or
            xx == self.width - 1 and yy == self.height - 1)
        {
            buf[0] = '+';
        } else if (xx == 0 or x == self.width - 1) {
            buf[0] = '|';
        } else if (yy == 0 or y == self.height - 1) {
            buf[0] = '-';
        }
    } else {
        if (self.config.text == null or self.config.text.?.len <= 0 or
            self.height < 3 and self.width < 3) return;
        if (self.config.textColor) |c| {
            buf[1] = c;
        }
        if (self.config.text) |txt| {
            const i = xx - 1;
            if (i >= 0 and i < txt.len and yy == 1) {
                buf[0] = txt[@intCast(i)];
            }
        }
    }
}
