const std = @import("std");

const Array = std.ArrayListAlignedUnmanaged;

pub const TableItem = struct {};

pub const TableHead = struct {
    columns: Array(TableItem),
};

pub const TableRow = struct {};

pub const TableFormat = enum {
    center,
    left,
    right,
};

pub const Table = struct {
    const Self = @This();

    head: TableHead,
    format: TableFormat,
    rows: Array(TableRow),
};
