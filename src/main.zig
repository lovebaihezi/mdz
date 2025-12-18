const std = @import("std");
const utils = @import("mdz.zig").utils;

const Parser = @import("mdz.zig").parser.Parser;
const Lexer = @import("mdz.zig").lexer.Lexer;
const Block = @import("mdz.zig").mir.Block;
const Args = @import("args.zig").Args;

const File = std.fs.File;
const Allocator = std.mem.Allocator;

const App = struct {
    const Self = @This();

    allocator: Allocator,
    format: Args.Format,

    pub fn open_or_create(self: Self, path: []const u8) ?File {
        const begin = std.mem.lastIndexOf(u8, path, "/") orelse 0;
        const end = std.mem.lastIndexOf(u8, path, ".") orelse path.len;
        const name = path[begin + 1 .. end];
        var buf: [512]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        const allocator = fba.allocator();
        const real_path = std.mem.join(allocator, ".", &[2][]const u8{
            name,
            switch (self.format) {
                .AST => "ast",
                .XML => "xml",
                .HTML => "html",
                .LaTex => "tex",
            },
        }) catch unreachable;
        std.log.info("will write to file: {s}", .{real_path});
        const file_err = std.fs.cwd().openFile(real_path, .{
            .mode = .write_only,
        });
        if (file_err) |file| {
            return file;
        } else |open_err| {
            if (open_err == File.OpenError.FileNotFound) {
                const file_e = std.fs.cwd().createFile(real_path, .{});
                if (file_e) |file| {
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

    pub const page_size = 4096 * 1024;

    pub fn pipe(self: Self, input_file: File, output_file: File) !void {
        var out_buf: [4096]u8 = undefined;
        var f_writer = output_file.writer(&out_buf);
        const writer = &f_writer.interface;

        var parser = Parser.init(self.allocator);
        var buffer: [page_size]u8 = undefined;
        var lexer = Lexer.init(&buffer);
        while (true) {
            if (input_file.readAll(&buffer)) |size| {
                if (size == 0) {
                    break;
                }
                while (parser.next(&lexer)) |opBlock| {
                    if (opBlock) |block| {
                        switch (self.format) {
                            .AST => {
                                try block.writeAST(buffer[0..size], writer);
                            },
                            .XML => {
                                try block.writeXML(buffer[0..size], writer);
                            },
                            .HTML => {
                                try block.writeHTML(buffer[0..size], writer);
                            },
                            else => @panic("todo"),
                        }
                    } else {
                        break;
                    }
                } else |e| {
                    std.log.err("parser encounter error: {s}", .{@errorName(e)});
                }
            } else |_| {
                break;
            }
        }
        try writer.flush();
    }
};

const version = @import("version.zig").version;

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = Args.try_parse(allocator) catch |e| {
        const cause = @errorName(e);
        std.log.err("failed to parse from args, cause: {s}", .{cause});
        std.process.exit(255);
    };

    if (args.show_help) {
        return;
    } else if (args.show_version) {
        _ = std.fs.File.stdout().write(version) catch unreachable;
        return;
    }

    const app = App{ .allocator = allocator, .format = args.format };

    if (args.files.len() == 0) {
        app.pipe(std.fs.File.stdin(), std.fs.File.stdout()) catch |e| {
            std.log.err("mdz parse failed, cause: {s}", .{@errorName(e)});
        };
    } else {
        for (args.files.items()) |item| {
            const file_err = std.fs.cwd().openFile(item, .{});
            if (file_err) |file| {
                defer file.close();
                var output = false;
                const output_file: File = if (args.write_to_file)
                    app.open_or_create(item) orelse {
                        continue;
                    }
                else file: {
                    output = true;
                    break :file std.fs.File.stdout();
                };
                defer {
                    if (!output) {
                        output_file.close();
                    }
                }
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
