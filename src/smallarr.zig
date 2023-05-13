const std = @import("std");

const Allocator = std.mem.Allocator;

pub const MemType = enum {
    Stack,
    Heap,
};

pub fn SmallArray(comptime T: type, comptime size: usize) type {
    return union(MemType) { Stack: [size]T, Heap: std.ArrayListUnmanaged(T) };
}
