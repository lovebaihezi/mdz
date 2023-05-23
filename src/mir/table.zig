const std = @import("std");
const utils = @import("../mdz.zig").utils;
const mir = @import("lib.zig");

const Container = mir.Container;
const Span = utils.Span;
const Inner = mir.text.Inner;
const Allocator = std.mem.Allocator;
const Error = mir.Error;

pub const TableItem = struct {
    span: Span,
};

pub const TableHead = struct {
    columns: Container(TableItem, 4),
};

pub const TableRow = struct {
    span: Span,
};

pub const TableFormat = enum(usize) {
    center,
    left,
    right,
};

pub const Table = struct {
    const Self = @This();

    head: TableHead,
    format: Container(TableFormat, 4),
    rows: Container(TableRow, 4),

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        self.head.deinit(allocator);
        self.format.deinit(allocator);
        self.rows.deinit(allocator);
    }
};
