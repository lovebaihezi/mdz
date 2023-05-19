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
        const contents = Container(Inner, 4).init(allocator, 0);
        return Self{ .contents = contents, .span = span };
    }

    pub fn addInner(self: *Self, allocator: Allocator, inner: Inner) Error!void {
        try self.contents.append(allocator, inner);
        _ = self.span.enlarge(inner.span.len);
    }
};

pub const Paragraph = struct {
    const Self = @This();

    lines: Container(Line, 2),
    span: Span,

    pub inline fn init(allocator: Allocator, span: Span) Error!Self {
        const arr = try Container(Line, 2).init(allocator, 0);
        return Self{ .lines = arr, .span = span };
    }

    pub inline fn addNewLine(self: *Self, allocator: Allocator, span: Span) Error!void {
        const line = try Line.init(allocator, span);
        try self.lines.append(allocator, line);
    }

    pub inline fn addPlainText(self: *Self, allocator: Allocator, span: Span) Error!void {
        if (self.lines.last_mut()) |line| {
            try line.contents.append(allocator, Inner.plainText(span));
        } else {
            var arr = try Container(Inner, 4).init(allocator, 0);
            try arr.append(allocator, Inner.plainText(span));
            self.lines.append(allocator, Line{
                .contents = arr,
                .span = span,
            });
        }
        _ = self.span.enlarge(span.len);
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};
