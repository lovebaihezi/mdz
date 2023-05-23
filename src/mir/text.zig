const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const TextKind = enum(usize) {
    Bold,
    Italic,
    Strikethrough,
    Code,
    Latex,
};

pub const Decorations = Container(TextKind, 4);

pub const Text = struct {
    const Self = @This();

    decorations: ?Decorations = null,
    span: Span,

    pub inline fn plain(text: Span) Self {
        return Self{ .span = text, .decorations = null };
    }

    pub inline fn code(allocator: Allocator, text: Span) Error!Self {
        var self = Self.plain(text);
        try self.addDecoration(allocator, .Code);
        return self;
    }

    pub inline fn bold(allocator: Allocator, text: Span) Error!Self {
        var self = Self.plain(text);
        try self.addDecoration(allocator, .Bold);
        return self;
    }
    pub inline fn italic(allocator: Allocator, text: Span) Error!Self {
        var self = Self.plain(text);
        try self.addDecoration(allocator, .Italic);
        return self;
    }
    pub inline fn strikethrough(allocator: Allocator, text: Span) Error!Self {
        var self = Self.plain(text);
        try self.addDecoration(allocator, .Strikethrough);
        return self;
    }
    pub inline fn latex(allocator: Allocator, text: Span) Error!Self {
        var self = Self.plain(text);
        try self.addDecoration(allocator, .Latex);
        return self;
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        if (self.decorations) |*decorations| {
            decorations.deinit(allocator);
        }
    }

    pub inline fn addDecoration(self: *Self, allocator: Allocator, decoration: TextKind) Error!void {
        if (self.decorations) |*decorations| {
            try decorations.append(allocator, decoration);
        } else {
            var decorations = try Decorations.init(allocator, 0);
            try decorations.append(allocator, decoration);
            self.decorations = decorations;
        }
    }

    pub inline fn enlarge(self: *Self, size: usize) void {
        self.span.len += size;
    }

    pub inline fn cloneDecorations(self: *const Self, allocator: Allocator) Error!Decorations {
        if (self.decorations) |decorations| {
            const newDecorations = try Decorations.init(allocator, decorations.len);
            for (decorations.items()) |decoration| {
                try newDecorations.append(allocator, decoration);
            }
            return newDecorations;
        } else {
            return try Decorations.init(allocator, 0);
        }
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Text");
        if (self.decorations) |decorations| {
            for (decorations.items()) |decoration| {
                _ = try writer.write(",");
                _ = try writer.write(@tagName(decoration));
            }
        }
        _ = try std.fmt.format(writer, "\t{d}-{d}", .{ self.span.begin, self.span.begin + self.span.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.span.begin .. self.span.begin + self.span.len]});
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("<text");
        if (self.decorations) |decorations| {
            _ = try writer.write(" decor=\"");
            for (decorations.items(), 0..) |decoration, i| {
                _ = try writer.write(@tagName(decoration));
                if (i != decorations.len() - 1) {
                    _ = try writer.write(",");
                }
            }
            _ = try writer.write("\"");
        }
        _ = try writer.write(">");
        _ = try std.fmt.format(writer, "{s}", .{buffer[self.span.begin .. self.span.begin + self.span.len]});
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("</text>\n");
    }
};

pub const Href = struct {
    const Self = @This();

    text: Span,
    link: Span,
    span: Span,

    pub inline fn enlarge(self: *Self, size: usize) void {
        self.text.len += size;
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Href");
        _ = try std.fmt.format(writer, "\t{d}-{d}", .{ self.span.begin, self.span.begin + self.span.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.span.begin .. self.span.begin + self.span.len]});
        for (0..level + 1) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Text");
        _ = try std.fmt.format(writer, "\t{d}-{d}", .{ self.text.begin, self.text.begin + self.text.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.text.begin .. self.text.begin + self.text.len]});
        for (0..level + 1) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Link");
        _ = try std.fmt.format(writer, "\t{d}-{d}", .{ self.link.begin, self.link.begin + self.link.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.link.begin .. self.link.begin + self.link.len]});
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("<href>");
        _ = try std.fmt.format(writer, "<text>{s}</text>", .{buffer[self.text.begin .. self.text.begin + self.text.len]});
        _ = try std.fmt.format(writer, "<link>{s}</link>", .{buffer[self.link.begin .. self.link.begin + self.link.len]});
        _ = try writer.write("</href>\n");
    }
};

pub const Image = struct {
    const Self = @This();

    alt: Span,
    imagePath: Span,
    span: Span,

    pub inline fn enlarge(self: *Self, size: usize) void {
        self.alt.len += size;
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Image");
        _ = try std.fmt.format(writer, "\t{d}-{d}", .{ self.span.begin, self.span.begin + self.span.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.span.begin .. self.span.begin + self.span.len]});
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try std.fmt.format(writer, "Alt\t{d}-{d}", .{ self.alt.begin, self.alt.begin + self.alt.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.alt.begin .. self.alt.begin + self.alt.len]});
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try std.fmt.format(writer, "URL\t{d}-{d}", .{ self.imagePath.begin, self.imagePath.begin + self.imagePath.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.imagePath.begin .. self.imagePath.begin + self.imagePath.len]});
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("<image>\n");
        for (0..level + 1) |_| {
            _ = try writer.write(" ");
        }
        _ = try std.fmt.format(writer, "<url>{s}</url>\n", .{buffer[self.imagePath.begin .. self.imagePath.begin + self.imagePath.len]});
        for (0..level + 1) |_| {
            _ = try writer.write(" ");
        }
        _ = try std.fmt.format(writer, "<alt>{s}</alt>\n", .{buffer[self.alt.begin .. self.alt.begin + self.alt.len]});
        _ = try writer.write("</image>\n");
    }
};

pub const InnerKind = enum {
    Text,
    Image,
    Href,
};

pub const Inner = union(InnerKind) {
    const Self = @This();

    Text: Text,
    Image: Image,
    Href: Href,

    pub inline fn plainText(text: Span) Self {
        return Self{ .Text = Text.plain(text) };
    }

    pub inline fn code(allocator: Allocator, code_s: Span) Error!Self {
        return Self{ .Text = try Text.code(allocator, code_s) };
    }

    pub inline fn enlarge(self: *Self, size: usize) void {
        switch (self) {
            .Text => self.Text.enlarge(size),
            .Image => self.Image.enlarge(size),
            .Href => self.Href.enlarge(size),
        }
    }

    pub inline fn span(self: Self) Span {
        switch (self) {
            .Text => return self.Text.span,
            .Image => return self.Image.span,
            .Href => return self.Href.span,
        }
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        switch (self) {
            .Text => try self.Text.writeAST(buffer, writer, level),
            .Image => try self.Image.writeAST(buffer, writer, level),
            .Href => try self.Href.writeAST(buffer, writer, level),
        }
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        switch (self) {
            .Text => try self.Text.writeXML(buffer, writer, level),
            .Image => try self.Image.writeXML(buffer, writer, level),
            .Href => try self.Href.writeXML(buffer, writer, level),
        }
    }
};
