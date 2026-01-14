const std = @import("std");
const utils = @import("utils/lib.zig");
const Span = utils.Span;

pub const Diagnose = struct {
    const Self = @This();

    line: usize,
    col: usize,
    line_content: []const u8,
    line_start_index: usize,
    error_index: usize,

    pub fn init(buffer: []const u8, span: Span) Self {
        var line: usize = 1;
        var line_start: usize = 0;

        for (buffer[0..span.begin], 0..) |c, i| {
            if (c == '\n') {
                line += 1;
                line_start = i + 1;
            }
        }

        // Calculate col (codepoint offset + 1)
        // We use a safe slice; if span.begin < line_start (should not happen), use empty
        const prefix = if (span.begin >= line_start) buffer[line_start..span.begin] else "";
        const col = (std.unicode.utf8CountCodepoints(prefix) catch 0) + 1;

        // Find end of line
        var line_end = line_start;
        while (line_end < buffer.len and buffer[line_end] != '\n') {
            line_end += 1;
        }

        // Trim \r
        var content_end = line_end;
        if (content_end > line_start and buffer[content_end - 1] == '\r') {
            content_end -= 1;
        }

        return Self{
            .line = line,
            .col = col,
            .line_content = buffer[line_start..content_end],
            .line_start_index = line_start,
            .error_index = span.begin,
        };
    }

    pub fn report(self: Self) void {
        std.log.err("Error at line {d}, col {d}:", .{ self.line, self.col });
        std.log.err("{s}", .{self.line_content});

        // Print pointer
        var buf: [4096]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();

        // Calculate offset in line_content
        if (self.error_index >= self.line_start_index) {
            var offset = self.error_index - self.line_start_index;
            if (offset > self.line_content.len) {
                offset = self.line_content.len;
            }

            const prefix = self.line_content[0..offset];
            // Iterate codepoints to match spacing
            if (std.unicode.Utf8View.init(prefix)) |utf8| {
                var iter = utf8.iterator();
                while (iter.nextCodepoint()) |c| {
                    if (c == '\t') {
                        writer.writeByte('\t') catch break;
                    } else {
                        // Assume width 1 for now
                        writer.writeByte(' ') catch break;
                    }
                }
            } else |_| {
                // Fallback for invalid utf8: print spaces for bytes? or just spaces
                 writer.writeByteNTimes(' ', prefix.len) catch {};
            }
            writer.writeByte('^') catch {};

            std.log.err("{s}", .{fbs.getWritten()});
        }
    }
};

test "Diagnose calculation and report" {
    const buffer =
        \\line 1
        \\line 2 is here
        \\line 3
    ;
    // 'i' in "is" is at index: 7 + 7 = 14.
    const span = Span{ .begin = 14, .len = 2 };
    const d = Diagnose.init(buffer, span);

    try std.testing.expectEqual(@as(usize, 2), d.line);
    try std.testing.expectEqual(@as(usize, 8), d.col);
    try std.testing.expectEqualStrings("line 2 is here", d.line_content);

    // We can't assert std.log output easily, but we can verify it doesn't crash
    d.report();
}
