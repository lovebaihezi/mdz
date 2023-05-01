const std = @import("std");
const Allocator = std.mem.Allocator;

pub const unicode_data_url = "https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt";
// pub const unicode_data_url = "http://localhost:8080";

pub fn fetch_unicode(allocator: Allocator) !void {
    std.log.info("get unicode file from \"{s}\"\n", .{unicode_data_url});
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();
    var client_headers = std.http.Headers{ .allocator = allocator };
    defer client_headers.deinit();
    const uri = try std.Uri.parse(unicode_data_url);
    var client_req = try client.request(std.http.Method.GET, uri, client_headers, .{});
    defer client_req.deinit();
    client_req.transfer_encoding = .{ .content_length = 0 };
    try client_req.start();
    try client_req.finish();
    try client_req.wait();
    var reader = client_req.reader();
    std.log.info("http request complete\n", .{});
    var read_size: usize = 0;
    const size = 4 * 1024 * 1024;
    comptime {
        if (size < 1913704) {
            @compileError("no enough space to store unicode data");
        }
    }
    var buffer: [size]u8 = undefined;
    while (read_size < size) {
        var read = try reader.read(buffer[read_size..]);
        std.log.info("size: {d}", .{read});
        if (read == 0) {
            break;
        }
        read_size += read;
    }
    std.log.info("fetch {d} bytes from {s}\n", .{ read_size, unicode_data_url });
    var iter = std.mem.tokenize(u8, buffer[0..read_size], "\n");
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
    var file = try std.fs.cwd().openFile("asserts/punction-code.txt", std.fs.File.OpenFlags{
        .mode = std.fs.File.OpenMode.write_only,
    });
    defer file.close();
    var writer = file.writer();
    var bytes: usize = 0;
    var count: usize = 0;
    while (iter.next()) |chars| {
        i += 1;
        var texts = std.mem.split(u8, chars, ";");
        const num = texts.next() orelse unreachable;
        _ = texts.next();
        const des = texts.next() orelse unreachable;
        for (search) |str| {
            if (std.mem.eql(u8, str, des)) {
                bytes += try writer.write(num);
                try writer.writeByte(' ');
                bytes += 1;
                count += 1;
            }
        }
    }
    std.log.info("write {d} unicode, total {d} bytes to scripts/punction-code.txt", .{
        count, bytes,
    });
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try fetch_unicode(allocator);
}
