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

pub const TableFormat = enum {
    center,
    left,
    right,
};

pub const Table = struct {
    const Self = @This();

    head: TableHead,
    format: TableFormat,
    rows: Container(TableRow, 4),
};
