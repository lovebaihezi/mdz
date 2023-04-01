const std = @import("std");

pub fn notControlCode(c: u8) bool {
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

pub fn notPunctuationCode(c: u8) bool {
    return switch (c) {
        0x21...0x2F => false,
        0x3A...0x40 => false,
        0x5B...0x60 => false,
        0x7B...0x7E => false,
        else => true,
    };
}

pub fn notWhiteSpaceCode(c: u8) bool {
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
