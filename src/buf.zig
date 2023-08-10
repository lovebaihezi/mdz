const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Buf = struct {
    const Self = @This();

    data: []u8,
    len: usize = 0,
    
    pub fn initWithAllocator(allocator: Allocator, init_size: usize) Allocator.Error!Self {
        const buf = try allocator.alloc(u8, init_size);
        return .{
            .data = buf,
        };
    }

    pub fn initFromStack(buf: []u8, len: usize) Self {
        return .{
            .data = buf,
            .len = len,
            .on_stack = true,
        };
    }

    fn cal_len(data_len: usize, buf_len: usize) usize {
        const v: f32 = @floatFromInt(f32, data_len + buf_len) * 2;
        return @intFromFloat(usize, v);
    }

    pub fn appendBuf(self: *Self, allocator: Allocator, buf: []u8) Allocator.Error!void {
        if (self.len + buf.len > self.data.len) {
            const old_data = self.data;
            var new_data = try allocator.alloc(u8, cal_len(self.len + buf.len));
            @memcpy(new_data, old_data);
            @memcpy(new_data[self.len..], buf);
        } else {
            @memcpy(self.data[self.len..], buf);
        }
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        if (!self.on_stack) {
            allocator.free(self.data);
        }
    }
};

test "append buf to a on heap Buf" {
    var b = Buf.initWithAllocator(std.testing.allocator, 0);
    _ = b;
}
