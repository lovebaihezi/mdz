const std = @import("std");
const utils = @import("mdz.zig").utils;

const Parser = @import("mdz.zig").parser.Parser;
const Block = @import("mdz.zig").mir.Block;

const File = std.fs.File;
const Allocator = std.mem.Allocator;

const ArgsError = error{
    MissingFilePath,
};

const Format = enum {
    AST,
    XML,
    JSON,
    LaTex,
};

comptime {
    std.debug.assert(@sizeOf(Format) >= 1);
}

const Args = struct {
    const Self = @This();

    file: []const u8 = undefined,
    format: Format = Format.AST,

    pub fn try_parse(allocator: Allocator) ArgsError!Self {
        var args = try std.process.argsWithAllocator(allocator);
        _ = args.next();
        var self = Self{};
        while (args.next()) |arg| {
            if (std.mem.startsWith(u8, arg, "-")) {
                const str = arg[1..];
                if (std.mem.eql(u8, "ast", str) or std.mem.eql(u8, "Ast", str) or std.mem.eql(u8, "AST", str)) {
                    self.format = Format.AST;
                    continue;
                } else if (std.mem.eql(u8, "xml", str) or std.mem.eql(u8, "Xml", str) or std.mem.eql(u8, "XML", str)) {
                    self.format = Format.XML;
                    continue;
                } else if (std.mem.eql(u8, "json", str) or std.mem.eql(u8, "Json", str) or std.mem.eql(u8, "JSON", str)) {
                    self.format = Format.JSON;
                    continue;
                } else if (std.mem.eql(u8, "latex", str) or std.mem.eql(u8, "Latex", str) or std.mem.eql(u8, "LaTex", str) or std.mem.eql(u8, "LaTeX", str)) {
                    self.format = Format.LaTex;
                    continue;
                } else {
                    @panic("unknown format");
                }
            } else {
                self.file = arg;
            }
        }
        return self;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = Args.try_parse(allocator) catch |e| {
        @panic(@errorName(e));
    };

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    //TODO: Consider use bound array to optmize read process
    const buffer: []const u8 = readBuffer: {
        const file_path = args.file;
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
        try bw.flush();
        i += 1;
        if (opBlock) |block| {
            try block.writeAST(stdout);
        } else {
            break;
        }
    } else |e| {
        @panic(@errorName(e));
    }
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("mdz.zig");
}
