const std = @import("std");

pub inline fn notControlCode(c: u8) bool {
    return switch (c) {
        0x00...0x1F => false,
        0x7F => false,
        else => true,
    };
}

test "notControlCode" {
    const assert = std.testing.expect;
    try assert(!notControlCode(0x00));
    try assert(!notControlCode(0x01));
    try assert(!notControlCode(0x1F));
    try assert(notControlCode(0x20));
    try assert(notControlCode(0x7E));
    try assert(!notControlCode(0x7F));
}

pub inline fn notPunctuationCode(c: u8) bool {
    return switch (c) {
        0x21...0x2F => false,
        0x3A...0x40 => false,
        0x5B...0x60 => false,
        0x7B...0x7E => false,
        else => true,
    };
}

pub inline fn notWhiteSpaceCode(c: u8) bool {
    return switch (c) {
        0x09 => false,
        0x0A => false,
        0x0B => false,
        0x0C => false,
        0x0D => false,
        0x20 => false,
        else => true,
    };
}

pub const Span = struct {
    const Self = @This();

    begin: usize = 0,
    len: usize = 0,

    pub inline fn default() Self {
        return Self{ .begin = 0, .len = 0 };
    }
    pub inline fn clone(self: *const Self) Self {
        return Self{ .begin = self.begin, .len = self.len };
    }
    pub inline fn new(begin: usize, len: usize) Self {
        return Self{ .begin = begin, .len = len };
    }
    pub inline fn enlarge(self: *Self, size: usize) *Self {
        self.len += size;
        return self;
    }
    pub inline fn back(self: *Self, size: usize) *Self {
        self.begin -= size;
        return self;
    }
};
