const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
const Decorations = @import("../../mir/lib.zig").Decorations;

pub fn code(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            if (state.value) |v| {
                switch (v) {
                    .Code => |*c| {
                        _ = c;
                    },
                    else => {},
                }
            } else {
                state.state = .{
                    .MaybeIndentedCodeBegin = {},
                };
            }
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{
                .Empty = {},
            };
            const s = Span.new(span.begin - 1, 2);
            if (state.value == null) {
                try state.initParagraph(s);
                try state.value.?.Paragraph.addNewLine(state.allocator, s);
            }
            var arr = try Decorations.init(state.allocator, 0);
            try arr.append(state.allocator, .Code);
            try state.value.?.Paragraph.lines.last_mut().?.contents.append(state.allocator, .{
                .Text = .{ .decorations = arr, .span = s },
            });
        },
        else => {},
    }
}
