const std = @import("std");
const table = @import("table.zig");
const list = @import("list.zig");
const utils = @import("utils.zig");

const Array = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const Span = utils.Span;

pub const TextKind = enum {
    Plain,
    Bold,
    Italic,
    BoldItalic,
    Strikethrough,
};

pub const Text = struct {
    kind: TextKind,
    content: Span,
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
    CodeSpan,
    LatexSpan,
    Image,
    Href,
    FootnoteRef,
};

// [^.+]
pub const FoodnoteRef = struct {
    id: Span,
};

pub const Inner = union(InnerKind) {
    Text: Text,
    CodeSpan: Span,
    LatexSpan: Span,
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
    id: ?Span = null,
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
