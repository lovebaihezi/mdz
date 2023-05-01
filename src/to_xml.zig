const std = @import("std");

const XMLFileHead =
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ++
    "<!DOCTYPE document SYSTEM \"CommonMark.dtd\">" ++
    "<document xmlns=\"http://commonmark.org/xml/1.0\">";

pub const Generator = struct {
    const Self = @This();

    pub fn toXML(self: *const Self, buffer: []u8) void {
        _ = buffer;
        _ = self;
    }

    pub fn streamToXML(self: *const Self) void {
        _ = self;
    }
};
