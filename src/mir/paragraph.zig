const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const Line = struct {
    const Self = @This();

    contents: Container(Inner, 4),
    span: Span,

    pub fn init(allocator: Allocator, span: Span) Error!Self {
        const contents = try Container(Inner, 4).init(allocator, 0);
        return Self{ .contents = contents, .span = span };
    }

    pub fn addInner(self: *Self, allocator: Allocator, inner: Inner) Error!void {
        try self.contents.append(allocator, inner);
        _ = self.span.enlarge(inner.span().len);
    }

    pub fn addPlainText(self: *Self, allocator: Allocator, text: Span) Error!void {
        try self.contents.append(allocator, Inner.plainText(text));
        _ = self.span.enlarge(text.len);
    }

    pub fn addCode(self: *Self, allocator: Allocator, code: Span) Error!void {
        try self.contents.append(allocator, try Inner.code(allocator, code));
        _ = self.span.enlarge(code.len);
    }

    pub fn addBold(self: *Self, allocator: Allocator, bold: Span) Error!void {
        try self.contents.append(allocator, try Inner.bold(bold));
        _ = self.span.enlarge(bold.len);
    }

    pub fn addItalic(self: *Self, allocator: Allocator, italic: Span) Error!void {
        try self.contents.append(allocator, try Inner.italic(italic));
        _ = self.span.enlarge(italic.len);
    }

    pub fn addLatex(self: *Self, allocator: Allocator, latex: Span) Error!void {
        try self.contents.append(allocator, try Inner.latex(latex));
        _ = self.span.enlarge(latex.len);
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        for (self.contents.items_mut()) |*item| {
            switch (item.*) {
                .Text => |*t| {
                    t.deinit(allocator);
                },
                else => {},
            }
        }
        self.contents.deinit(allocator);
    }

    pub fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Line:");
        _ = try std.fmt.format(writer, "{d}-{d}\n", .{ self.span.begin, self.span.begin + self.span.len });
        for (self.contents.items()) |item| {
            _ = try item.writeAST(buffer, writer, level + 1);
        }
    }
};

pub const Paragraph = struct {
    const Self = @This();

    lines: Container(Line, 2),
    span: Span,

    pub inline fn init(allocator: Allocator, span: Span) Error!Self {
        const arr = try Container(Line, 2).init(allocator, 0);
        return Self{ .lines = arr, .span = Span.new(span.begin, 0) };
    }

    pub inline fn addNewLine(self: *Self, allocator: Allocator, span: Span) Error!void {
        const line = try Line.init(allocator, span);
        try self.lines.append(allocator, line);
        _ = self.span.enlarge(span.len);
    }

    pub inline fn addPlainText(self: *Self, allocator: Allocator, span: Span) Error!void {
        try self.addInner(allocator, Inner.plainText(span));
    }

    pub inline fn addCode(self: *Self, allocator: Allocator, span: Span) Error!void {
        try self.addInner(allocator, try Inner.code(allocator, span));
    }

    pub inline fn addInner(self: *Self, allocator: Allocator, inner: Inner) Error!void {
        if (self.lines.last_mut()) |line| {
            try line.addInner(allocator, inner);
        } else {
            var arr = try Container(Inner, 4).init(allocator, 0);
            try arr.append(allocator, inner);
            try self.lines.append(allocator, Line{
                .contents = arr,
                .span = inner.span(),
            });
        }
        // FIXME: error span len,
        _ = self.span.enlarge(inner.span().len);
        // std.debug.print("\t|paragraph span enlarge {} to {}|\t", .{ inner.span().len, self.span.len });
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        for (self.lines.items_mut()) |*item| {
            item.deinit(allocator);
        }
        self.lines.deinit(allocator);
    }

    pub inline fn writeAST(self: Self, buffer: []const u8, writer: anytype, level: usize) !void {
        const str = buffer[self.span.begin .. self.span.begin + self.span.len];
        var iter = std.mem.tokenize(u8, str, "\n");
        while (iter.next()) |s| {
            _ = try writer.write("|");
            _ = try writer.write(s);
            _ = try writer.write("\n");
        }
        for (0..level) |_| {
            _ = try writer.write(" ");
        }
        _ = try writer.write("Paragraph:");
        _ = try std.fmt.format(writer, "{d}-{d}\n", .{ self.span.begin, self.span.begin + self.span.len });
        for (self.lines.items()) |item| {
            _ = try item.writeAST(buffer, writer, level + 1);
        }
    }
};
