const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const TextKind = enum(u8) {
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

    pub inline fn deinit(self: Self) void {
        if (self.decorations) |decorations| {
            decorations.deinit();
        }
    }

    pub inline fn addDecoration(self: *Self, allocator: Allocator, decoration: TextKind) Error!void {
        if (self.decorations) |decorations| {
            decorations.append(allocator, decoration);
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
};

pub const Image = struct {
    const Self = @This();

    alt: Span,
    imagePath: Span,
    span: Span,

    pub inline fn enlarge(self: *Self, size: usize) void {
        self.alt.len += size;
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

    pub inline fn enlarge(self: *Self, size: usize) void {
        switch (self) {
            .Text => self.Text.enlarge(size),
            .Image => self.Image.enlarge(size),
            .Href => self.Href.enlarge(size),
        }
    }
};
