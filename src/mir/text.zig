const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const TextKind = enum(u8) {
    const Self = @This();

    Bold,
    Italic,
    Strikethrough,
    LaTex,
    Code,

    pub inline fn toHtmlTag(self: Self) []const u8 {
        switch (self) {
            .Bold => return "b",
            .Italic => return "i",
            .Strikethrough => return "s",
            .Code => return "code",
            .LaTex => return "pre",
        }
    }
};

pub const TextKindCount = 5;

pub const Decorations = std.bit_set.StaticBitSet(TextKindCount);

pub const Text = struct {
    const Self = @This();

    decorations: Decorations = Decorations.initEmpty(),
    span: Span,

    pub inline fn plain(text: Span) Self {
        return Self{ .span = text };
    }

    pub inline fn code(text: Span) Self {
        var self = Self.plain(text);
        self.addDecoration(.Code);
        return self;
    }

    pub inline fn bold(text: Span) Self {
        var self = Self.plain(text);
        self.addDecoration(.Bold);
        return self;
    }

    pub inline fn italic(text: Span) Self {
        var self = Self.plain(text);
        self.addDecoration(.Italic);
        return self;
    }

    pub inline fn strikethrough(text: Span) Self {
        var self = Self.plain(text);
        self.addDecoration(.Strikethrough);
        return self;
    }

    pub inline fn latex(text: Span) Self {
        var self = Self.plain(text);
        self.addDecoration(.LaTex);
        return self;
    }

    pub inline fn addDecoration(self: *Self, decoration: TextKind) void {
        self.decorations.setValue(@enumToInt(decoration), true);
    }

    pub inline fn enlarge(self: *Self, size: usize) void {
        self.span.len += size;
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Text");
        for (0..TextKindCount) |i| {
            if (self.decorations.isSet(i)) {
                _ = try writer.write(",");
                _ = try writer.write(@tagName(@intToEnum(TextKind, i)));
            }
        }
        _ = try std.fmt.format(writer, "\t{d}-{d}", .{ self.span.begin, self.span.begin + self.span.len });
        _ = try std.fmt.format(writer, "\t{s}\n", .{buffer[self.span.begin .. self.span.begin + self.span.len]});
    }

    pub inline fn writeXML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try std.fmt.format(writer, "<text begin=\"{d}\" end=\"{d}\"", .{ self.span.begin, self.span.begin + self.span.len });
        _ = try writer.write(" type=\"");
        for (0..TextKindCount) |i| {
            if (self.decorations.isSet(i)) {
                _ = try writer.write(@tagName(@intToEnum(TextKind, i)));
                if (i != TextKindCount - 1) {
                    _ = try writer.write(",");
                }
            }
        }
        _ = try writer.write("\"");
        _ = try writer.write(">");
        _ = try std.fmt.format(writer, "{s}", .{buffer[self.span.begin .. self.span.begin + self.span.len]});
        _ = try writer.write("</text>\n");
    }

    pub inline fn writeHTML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        _ = level;
        for (0..TextKindCount) |i| {
            if (self.decorations.isSet(i)) {
                const e = @intToEnum(TextKind, i);
                const tag = e.toHtmlTag();
                _ = try std.fmt.format(writer, "<{s}>", .{tag});
            }
        }
        _ = try writer.write(buffer[self.span.begin .. self.span.begin + self.span.len]);
        for (0..TextKindCount) |i| {
            if (self.decorations.isSet(i)) {
                const tag = @intToEnum(TextKind, i).toHtmlTag();
                _ = try std.fmt.format(writer, "</{s}>", .{tag});
            }
        }
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
        _ = try std.fmt.format(writer, "<href begin=\"{d}\" end=\"{d}\">", .{ self.span.begin, self.span.begin + self.span.len });
        _ = try std.fmt.format(writer, "<text>{s}</text>", .{buffer[self.text.begin .. self.text.begin + self.text.len]});
        _ = try std.fmt.format(writer, "<link>{s}</link>", .{buffer[self.link.begin .. self.link.begin + self.link.len]});
        _ = try writer.write("</href>\n");
    }

    pub inline fn writeHTML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("<a href=\"");
        _ = try writer.write(buffer[self.link.begin .. self.link.begin + self.link.len]);
        _ = try writer.write("\">");
        _ = try writer.write(buffer[self.text.begin .. self.text.begin + self.text.len]);
        _ = try writer.write("</a>");
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

    pub inline fn writeHTML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("<img src=\"");
        _ = try writer.write(buffer[self.imagePath.begin .. self.imagePath.begin + self.imagePath.len]);
        _ = try writer.write("\" alt=\"");
        _ = try writer.write(buffer[self.alt.begin .. self.alt.begin + self.alt.len]);
        _ = try writer.write("\" />\n");
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

    pub inline fn code(code_s: Span) Self {
        return Self{ .Text = Text.code(code_s) };
    }

    pub inline fn bold(text: Span) Self {
        return Self{ .Text = Text.bold(text) };
    }

    pub inline fn italic(text: Span) Self {
        return Self{ .Text = Text.italic(text) };
    }

    pub inline fn latex(text: Span) Self {
        return Self{ .Text = Text.latex(text) };
    }

    pub inline fn enlarge(self: *Self, size: usize) void {
        switch (self) {
            .Text => self.Text.enlarge(size),
            .Image => self.Image.enlarge(size),
            .Href => self.Href.enlarge(size),
        }
    }

    pub inline fn rawText(self: Self) Span {
        switch (self) {
            .Text => return self.Text.span,
            .Image => return self.Image.alt,
            .Href => return self.Href.text,
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

    pub inline fn writeHTML(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        switch (self) {
            .Text => |text| {
                _ = try text.writeHTML(buffer, writer, level + 1);
            },
            .Image => |image| {
                _ = try image.writeHTML(buffer, writer, level + 1);
            },
            .Href => |href| {
                _ = try href.writeHTML(buffer, writer, level + 1);
            },
        }
    }
};
