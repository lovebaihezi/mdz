const std = @import("std");

const XMLFileHead =
    \\<?xml version="1.0" encoding="UTF-8"?>
    \\<!DOCTYPE document SYSTEM "CommonMark.dtd">
    ++
    "<document xmlns=\"http://commonmark.org/xml/1.0\">";

const HTMLFileHead = "<!DOCTYPE html>";

pub const Generator = struct {
    const Self = @This();
};
