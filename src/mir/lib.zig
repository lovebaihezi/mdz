const std = @import("std");
const table = @import("table.zig");
const list = @import("list.zig");
const utils = @import("../mdz.zig").utils;

//TODO: Combine std.boundArray and std.ArrayListUnmanaged to reduce allocation on heap
const Allocator = std.mem.Allocator;
const Span = utils.Span;
const smallarr = @import("../small_arr.zig");

pub const Container = smallarr.SmallArray;

pub const Texts = Container(Text, 4);

pub const TextKind = enum {
    Bold,
    Italic,
    Strikethrough,
    Code,
    Latex,
};

pub const Text = struct {
    const Self = @This();

    decorations: ?Container(TextKind, 4) = null,
    span: Span,

    pub inline fn plain(text: Span) Self {
        return Self{ .Plain = text };
    }
};

pub const Href = struct {
    text: Span,
    link: Span,
    alt: ?Span = null,
};

pub const Image = struct {
    alt: Span,
    imagePath: Span,
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
};

pub const Title = struct {
    const Self = @This();

    level: u8,
    id: ?Span = null,
    ///I bet in 99% of markdown, the content will always be a simple text
    content: Container(Inner, 4),
    span: Span,

    pub inline fn initWithAllocator(allocator: Allocator, level: u8, span: Span) Allocator.Error!Title {
        var arr: Container(Inner) = try Container(Inner).initCapacity(allocator, 1);

        return Title{
            .level = level,
            .span = span,
            .content = arr,
        };
    }

    pub inline fn addContent(self: *Self, allocator: Allocator, content: Inner) Allocator.Error!void {
        try self.content.append(allocator, content);
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};

pub const Paragraph = struct {
    const Self = @This();

    content: Container(Inner),
    span: Span,

    pub inline fn initWithAllocator(allocator: Allocator, span: Span) Allocator.Error!Self {
        const arr = try Container(Inner).initCapacity(allocator, 1);
        return Self{ .content = arr, .span = span };
    }

    pub inline fn addPlainText(self: *Self, allocator: Allocator, span: Span) Allocator.Error!void {
        try self.content.append(allocator, Inner.plainText(span));
        if (self.span.len < span.begin) {
            self.span.len = span.begin;
        }
        _ = self.span.enlarge(span.len);
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};

pub const Quote = struct {
    level: usize,
    content: Container(Inner),
    span: Span,
};

pub const CodeBlock = struct {
    Metadata: Span,
    Codes: Span,
};

pub const BlockTag = enum {
    const Self = @This();

    Title,
    Paragraph,
    Table,
    OrderedList,
    BulletList,
    Code,
    ThematicBreak,
    Quote,
    Footnote,
};

/// # Block
///
/// ## Middle represent of Markdown
///
/// target lang: JSON, XML, HTML, LaTex
///
/// ## Q&A
pub const Block = union(BlockTag) {
    const Self = @This();

    /// Non-Strict: One end line, Strict : Double end line
    Title: Title,
    /// Double end line means block done, one endline means nothing
    Paragraph: Paragraph,
    /// One end line
    Quote: Quote,
    /// One end line
    Table: table.Table,
    /// One end line
    OrderedList: list.OrderedList,
    /// One end line
    BulletList: list.BulletList,
    /// One end line
    Code: CodeBlock,
    /// Double end line
    ThematicBreak: void,
    // One end line
    Footnote: Paragraph,

    pub inline fn title(item: Title) Self {
        return Self{ .Title = item };
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        switch (self.*) {
            .Title => |*t| t.deinit(allocator),
            .Paragraph => |*p| p.deinit(allocator),
            else => {},
        }
    }

    pub inline fn paragraph(p: Paragraph) Self {
        return Self{ .Paragraph = p };
    }

    pub fn writeAST(self: *const Self, write: anytype) !void {
        _ = write;
        _ = self;
    }
};
