const std = @import("std");
const mdz = @import("mdz.zig");
const Parser = mdz.parser.Parser;
const Lexer = mdz.lexer.Lexer;

const linux = std.os.linux;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 1. Prepare Workload
    std.debug.print("Generating workload...\n", .{});
    const workload = try generateWorkload(allocator, 50 * 1024 * 1024); // 50MB
    std.debug.print("Workload size: {d} bytes\n", .{workload.len});

    // 2. Setup Perf Counters
    const perf_fd = setupPerfCounter() catch |err| blk: {
        std.debug.print("Warning: Failed to setup perf counter (cache misses): {s}\n", .{@errorName(err)});
        if (err == error.PermissionDenied) {
             std.debug.print("  (Try running with sudo or adjusting /proc/sys/kernel/perf_event_paranoid)\n", .{});
        }
        break :blk -1;
    };
    defer if (perf_fd != -1) std.posix.close(perf_fd);

    // 3. Reset/Read Initial Metrics
    if (perf_fd != -1) {
        // Reset and enable
        _ = linux.ioctl(perf_fd, linux.PERF.EVENT_IOC.RESET, 0);
        _ = linux.ioctl(perf_fd, linux.PERF.EVENT_IOC.ENABLE, 0);
    }

    var rusage_start: linux.rusage = undefined;
    _ = linux.getrusage(0, &rusage_start); // 0 = RUSAGE_SELF

    const start_time = std.time.nanoTimestamp();

    // 4. Run Parser
    {
        var lexer = Lexer.init(workload);
        var parser = Parser.init(allocator);

        while (parser.next(&lexer)) |opBlock| {
            if (opBlock) |_| {
                // discard block
            } else {
                break;
            }
        } else |err| {
            std.debug.print("Parser error: {s}\n", .{@errorName(err)});
        }
    }

    const end_time = std.time.nanoTimestamp();

    // 5. Read Final Metrics
    var rusage_end: linux.rusage = undefined;
    _ = linux.getrusage(0, &rusage_end); // 0 = RUSAGE_SELF

    var cache_misses: u64 = 0;
    if (perf_fd != -1) {
        _ = linux.ioctl(perf_fd, linux.PERF.EVENT_IOC.DISABLE, 0);
        const n = std.posix.read(perf_fd, std.mem.asBytes(&cache_misses)) catch 0;
        if (n != 8) cache_misses = 0;
    }

    // 6. Report
    const wall_time_ns = @as(u64, @intCast(end_time - start_time));
    const wall_time_s = @as(f64, @floatFromInt(wall_time_ns)) / 1_000_000_000.0;

    const user_time_s = timevalToSec(rusage_end.utime) - timevalToSec(rusage_start.utime);
    const sys_time_s = timevalToSec(rusage_end.stime) - timevalToSec(rusage_start.stime);

    const nvcsw = rusage_end.nvcsw - rusage_start.nvcsw;
    const nivcsw = rusage_end.nivcsw - rusage_start.nivcsw;

    const max_rss_kb = rusage_end.maxrss; // usually in KB on Linux

    const stdout_file = std.fs.File.stdout();
    const MyWriter = std.io.GenericWriter(std.fs.File, std.fs.File.WriteError, std.fs.File.write);
    const stdout = MyWriter{ .context = stdout_file };

    try stdout.print("\nBenchmark Results:\n", .{});
    try stdout.print("==================\n", .{});
    try stdout.print("Input Size:       {d:.2} MB\n", .{@as(f64, @floatFromInt(workload.len)) / 1024.0 / 1024.0});
    try stdout.print("Wall Time:        {d:.4} s\n", .{wall_time_s});
    try stdout.print("User Time:        {d:.4} s\n", .{user_time_s});
    try stdout.print("System Time:      {d:.4} s\n", .{sys_time_s});
    try stdout.print("Context Switches: {d} (Vol: {d}, Invol: {d})\n", .{nvcsw + nivcsw, nvcsw, nivcsw});
    try stdout.print("Max RSS:          {d:.2} MB\n", .{@as(f64, @floatFromInt(max_rss_kb)) / 1024.0});
    if (perf_fd != -1) {
        try stdout.print("Cache Misses:     {d}\n", .{cache_misses});
    } else {
        try stdout.print("Cache Misses:     N/A (Not supported/permitted)\n", .{});
    }
}

fn setupPerfCounter() !std.posix.fd_t {
    var attr = std.mem.zeroes(linux.perf_event_attr);
    attr.type = linux.PERF.TYPE.HARDWARE;
    attr.config = @intFromEnum(linux.PERF.COUNT.HW.CACHE_MISSES);
    attr.flags.disabled = true;
    attr.flags.exclude_kernel = false;
    attr.flags.exclude_hv = true;

    const rc = std.os.linux.perf_event_open(&attr, 0, -1, -1, 0); // 0 = self pid, -1 = any cpu
    const result: isize = @bitCast(rc);
    if (result < 0 and result > -4096) {
        const err_code: u32 = @intCast(@abs(result));
        if (err_code == @intFromEnum(std.os.linux.E.ACCES)) return error.PermissionDenied;
        return error.Unexpected;
    }
    return @intCast(rc);
}

fn timevalToSec(tv: linux.timeval) f64 {
    return @as(f64, @floatFromInt(tv.sec)) + @as(f64, @floatFromInt(tv.usec)) / 1_000_000.0;
}

fn generateWorkload(allocator: std.mem.Allocator, target_size: usize) ![]u8 {
    var list = std.ArrayList(u8){};
    // Don't defer deinit because we return the slice

    const chunk =
        \\# Benchmark Title
        \\
        \\This is a paragraph with some plain text.
        \\It also has some `code` inside.
        \\
        \\Another paragraph to ensure we have enough content.
        \\Repeated content is fine for benchmarking parser throughput.
        \\
        \\
    ;

    while (list.items.len < target_size) {
        try list.appendSlice(allocator, chunk);
    }

    return list.toOwnedSlice(allocator);
}
