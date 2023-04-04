const std = @import("std");

pub const MirTag = enum {};

pub const Mir = union(MirTag) {};
