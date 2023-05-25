const std = @import("std");
const utils = @import("mdz.zig").utils;

const Parser = @import("mdz.zig").parser.Parser;
const Block = @import("mdz.zig").mir.Block;
const Args = @import("args.zig").Args;

const File = std.fs.File;
const Allocator = std.mem.Allocator;

fn open_or_create(path: []const u8) ?File {
    const begin = std.mem.lastIndexOf(u8, path, "/") orelse 0;
    const end = std.mem.lastIndexOf(u8, path, ".") orelse path.len;
    const real_path = path[begin + 1 .. end];
    const file_err = std.fs.cwd().openFile(real_path, .{
        .mode = .write_only,
    });
    if (file_err) |file| {
        std.debug.print("write to opened file: {s}\n", .{real_path});
        return file;
    } else |open_err| {
        if (open_err == File.OpenError.FileNotFound) {
            const file_e = std.fs.cwd().createFile(path, .{});
            if (file_e) |file| {
                std.debug.print("write to created file: {s}\n", .{real_path});
                return file;
            } else |create_err| {
                std.log.err("failed to create file: cause: {s}", .{@errorName(create_err)});
            }
        } else {
            std.log.err("failed to open file: cause: {s}", .{@errorName(open_err)});
        }
    }
    return null;
}

const App = struct {
    const Self = @This();

    allocator: Allocator,
    format: Args.Format,

    pub fn pipe(self: Self, input_file: File, output_file: File) !void {
        var writer = output_file.writer();

        const buffer: []const u8 = readBuffer: {
            const metadata = input_file.metadata() catch |e| {
                @panic(@errorName(e));
            };
            const size = metadata.size();
            if (size > 8192 * 4) {
                @panic("no enough memory");
            }
            break :readBuffer input_file.readToEndAlloc(self.allocator, @as(usize, size)) catch |e| {
                @panic(@errorName(e));
            };
        };

        var parser = Parser.init(buffer);
        while (parser.next(self.allocator)) |opBlock| {
            if (opBlock) |block| {
                switch (self.format) {
                    .AST => {
                        try block.writeAST(buffer, writer);
                    },
                    .XML => {
                        try block.writeXML(buffer, writer);
                    },
                    .HTML => {
                        try block.writeHTML(buffer, writer);
                    },
                    else => @panic("todo"),
                }
            } else {
                break;
            }
        } else |e| {
            std.log.err("parser encounter error: {s}", .{@errorName(e)});
        }
    }
};
pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = Args.try_parse(allocator) catch |e| {
        const cause = @errorName(e);
        std.log.err("failed to parse from args, cause: {s}", .{cause});
        std.process.exit(255);
    };

    const app = App{ .allocator = allocator, .format = args.format };

    if (args.files.len() == 0) {
        app.pipe(std.io.getStdIn(), std.io.getStdOut()) catch |e| {
            std.log.err("mdz parse failed, cause: {s}", .{@errorName(e)});
        };
    } else {
        for (args.files.items()) |item| {
            const file_err = std.fs.cwd().openFile(item, .{});
            if (file_err) |file| {
                defer file.close();
                const output_file: File = if (args.write_to_file)
                    open_or_create(item) orelse {
                        continue;
                    }
                else
                    std.io.getStdOut();
                defer output_file.close();
                app.pipe(file, output_file) catch |e| {
                    std.log.err("mdz parse failed, cause: {s}", .{@errorName(e)});
                };
            } else |e| {
                std.log.err("failed to open file: \"{s}\", cause: {s}", .{ item, @errorName(e) });
            }
        }
    }
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("mdz.zig");
}
