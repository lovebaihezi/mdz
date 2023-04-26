const std = @import("std");
const table = @import("table.zig");
const list = @import("list.zig");
const utils = @import("utils.zig");

//TODO: Combine std.boundArray and std.ArrayListUnmanaged to reduce allocation on heap
const Allocator = std.mem.Allocator;
const Span = utils.Span;

pub const Container = std.ArrayListUnmanaged;

pub const Texts = Container(Text);

pub const TextKind = enum {
    Plain,
    Bold,
    Italic,
    Strikethrough,
};

pub const Text = union(TextKind) {
    const Self = @This();

    Plain: Span,
    Bold: Texts,
    Italic: Texts,
    Strikethrough: Texts,

    pub inline fn plain(text: Span) Self {
        return Self{ .Plain = text };
    }
};

pub const Href = struct {
    text: Text,
    link: Span,
    alt: ?Span = null,
};

pub const Image = struct {
    alt: Span,
    imagePath: Span,
};

pub const InnerKind = enum {
    Text,
    Code,
    Latex,
    Image,
    Href,
    FootNoteRef,
};

// [^.+]
pub const FootNoteRef = struct {
    id: Span,
    content: Text,
};

pub const Inner = union(InnerKind) {
    const Self = @This();

    Text: Text,
    Code: Span,
    Latex: Span,
    Image: Image,
    Href: Href,
    FootNoteRef: FootNoteRef,

    pub inline fn plainText(text: Span) Self {
        return Self{ .Text = Text.plain(text) };
    }
};

pub const Title = struct {
    const Self = @This();

    level: u8,
    id: ?Span = null,
    ///I bet in 99% of markdown, the content will always be a simple text
    content: Container(Inner),
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
};
