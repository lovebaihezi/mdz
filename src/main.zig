const std = @import("std");
const utils = @import("utils.zig");
const File = std.fs.File;

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
        const args = try std.process.argsWithAllocator(allocator);
        args.next();
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
    const file_path = Args.try_parse(allocator) catch |e| {
        std.log.err("error: {s}\n", .{e});
        std.os.exit(-1);
    };
    const file = std.fs.cwd().openFile(file_path, File.OpenFlags.isRead()) catch |e| {
        std.log.err("error: {s}\n", .{e});
        std.os.exit(-1);
    };
    defer file.close();
}
