const std = @import("std");

const Allocator = std.mem.Allocator;

pub const MemType = enum {
    Stack,
    Heap,
};

pub const Error = error{
    Overflow,
} || Allocator.Error;

pub fn SmallArray(comptime T: type, comptime stack_size: usize) type {
    return union(MemType) {
        const Self = @This();
        const StackType = std.BoundedArray(T, stack_size);
        const HeapType = std.ArrayListUnmanaged(T);

        Stack: StackType,
        Heap: HeapType,

        pub fn init(allocator: Allocator, size: usize) Error!Self {
            if (size > stack_size) {
                const heap = try HeapType.initCapacity(allocator, size);
                return Self{ .Heap = heap };
            } else {
                const stack = try StackType.init(size);
                return Self{ .Stack = stack };
            }
        }

        pub fn append(self: *Self, allocator: Allocator, item: T) Error!void {
            switch (self.*) {
                .Stack => |*stack| {
                    const l = stack.len + 1;
                    const capacity = stack.capacity();
                    if (l == capacity) {
                        const f: f32 = @floatFromInt(capacity);
                        const new_capacity: usize = @intFromFloat(f * 1.5);
                        var heap = try HeapType.initCapacity(allocator, new_capacity);
                        try heap.appendSlice(allocator, stack.buffer[0..stack.len]);
                        try heap.append(allocator, item);
                        self.* = Self{ .Heap = heap };
                    } else {
                        try stack.append(item);
                    }
                },
                .Heap => |*heap| {
                    try heap.append(allocator, item);
                },
            }
        }

        pub inline fn deinit(self: *Self, allocator: Allocator) void {
            switch (self.*) {
                .Heap => |*heap| {
                    heap.deinit(allocator);
                },
                else => {},
            }
        }

        pub inline fn len(self: *const Self) usize {
            return switch (self.*) {
                .Heap => |heap| heap.items.len,
                .Stack => |stack| stack.len,
            };
        }

        pub inline fn items(self: Self) []const T {
            return switch (self) {
                .Heap => |heap| heap.items,
                .Stack => |stack| stack.buffer[0..stack.len],
            };
        }

        pub inline fn items_mut(self: *Self) []T {
            return switch (self.*) {
                .Heap => |*heap| heap.items,
                .Stack => |*stack| stack.buffer[0..self.Stack.len],
            };
        }

        pub inline fn last(self: *const Self) ?*const T {
            if (self.len() == 0) {
                return null;
            }
            return &self.items()[self.len() - 1];
        }

        pub inline fn last_mut(self: *Self) ?*T {
            if (self.len() == 0) {
                return null;
            }
            return &self.items_mut()[self.len() - 1];
        }
    };
}

test "small arr append item until move to heap" {
    const allocator = std.testing.allocator;
    var arr = try SmallArray(usize, 32).init(allocator, 0);
    defer arr.deinit(allocator);
    for (0..10) |x| {
        try arr.append(allocator, x);
    }
    var items = arr.items();
    try std.testing.expectEqual(@as(usize, 10), items.len);
    for (items, 0..) |i, x| {
        try std.testing.expectEqual(i, x);
    }
    try std.testing.expectEqual(MemType.Stack, @as(MemType, arr));
    for (10..50) |x| {
        try arr.append(allocator, x);
    }
    items = arr.items();
    try std.testing.expectEqual(MemType.Heap, @as(MemType, arr));
    try std.testing.expectEqual(@as(usize, 50), items.len);
    for (items, 0..) |i, x| {
        try std.testing.expectEqual(i, x);
    }
}

test "change arr content use items fn" {
    const allocator = std.testing.allocator;
    var arr = try SmallArray(i32, 32).init(allocator, 0);
    defer arr.deinit(allocator);
    inline for (0..100) |x| {
        try arr.append(allocator, @intCast(x));
    }
    var items = arr.items_mut();
    for (items, 1..101) |*i, x| {
        i.* = @intCast(x);
    }
    inline for (1..101) |x| {
        try std.testing.expectEqual(@as(i32, x), items[x - 1]);
    }
}

test "change arr last item use last_mut fn" {
    const allocator = std.testing.allocator;
    var arr = try SmallArray(i32, 32).init(allocator, 0);
    defer arr.deinit(allocator);
    inline for (0..100) |x| {
        try arr.append(allocator, @intCast(x));
    }
    if (arr.last_mut()) |last| {
        try std.testing.expectEqual(@as(i32, 99), last.*);
        last.* = 100;
        try std.testing.expectEqual(@as(i32, 100), arr.last().?.*);
    }
}
