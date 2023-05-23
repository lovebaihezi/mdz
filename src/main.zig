const std = @import("std");
const utils = @import("mdz.zig").utils;

const Parser = @import("mdz.zig").parser.Parser;
const Block = @import("mdz.zig").mir.Block;
const Args = @import("args.zig").Args;

const File = std.fs.File;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = Args.try_parse(allocator) catch |e| {
        @panic(@errorName(e));
    };

    for (args.files.items()) |item| {
        const stdout_file = std.io.getStdOut().writer();

        //TODO: Consider use bound array to optmize read process
        const buffer: []const u8 = readBuffer: {
            const path = item;
            const flag = File.OpenFlags{};
            const file = std.fs.cwd().openFile(path, flag) catch |e| {
                @panic(@errorName(e));
            };
            defer file.close();
            const metadata = file.metadata() catch |e| {
                @panic(@errorName(e));
            };
            const size = metadata.size();
            if (size > std.math.maxInt(usize)) {
                @panic("no enough memory");
            }
            break :readBuffer file.readToEndAlloc(allocator, @as(usize, size)) catch |e| {
                @panic(@errorName(e));
            };
        };

        var parser = Parser.init(buffer);
        var i: usize = 0;
        std.debug.print("----------------------------\n", .{});
        while (parser.next(allocator)) |opBlock| {
            i += 1;
            if (opBlock) |block| {
                try block.writeAST(buffer, stdout_file);
                std.debug.print("----------------------------\n", .{});
            } else {
                break;
            }
        } else |e| {
            std.log.err("parser encounter error: {s}", .{@errorName(e)});
        }
    }
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("mdz.zig");
}
