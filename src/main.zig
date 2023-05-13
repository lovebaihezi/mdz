const std = @import("std");
const utils = @import("utils.zig");
const File = std.fs.File;
const parse = @import("parser.zig");
const Parser = parse.Parser;
const Block = @import("mir.zig").Block;

const Allocator = std.mem.Allocator;

const ArgsError = error{
    MissingFilePath,
};

const Args = struct {
    const Self = Args;
    input: []const u8,
    pub fn try_parse(allocator: Allocator) ArgsError!Self {
        var args = try std.process.argsWithAllocator(allocator);
        _ = args.next();
        const file_path = args.next() orelse return ArgsError.MissingFilePath;
        return Args{
            .input = file_path,
        };
    }
};

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = Args.try_parse(allocator) catch |e| {
        @panic(@errorName(e));
    };

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    _ = stdout;

    //TODO: Consider use bound array to optmize read process
    const buffer: []const u8 = readBuffer: {
        const file_path = args.input;
        const flag = File.OpenFlags{};
        const file = std.fs.cwd().openFile(file_path, flag) catch |e| {
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
    while (parser.next(allocator)) |opBlock| {
        i += 1;
        if (opBlock) |block| {
            std.debug.print("the number {d} of blocks: ", .{i});
            switch (block) {
                .Title => |title| {
                    std.debug.print("type: Title    ", .{});
                    std.debug.print("title level: {d}  ", .{title.level});
                    for (title.content.items) |item| {
                        switch (item) {
                            .Text => |text| {
                                switch (text) {
                                    .Plain => |span| {
                                        std.debug.print("title content: \"{s}\"  ", .{buffer[span.begin .. span.begin + span.len]});
                                    },
                                    else => @panic("todo"),
                                }
                            },
                            else => @panic("todo"),
                        }
                    }
                    std.debug.print("\n", .{});
                },
                .Paragraph => |paragraph| {
                    std.debug.print("type: Paragraph   ", .{});
                    for (paragraph.content.items, 0..) |item, n| {
                        switch (item) {
                            .Text => |text| {
                                switch (text) {
                                    .Plain => |span| {
                                        std.debug.print("{d}: \"{s}\"   ", .{ n, buffer[span.begin .. span.begin + span.len] });
                                    },
                                    else => @panic("todo"),
                                }
                            },
                            else => @panic("todo"),
                        }
                    }
                    std.debug.print("\n", .{});
                },
                else => @panic("todo"),
            }
        } else {
            break;
        }
    } else |e| {
        @panic(@errorName(e));
    }
}

test {
    std.testing.refAllDecls(@This());
    std.debug.print("\n", .{});
    _ = @import("dfa.zig");
    _ = @import("lexer.zig");
    _ = @import("utils.zig");
    _ = @import("mir.zig");
    _ = @import("parser.zig");
}
