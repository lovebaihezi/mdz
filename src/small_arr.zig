const std = @import("std");

const Allocator = std.mem.Allocator;

pub const MemType = enum {
    Stack,
    Heap,
};

pub fn SmallArray(comptime T: type, comptime stack_size: usize) type {
    return union(MemType) {
        const Self = @This();

        const StackType = std.BoundedArray(T, stack_size);
        const HeapType = std.ArrayListUnmanaged(T);

        Stack: StackType,
        Heap: HeapType,

        pub fn init(size: usize) error{Overflow}!Self {
            const stack = try StackType.init(size);
            return Self{ .Stack = stack };
        }

        pub fn append(self: *Self, allocator: Allocator, item: T) !void {
            switch (self.*) {
                .Stack => |*stack| {
                    const len = stack.len;
                    const capacity = stack.capacity();
                    if (len == capacity) {
                        var heap = try HeapType.initCapacity(capacity * 1.5);
                        try heap.append(allocator, stack[0..len]);
                        self.* = Self{ .Heap = heap };
                    } else {
                        stack.append(item);
                    }
                },
                .Heap => |*heap| {
                    try heap.append(allocator, item);
                },
            }
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            switch (self) {
                .Heap => |*heap| {
                    heap.deinit(allocator);
                },
                else => {},
            }
        }

        pub fn items(self: *Self) []T {
            return switch (self) {
                .Heap => |*heap| heap[0..heap.len],
                .Stack => |*stack| stack[0..stack.len],
            };
        }
    };
}

test "it work" {
    const allocator = std.testing.allocator;
    var arr = SmallArray(i32, 512);
    try arr.init(64);
    defer arr.deinit(allocator);
    for (0..10) |x| {
        try arr.append(allocator, x);
    }
    const items = arr.items();
    try std.testing.expectEqual(11, items.len);
    for (items, 0..) |i, x| {
        try std.testing.expectEqual(i, x);
    }
}
