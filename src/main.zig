const std = @import("std");
const utils = @import("utils.zig");
const File = std.fs.File;
const parse = @import("parser.zig");
const Parser = parse.Parser;

// pub fn main() !void { // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`) std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

//     // stdout is for the actual output of your application, for example if you
//     // are implementing gzip, then only the compressed bytes should be sent to
//     // stdout, not any debugging messages.
//     const stdout_file = std.io.getStdOut().writer();
//     var bw = std.io.bufferedWriter(stdout_file);
//     const stdout = bw.writer();

//     try stdout.print("Run `zig build test` to run the tests.\n", .{});

//     try bw.flush(); // don't forget to flush!
// }

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

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
    const block = parser.next() catch |e| {
        @panic(@errorName(e));
    };
    _ = block;
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("lexer.zig");
}
