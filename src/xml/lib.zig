const std = @import("std");

const XMLFileHead =
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ++
    "<!DOCTYPE document SYSTEM \"CommonMark.dtd\">" ++
    "<document xmlns=\"http://commonmark.org/xml/1.0\">";

const XMLFileEnd = "";

pub const Generator = struct {
    const Self = @This();

    pub fn write(self: Self, writer: anytype) void {
        _ = writer;
        _ = self;
    }
};

pub fn write_to(s: anytype, stream: anytype) !void {
    var bw = std.io.bufferedWriter(stream);
    const writer = bw.writer();
    _ = writer;
    const info = @typeInfo(@TypeOf(s));
    _ = info;
}
