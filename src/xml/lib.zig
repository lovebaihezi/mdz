const std = @import("std");

const XMLFileHead =
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ++
    "<!DOCTYPE document SYSTEM \"CommonMark.dtd\">" ++
    "<document xmlns=\"http://commonmark.org/xml/1.0\">";

const XMLFileEnd = "";

pub const Generator = struct {
    const Self = @This();

    pub fn generate(self: *const Self, comptime writer_t: type) void {
        _ = writer_t;
        _ = self;
    }
};
