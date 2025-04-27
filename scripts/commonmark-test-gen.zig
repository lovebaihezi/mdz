const std = @import("std");

const main_url = "https://spec.commonmark.org/";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // TODO(chaibowen): fetch spec.json then gen zig source code
    const client = std.http.Client{
        .allocator = allocator,
    };
    client.fetch(.{});
}
