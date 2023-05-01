const std = @import("std");
const dfa = @import("dfa.zig");

const Allocator = std.mem.Allocator;

const ParseError = dfa.ParseError;

pub inline fn notControlCode(c: u8) bool {
    return switch (c) {
        0x00...0x1F, 0x7F => false,
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
        inline 0x21...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E => false,
        else => true,
    };
}

pub inline fn notWhiteSpaceCode(c: u8) bool {
    return switch (c) {
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20 => false,
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
    pub inline fn extend(self: *Self, other: *const Self) *Self {
        self.len += other.len;
        self.begin = other.begin;
        return self;
    }
};

pub fn allocErrorToParseError(e: Allocator.Error) ParseError {
    return switch (e) {
        Allocator.Error.OutOfMemory => ParseError.OutOfMemory,
    };
}

pub fn getStackSize() noreturn {
    @panic("todo");
}
