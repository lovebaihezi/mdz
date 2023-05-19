const std = @import("std");
const code =
    \\const std = @import("std");
    \\const State = @import("../state/state.zig").State;
    \\const Span = @import("../../utils/lib.zig").Span;
    \\const Error = @import("../lib.zig").ParseError;
    \\
++ "pub fn ";
const end =
    "(state: *State, span: Span) Error!void {" ++
    \\
    \\}
;
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    const cwd = std.fs.cwd();
    _ = args.next();
    while (args.next()) |arg| {
        const slice: [2][]const u8 = .{ arg, "zig" };
        const path = try std.mem.join(allocator, ".", &slice);
        defer allocator.free(path);
        var file = try cwd.createFile(path, .{});
        defer file.close();
        _ = try file.writeAll(code);
        _ = try file.writeAll(arg);
        _ = try file.writeAll(end);
        std.log.info("write bytes into: {s}", .{path});
    }
}
