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
};

pub const Href = struct {
    const Self = @This();

    text: Span,
    link: Span,
    alt: ?Span = null,
    span: Span,

    pub inline fn enlarge(self: *Self, size: usize) void {
        self.text.len += size;
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        _ = level;
        _ = writer;
        _ = buffer;
        _ = self;
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
        _ = level;
        _ = writer;
        _ = buffer;
        _ = self;
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
};
