const std = @import("std");

const TestCase = struct {
    markdown: []const u8,
    html: []const u8,
    example: u64,
    start_line: u64,
    end_line: u64,
    section: []const u8,
};

const spec_url = "https://spec.commonmark.org/0.31.2/spec.json";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var response_body = std.ArrayList(u8).init(allocator);
    defer response_body.deinit();

    std.debug.print("Fetching test cases from {s}...\n", .{spec_url});
    const result = try client.fetch(.{
        .location = .{
            .url = spec_url,
        },
        .response_storage = .{ .dynamic = &response_body },
    });

    if (result.status != .ok) {
        std.debug.print("Failed to fetch spec.json: {}\n", .{result.status});
        return error.HttpRequestFailed;
    }

    std.debug.print("Parsing test cases...\n", .{});
    var parsed = try std.json.parseFromSlice([]TestCase, allocator, response_body.items, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    const test_cases = parsed.value;

    std.debug.print("Successfully parsed {d} test cases.\n", .{test_cases.len});
}
