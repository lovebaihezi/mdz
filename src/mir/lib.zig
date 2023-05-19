const std = @import("std");
const utils = @import("../mdz.zig").utils;

const Allocator = std.mem.Allocator;
const Span = utils.Span;
const smallarr = @import("../small_arr.zig");

pub const Error = @import("../dfa/lib.zig").ParseError;
pub const table = @import("table.zig");
pub const list = @import("list.zig");
pub const code = @import("code.zig");
pub const title = @import("title.zig");
pub const paragraph = @import("paragraph.zig");
pub const text = @import("text.zig");
pub const quote = @import("quote.zig");
pub const Container = smallarr.SmallArray;
pub const Texts = Container(text.Text, 4);
pub const Decorations = text.Decorations;

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
    Title: title.Title,
    /// Double end line means block done, one endline means nothing
    Paragraph: paragraph.Paragraph,
    /// One end line
    Quote: quote.Quote,
    /// One end line
    Table: table.Table,
    /// One end line
    OrderedList: list.OrderedList,
    /// One end line
    BulletList: list.BulletList,
    /// One end line
    Code: code.CodeBlock,
    /// Double end line
    ThematicBreak: void,
    // One end line
    Footnote: paragraph.Paragraph,

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        switch (self.*) {
            .Title => |*t| t.deinit(allocator),
            .Paragraph => |*p| p.deinit(allocator),
            else => {},
        }
    }

    pub fn writeAST(self: *const Self, writer: anytype) !void {
        _ = writer;
        _ = self;
        // try switch (self.*) {
        //     .Title => |*t| t.writeAST(writer),
        //     .Paragraph => |*p| p.writeAST(writer),
        //     .Code => |*c| c.writeAST(writer),
        //     .Quote => |*q| q.writeAST(writer),
        //     .Table => |*t| t.writeAST(writer),
        //     .OrderedList => |*l| l.writeAST(writer),
        //     .BulletList => |*l| l.writeAST(writer),
        //     .ThematicBreak => writer.write("ThematicBreak\n"),
        //     .Footnote => |*f| f.writeAST(writer),
        // };
    }
};
