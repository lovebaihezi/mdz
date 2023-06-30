const std = @import("std");
const Allocator = std.mem.Allocator;

const File = std.fs.File;
const OpenFlags = File.OpenFlags;
const OpenMode = File.OpenMode;

pub const unicode_path = "asserts/unicode.txt";

const buffer_size = 4 * 1024 * 1024;

const text = "///# Punction Codes\n" ++
    "\n" ++ "///generate from unicode.txt\n" ++ "\n" ++
    "///this file it's auto generated, do not modified it directily\n";

fn generate() !void {
    const buffer = @embedFile(unicode_path);
    var iter = std.mem.tokenize(u8, buffer, "\n");
    var i: usize = 0;
    const search = [_][]const u8{
        "Pc", // Punctuation, Connector
        "Pd", // Punctuation, Dash
        "Pe", // Punctuation, Close
        "Pf", // Punctuation, FinalQuote
        "Pi", // Punctuation, InitialQuote
        "Po", // Punctuation, Other
        "Ps", // Punctuation, Open
    };
    const path = "src/unicode.zig";
    var file = try std.fs.cwd().openFile(path, OpenFlags{
        .mode = std.fs.File.OpenMode.write_only,
    });
    defer file.close();
    var writer = std.io.bufferedWriter(file.writer());
    var bytes: usize = 0;
    var count: usize = 0;
    bytes += try writer.write(text);
    bytes += try writer.write("pub const PunctionCodes: [len]u21 = .{\n");
    while (iter.next()) |chars| {
        i += 1;
        var texts = std.mem.split(u8, chars, ";");
        const num = texts.next() orelse unreachable;
        _ = texts.next();
        const des = texts.next() orelse unreachable;
        for (search) |str| {
            if (std.mem.eql(u8, str, des)) {
                bytes += try writer.write("    '\\u{");
                bytes += try writer.write(num);
                bytes += try writer.write("}', \n");
                count += 1;
            }
        }
    }
    bytes += try writer.write("};\n");
    var buf = try std.BoundedArray(u8, 32).init(0);
    try std.fmt.format(buf.writer(), "pub const len = {d};\n", .{count});
    bytes += try writer.write(buf.buffer[0..buf.len]);
    try writer.flush();
    std.log.info("write {d} unicode, total {d} bytes to " ++ path, .{
        count, bytes,
    });
}

pub fn main() anyerror!void {
    try generate();
}
