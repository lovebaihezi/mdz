const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const OrderedList = struct {
    const Self = @This();

    number: u32,
    content: mir.paragraph.Line,

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};
pub const BulletList = struct {
    const Self = @This();

    content: mir.paragraph.Line,

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};
