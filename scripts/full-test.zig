const std = @import("std");

const Type = enum { Normal, Full };
const File = std.fs.File;

fn load_cache(map: *std.StringArrayHashMap(bool), allocator: std.mem.Allocator, path: []const u8) !File {
    const file_err = std.fs.cwd().openFile(path, .{});
    if (file_err) |file| {
        const buf = try File.readToEndAlloc(file, allocator, 8192 * 4);
        var iter = std.mem.splitAny(u8, buf, "\n");
        while (iter.next()) |line| {
            var files = std.mem.splitAny(u8, line, " ");
            while (files.next()) |p| {
                try map.put(p, true);
            }
        }
        return file;
    } else |_| {
        const file = try std.fs.cwd().createFile(path, .{});
        return file;
    }
}

fn begin_test(map: std.StringArrayHashMap(bool), allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = map;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next();
    var cmd = Type.Normal;
    if (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "full") or std.mem.eql(u8, arg, "f")) {
            cmd = Type.Full;
        }
    }
    const cwd = std.fs.cwd();
    var map = std.StringArrayHashMap(bool).init(allocator);
    if (cmd == Type.Normal) {
        const file = try load_cache(&map, allocator, "tests/.test_cache");
        _ = file;
    }
    const dir = try cwd.openDir("tests/asserts", .{});
    _ = dir;
}
