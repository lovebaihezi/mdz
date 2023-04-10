const std = @import("std");
const table = @import("table.zig");
const list = @import("list.zig");

const Array = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

pub const TextKind = enum {
    Plain,
    Bold,
    Italic,
    BoldItalic,
    Strikethrough,
};

pub const Text = struct {
    kind: TextKind,
    content: []const u8,
};

pub const Href = struct {
    text: Text,
    link: []const u8,
    alt: ?[]const u8 = null,
};

pub const Image = struct {
    alt: []const u8,
    imagePath: []const u8,
};

pub const InnerKind = enum {
    Text,
    CodeSpan,
    LatexSpan,
    Image,
    Href,
    FootnoteRef,
};

// [^.+]
pub const FoodnoteRef = struct {
    id: []const u8,
};

pub const Inner = union(InnerKind) {
    Text: Text,
    CodeSpan: []const u8,
    LatexSpan: []const u8,
    Image: Image,
    Href: Href,
    FootnoteRef: FoodnoteRef,
};

pub const TitleLevel = enum {
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
};

pub const Title = struct {
    level: TitleLevel,
    id: ?[]const u8 = null,
    ///I bet in 99% of markdown, the content will always be a simple text
    content: Array(Inner),
};

pub const Paragraph = struct {
    content: Array(Inner),
};

pub const Quote = struct {
    level: usize,
    content: Array(Inner),
};

pub const CodeBlock = struct {
    Metadata: []const u8,
    Codes: []const u8,
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

/// EOF means block done
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
};
