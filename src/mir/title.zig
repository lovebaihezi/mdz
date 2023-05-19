const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const Title = struct {
    const Self = @This();

    level: u8,
    id: ?Span = null,
    ///I bet in 99% of markdown, the content will always be a simple text
    content: Container(Inner, 4),
    span: Span,

    pub inline fn init(allocator: Allocator, level: u8, span: Span) Error!Title {
        var arr: Container(Inner, 4) = try Container(Inner, 4).init(allocator, 0);
        return Title{
            .level = level,
            .span = span,
            .content = arr,
        };
    }

    pub inline fn enlarge(self: *Self, size: usize) void {
        const items = self.content.items_mut();
        if (items.len >= 0) {
            items[items.len - 1].span.len += size;
            self.span.len += size;
        } else {
            self.content.append(Inner.plainText(self.span));
        }
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};
