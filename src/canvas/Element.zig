const std = @import("std");
const Buffer = @import("Canvas.zig").Buffer;

const Self = @This();
const FragFunc = *const fn (*const anyopaque, usize, usize, *Buffer) void;
const DeinitFunc = *const fn (*const anyopaque, std.mem.Allocator) void;

allocator: ?std.mem.Allocator,
data: *const anyopaque,
fragFunc: FragFunc,
deinitFunc: DeinitFunc,

pub fn new(base: anytype, allocator: std.mem.Allocator) !Self {
    const typeInfo: std.builtin.Type = @typeInfo(@TypeOf(base));
    const DataType = if (typeInfo == .Pointer) typeInfo.Pointer.child else @TypeOf(base);
    var data: *const anyopaque = undefined;
    var alloc: ?std.mem.Allocator = null;

    if (typeInfo == .Pointer and @typeInfo(typeInfo.Pointer.child) == .Struct) {
        data = @ptrCast(base);
    } else if (typeInfo == .Struct) {
        const ptr = try allocator.create(DataType);
        ptr.* = base;
        data = @ptrCast(ptr);
        alloc = allocator;
    } else {
        @compileError("`base` must be a struct or a pointer to a struct");
    }

    if (!@hasDecl(DataType, "frag")) {
        @compileError("`base` must have a `frag` method");
    }

    const gen = struct {
        pub fn frag(pointer: *const anyopaque, x: usize, y: usize, buf: *Buffer) void {
            const self: *const DataType = @ptrCast(@alignCast(pointer));
            return DataType.frag(self.*, x, y, buf);
        }
        pub fn deinit(pointer: *const anyopaque, allo: std.mem.Allocator) void {
            const ptr: *const DataType = @ptrCast(@alignCast(pointer));
            allo.destroy(ptr);
        }
    };

    return init(data, gen.frag, gen.deinit, alloc);
}

pub fn init(data: *const anyopaque, fragFunc: FragFunc, deinitFunc: DeinitFunc, allocator: ?std.mem.Allocator) Self {
    return Self{
        .data = data,
        .fragFunc = fragFunc,
        .deinitFunc = deinitFunc,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    if (self.allocator) |alloc| {
        self.deinitFunc(self.data, alloc);
    }
    self.* = undefined;
}

pub fn frag(self: *Self, x: usize, y: usize, buf: *Buffer) void {
    return self.fragFunc(self.data, x, y, buf);
}
