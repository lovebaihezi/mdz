const std = @import("std");
const utils = @import("../utils/lib.zig");
const Span = utils.Span;
const Allocator = std.mem.Allocator;

pub const Frontmatter = struct {
    const Self = @This();

    span: Span,

    pub inline fn init(span: Span) Self {
        return .{ .span = span };
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        _ = self;
        _ = allocator;
    }

    pub fn writeAST(self: Self, buffer: []const u8, stream: anytype, level: usize) !void {
        _ = level;
        const writer = stream;
        _ = try writer.write("Frontmatter: ");
        _ = try writer.write(buffer[self.span.begin .. self.span.begin + self.span.len]);
        _ = try writer.write("\n");
    }

    pub fn writeXML(self: Self, buffer: []const u8, stream: anytype, level: usize) !void {
        _ = level;
        const writer = stream;
        _ = try writer.write("<frontmatter>");
        _ = try writer.write(buffer[self.span.begin .. self.span.begin + self.span.len]);
        _ = try writer.write("</frontmatter>\n");
    }

    pub fn writeHTML(self: Self, buffer: []const u8, stream: anytype, level: usize) !void {
        _ = self;
        _ = buffer;
        _ = stream;
        _ = level;
        // Frontmatter is ignored in HTML
        // TODO: Handle frontmatter in HTML (maybe metadata?)
    }
};
