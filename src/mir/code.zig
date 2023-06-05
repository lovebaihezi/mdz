const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const CodeBlock = struct {
    const Self = @This();

    metadata: Span,
    codes: Span,
    span: Span,

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        const str = buffer[self.span.begin .. self.span.begin + self.span.len];
        var iter = std.mem.tokenize(u8, str, "\n");
        while (iter.next()) |s| {
            _ = try writer.write(s);
            _ = try writer.write("\n");
        }
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("CodeBlock:");
        _ = try std.fmt.format(writer, "{d}-{d}\n", .{ self.span.begin, self.span.begin + self.span.len });
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        const metadata = buffer[self.metadata.begin .. self.metadata.begin + self.metadata.len];
        _ = try writer.write("Metadata:");
        _ = try std.fmt.format(writer, "{s}\n", .{metadata});
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Codes:\n");
        const codes = buffer[self.codes.begin .. self.codes.begin + self.codes.len];
        iter = std.mem.tokenize(u8, codes, "\n");
        while (iter.next()) |s| {
            _ = try writer.write(s);
            _ = try writer.write("\\n");
        }
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        _ = level;
        _ = try std.fmt.format(writer, "<code begin=\"{d}\" end=\"{d}\">", .{ self.span.begin, self.span.begin + self.span.len });
        const codes = buffer[self.codes.begin .. self.codes.begin + self.codes.len];
        _ = try writer.write(codes);
        _ = try writer.write("</code>");
    }

    pub inline fn writeHTML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        _ = level;
        _ = try std.fmt.format(writer, "<pre><code class=\"{s}\">", .{buffer[self.metadata.begin .. self.metadata.begin + self.metadata.len]});
        const codes = buffer[self.codes.begin .. self.codes.begin + self.codes.len];
        _ = try writer.write(codes);
        _ = try writer.write("</code></pre>");
    }
};
