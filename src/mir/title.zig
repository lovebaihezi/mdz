const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const Title = struct {
    const Self = @This();

    level: u8,
    ///I bet in 99% of markdown, the content will always be a simple text
    content: mir.paragraph.Line,
    span: Span,

    pub inline fn init(allocator: Allocator, level: u8, span: Span) Error!Title {
        const line = try mir.paragraph.Line.init(allocator, span);
        return Title{
            .level = level,
            .span = span,
            .content = line,
        };
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        const str = buffer[self.span.begin .. self.span.begin + self.span.len + 1];
        var iter = std.mem.tokenizeAny(u8, str, "\n");
        while (iter.next()) |s| {
            _ = try writer.write("|");
            _ = try writer.write(s);
            _ = try writer.write("\n");
        }
        for (0..level) |_| {
            _ = try writer.write("\t");
        }
        _ = try writer.write("Title:");
        try writer.print("{d}-{d}\n", .{ self.span.begin, self.span.begin + self.span.len });
        for (0..level) |_| {
            _ = try writer.write("\t");
        }
        try writer.print("level: {d}\n", .{self.level});
        try self.content.writeAST(buffer, writer, level + 1);
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        try writer.print("<title level=\"{d}\">\n", .{self.level});
        try self.content.writeXML(buffer, writer, level + 1);
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("</title>\n");
    }

    pub inline fn writeHTML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        try writer.print("<h{d} id=\"", .{self.level});
        _ = try self.content.writeRaw(writer, buffer);
        _ = try writer.write("\">");
        try self.content.writeHTML(buffer, writer, level + 1);
        try writer.print("</h{d}>\n", .{self.level});
    }
};
