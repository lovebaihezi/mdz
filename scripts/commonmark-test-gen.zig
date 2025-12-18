const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const output_path = "src/commonmark_spec_tests.zig";

    // Check if file exists to avoid regenerating
    if (std.fs.cwd().access(output_path, .{})) |_| {
         std.debug.print("File {s} exists, skipping generation.\n", .{output_path});
         return;
    } else |err| {
        if (err != std.fs.File.OpenError.FileNotFound) {
             return err;
        }
    }

    std.debug.print("Fetching CommonMark spec...\n", .{});

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse("https://spec.commonmark.org/0.31.2/spec.json");

    var req = try client.request(.GET, uri, .{
        .headers = .{ .accept_encoding = .{ .override = "identity" } },
    });
    defer req.deinit();

    try req.sendBodiless();

    var redirect_buf: [4096]u8 = undefined;
    var response = try req.receiveHead(&redirect_buf);

    if (response.head.status != .ok) {
        std.debug.print("Failed to fetch spec: {}\n", .{response.head.status});
        return error.FetchFailed;
    }

    var transfer_buf: [4096]u8 = undefined;
    var reader = response.reader(&transfer_buf);
    const body = try reader.allocRemaining(allocator, .limited(10 * 1024 * 1024));
    defer allocator.free(body);

    std.debug.print("Spec fetched ({} bytes).\nBody snippet: {s}\nParsing JSON...\n", .{body.len, body[0..@min(200, body.len)]});

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, body, .{});
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .array) {
        return error.InvalidJsonFormat;
    }

    std.debug.print("Generating Zig tests...\n", .{});

    var file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    var file_buf: [4096]u8 = undefined;
    var f_writer = file.writer(&file_buf);
    const writer = &f_writer.interface;

    try writer.writeAll(
        \\//! Generated CommonMark specification tests
        \\//! Do not edit manually.
        \\
        \\const std = @import("std");
        \\const testing = std.testing;
        \\const Allocator = std.mem.Allocator;
        \\const Parser = @import("mdz.zig").parser.Parser;
        \\const Lexer = @import("mdz.zig").lexer.Lexer;
        \\const Block = @import("mdz.zig").mir.Block;
        \\
        \\const page_size = 4096 * 1024;
        \\
        \\fn parseMarkdownToHtml(allocator: Allocator, markdown: []const u8) ![]u8 {
        \\    var result = std.ArrayList(u8){};
        \\    const result_writer = result.writer(allocator);
        \\
        \\    var parser = Parser.init(allocator);
        \\    const buffer = try allocator.alloc(u8, markdown.len);
        \\    defer allocator.free(buffer);
        \\    @memcpy(buffer, markdown);
        \\    var lexer = Lexer.init(buffer);
        \\
        \\    while (try parser.next(&lexer)) |block| {
        \\        try block.writeHTML(buffer, result_writer);
        \\    }
        \\
        \\    return result.toOwnedSlice(allocator);
        \\}
        \\
        \\fn normalizeHtml(allocator: Allocator, html: []const u8) ![]u8 {
        \\    var result = std.ArrayList(u8){};
        \\    defer result.deinit(allocator);
        \\
        \\    for (html) |char| {
        \\        switch (char) {
        \\            '\r' => {}, // Skip \r, normalize to \n only
        \\            else => try result.append(allocator, char),
        \\        }
        \\    }
        \\
        \\    return result.toOwnedSlice(allocator);
        \\}
        \\
        \\
    );

    var idx: usize = 0;
    for (root.array.items) |item| {
        if (item != .object) continue;
        const obj = item.object;

        const markdown = obj.get("markdown").?.string;
        const html = obj.get("html").?.string;
        const section = obj.get("section").?.string;
        const example_number = obj.get("example").?.integer;

        idx += 1;

        try writer.print(
            \\
            \\// Example {d} from section "{s}"
            \\test "commonmark_spec_{d}" {{
            \\    const allocator = testing.allocator;
            \\    const markdown =
        , .{example_number, section, idx});

        try writeStringLiteral(writer, markdown);

        try writer.writeAll(";\n    const expected_html = ");

        try writeStringLiteral(writer, html);

        try writer.writeAll(
            \\;
            \\
            \\    const actual_html = try parseMarkdownToHtml(allocator, markdown);
            \\    defer allocator.free(actual_html);
            \\
            \\    const normalized_expected = try normalizeHtml(allocator, expected_html);
            \\    defer allocator.free(normalized_expected);
            \\
            \\    const normalized_actual = try normalizeHtml(allocator, actual_html);
            \\    defer allocator.free(normalized_actual);
            \\
            \\    try testing.expectEqualStrings(normalized_expected, normalized_actual);
            \\}
            \\
        );
    }

    std.debug.print("Generated {d} tests in {s}.\n", .{idx, output_path});
}

fn writeStringLiteral(writer: anytype, str: []const u8) !void {
    try writer.writeAll("\"");
    for (str) |char| {
        switch (char) {
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            '\\' => try writer.writeAll("\\\\"),
            '"' => try writer.writeAll("\\\""),
            else => {
                if (std.ascii.isPrint(char)) {
                    const bytes = [1]u8{char};
                    try writer.writeAll(&bytes);
                } else {
                    try writer.print("\\x{x:0>2}", .{char});
                }
            },
        }
    }
    try writer.writeAll("\"");
}
