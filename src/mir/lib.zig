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
    // Table,
    OrderedList,
    BulletList,
    Code,
    ThematicBreak,
    Quote,
    // Footnote,
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
    // Table: table.Table,
    /// One end line
    OrderedList: list.OrderedList,
    /// One end line
    BulletList: list.BulletList,
    /// One end line
    Code: code.CodeBlock,
    /// Double end line
    ThematicBreak: void,
    // One end line
    // Footnote: paragraph.Line,

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        switch (self.*) {
            .Title => |*t| t.deinit(allocator),
            .Paragraph => |*p| p.deinit(allocator),
            .Quote => |*q| q.deinit(allocator),
            .OrderedList => |*l| l.deinit(allocator),
            .BulletList => |*l| l.deinit(allocator),
            else => {},
        }
    }

    pub inline fn addCode(self: *Self, allocator: Allocator, s: Span) !void {
        try switch (self.*) {
            .Title => |*t| t.content.addCode(allocator, s),
            .Paragraph => |*p| p.addCode(allocator, s),
            .Quote => |*q| q.content.addCode(allocator, s),
            .BulletList => |*b| b.content.addCode(allocator, s),
            .OrderedList => |*o| o.content.addCode(allocator, s),
            else => unreachable,
        };
    }

    pub inline fn span(self: Self) Span {
        switch (self) {
            .Title => |t| t.span,
            .Paragraph => |p| p.span,
            .Quote => |q| q.span,
            .BulletList => |b| b.span,
            .OrderedList => |o| o.span,
            else => unreachable,
        }
    }

    pub fn writeAST(self: Self, buffer: []const u8, stream: anytype) !void {
        var bw = std.io.bufferedWriter(stream);
        var writer = bw.writer();
        _ = try writer.write("--------------------------\n");
        switch (self) {
            .Title => |t| _ = try t.writeAST(buffer, writer, 0),
            .Paragraph => |p| _ = try p.writeAST(buffer, writer, 0),
            .Code => |c| try c.writeAST(buffer, writer, 0),
            // .Quote => |q| q.writeAST(writer, 0),
            // .OrderedList => |l| l.writeAST(writer, 0),
            // .BulletList => |l| l.writeAST(writer, 0),
            .ThematicBreak => _ = try writer.write("\tThematicBreak\n"),
            else => {},
        }
        _ = try writer.write("--------------------------\n");
        try bw.flush();
    }

    pub fn writeXML(self: Self, buffer: []const u8, stream: anytype) !void {
        var bw = std.io.bufferedWriter(stream);
        var writer = bw.writer();
        switch (self) {
            .Title => |t| try t.writeXML(buffer, writer, 0),
            .Paragraph => |p| try p.writeXML(buffer, writer, 0),
            .Code => |c| try c.writeXML(buffer, writer, 0),
            // .Quote => |q| q.writeXML(writer, 0),
            // .OrderedList => |l| l.writeXML(writer, 0),
            // .BulletList => |l| l.writeXML(writer, 0),
            .ThematicBreak => _ = try writer.write("<ThematicBreak></ThemanticBreak>\n"),
            else => {},
        }
        try bw.flush();
    }

    pub fn writeHTML(self: Self, buffer: []const u8, stream: anytype) !void {
        var bw = std.io.bufferedWriter(stream);
        var writer = bw.writer();
        switch (self) {
            .Title => |t| try t.writeHTML(buffer, writer, 0),
            .Paragraph => |p| try p.writeHTML(buffer, writer, 0),
            .Code => |c| try c.writeHTML(buffer, writer, 0),
            // .Quote => |q| q.writeHTML(writer, 0),
            // .OrderedList => |l| l.writeHTML(writer, 0),
            // .BulletList => |l| l.writeHTML(writer, 0),
            .ThematicBreak => _ = try writer.write("<ThematicBreak></ThemanticBreak>\n"),
            else => {},
        }
        try bw.flush();
    }
};
