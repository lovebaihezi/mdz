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
    return struct {
        const Self = @This();

        const StackType = std.BoundedArray(T, stack_size);
        const HeapType = std.ArrayListUnmanaged(T);

        const U = union(MemType) {
            Stack: StackType,
            Heap: HeapType,

            pub fn init(allocator: Allocator, size: usize) Error!U {
                if (size > stack_size) {
                    const heap = try HeapType.initCapacity(allocator, size);
                    return U{ .Heap = heap };
                } else {
                    const stack = try StackType.init(size);
                    return U{ .Stack = stack };
                }
            }

            pub fn append(self: *U, allocator: Allocator, item: T) Error!void {
                switch (self.*) {
                    .Stack => |*stack| {
                        const len = stack.len;
                        const capacity = stack.capacity();
                        if (len == capacity) {
                            const f = @intToFloat(f32, capacity);
                            const new_capacity: usize = @floatToInt(usize, f * 1.5);
                            var heap = try HeapType.initCapacity(new_capacity);
                            try heap.append(allocator, stack[0..len]);
                            self.* = U{ .Heap = heap };
                        } else {
                            stack.append(item);
                        }
                    },
                    .Heap => |*heap| {
                        try heap.append(allocator, item);
                    },
                }
            }

            pub fn deinit(self: *U, allocator: Allocator) void {
                switch (self) {
                    .Heap => |*heap| {
                        heap.deinit(allocator);
                    },
                    else => {},
                }
            }

            pub fn items(self: *U) []T {
                return switch (self) {
                    .Heap => |*heap| heap.item[0..heap.len],
                    .Stack => |*stack| stack.item[0..stack.len],
                };
            }
        };

        arr: U = undefined,

        pub fn init(allocator: Allocator, size: usize) Error!Self {
            return Self{ .arr = try U.init(allocator, size) };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.arr.deinit(allocator);
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
