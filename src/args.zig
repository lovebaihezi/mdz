const std = @import("std");

const small_arr = @import("./small_arr.zig");

const Allocator = std.mem.Allocator;

const SmallArray = small_arr.SmallArray;

pub const Args = struct {
    const Self = @This();
    pub const ArgsError = error{ MissingFilePath, UnknownOutputFormat, OptionNoType, UnknownOption } || small_arr.Error;

    pub const Format = enum {
        AST,
        XML,
        HTML,
        LaTex,
    };

    comptime {
        std.debug.assert(@sizeOf(Format) >= 1);
    }

    files: SmallArray([]const u8, 1) = undefined,
    format: Format = Format.AST,
    write_to_file: bool = false,
    args: std.process.ArgIterator = undefined,

    pub fn set_option(self: *Self, arg: []const u8) ArgsError!void {
        const s = arg[1..];
        var tokens = std.mem.tokenize(u8, s, "=");
        const ty = tokens.next() orelse return error.OptionNoType;
        if (std.mem.eql(u8, "format", ty) or std.mem.eql(u8, "f", ty) or std.mem.eql(u8, "fmt", ty)) {
            const value = tokens.next();
            if (value) |str| {
                if (std.mem.eql(u8, "ast", str) or std.mem.eql(u8, "Ast", str) or std.mem.eql(u8, "AST", str)) {
                    self.format = Format.AST;
                } else if (std.mem.eql(u8, "xml", str) or std.mem.eql(u8, "Xml", str) or std.mem.eql(u8, "XML", str)) {
                    self.format = Format.XML;
                } else if (std.mem.eql(u8, "html", str) or std.mem.eql(u8, "Html", str) or std.mem.eql(u8, "HTML", str)) {
                    self.format = Format.HTML;
                } else if (std.mem.eql(u8, "latex", str) or std.mem.eql(u8, "Latex", str) or std.mem.eql(u8, "LaTex", str) or std.mem.eql(u8, "LaTeX", str)) {
                    self.format = Format.LaTex;
                } else {
                    return error.UnknownOutputFormat;
                }
            }
        } else if (std.mem.eql(u8, "o", ty) or std.mem.eql(u8, "output", ty)) {
            self.write_to_file = true;
        } else {
            return error.UnknownOption;
        }
    }

    pub fn try_parse(allocator: Allocator) ArgsError!Self {
        var args = try std.process.argsWithAllocator(allocator);
        _ = args.next();
        var self = Self{
            .args = args,
            .files = try SmallArray([]const u8, 1).init(allocator, 0),
        };
        while (args.next()) |arg| {
            if (std.mem.startsWith(u8, arg, "-")) {
                try self.set_option(arg);
            } else if (std.mem.startsWith(u8, arg, "--")) {
                const s = arg[2..];
                if (std.mem.eql(u8, s, "help")) {}
            } else {
                try self.files.append(allocator, arg);
            }
        }
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.files.deinit();
        self.args.deinit();
    }
};

test "test set_option" {
    const Format = Args.Format;
    var args = Args{};
    try args.set_option("-format=ast");
    try std.testing.expect(args.format == Format.AST);
    try args.set_option("-format=xml");
    try std.testing.expect(args.format == Format.XML);
    try args.set_option("-format=html");
    try std.testing.expect(args.format == Format.HTML);
    try args.set_option("-format=latex");
    try std.testing.expect(args.format == Format.LaTex);
    try args.set_option("-f=ast");
    try std.testing.expect(args.format == Format.AST);
    try args.set_option("-f=xml");
    try std.testing.expect(args.format == Format.XML);
    try args.set_option("-f=html");
    try std.testing.expect(args.format == Format.HTML);
    try args.set_option("-f=latex");
    try std.testing.expect(args.format == Format.LaTex);
    try args.set_option("-fmt=ast");
    try std.testing.expect(args.format == Format.AST);
    try args.set_option("-fmt=xml");
    try std.testing.expect(args.format == Format.XML);
    try args.set_option("-fmt=html");
    try std.testing.expect(args.format == Format.HTML);
    try args.set_option("-fmt=latex");
    try std.testing.expect(args.format == Format.LaTex);
}
