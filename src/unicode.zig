const std = @import("std");

const len: usize = len: {
    const str = @embedFile("../scripts/punction-code.txt");
    const nums = std.mem.tokenize([]const u8, str, " ");
    break :len nums.len;
};

pub const PunctionCodes: [len]u21 = datas: {
    var arr: [len]u21 = undefined;
    const str = @embedFile("../scripts/punction-code.txt");
    var nums = std.mem.tokenize([]const u8, str, " ");
    for (nums, 0..) |slice, i| {
        var num = std.fmt.parseUnsigned(u21, slice) orelse unreachable;
        arr[i] = num;
    }
    break :datas arr;
};
