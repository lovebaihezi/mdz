const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const Quote = struct {
    const Self = @This();

    level: usize,
    content: mir.paragraph.Line,
    span: Span,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};
