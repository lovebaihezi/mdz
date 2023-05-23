const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;

pub fn normal(state: *State, span: Span) Error!void {
    std.debug.assert(span.len != 0);
    switch (state.state) {
        .Empty => {
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeIndentedCodeBegin => {
            if (state.value == null) {
                try state.initParagraph(Span.new(span.begin + 1, span.len + 1));
            }
            state.state = .{ .MaybeIndentedCodeContent = span };
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeFencedCodeBegin => |s| {
            state.toNormalText(Span.new(span.begin - s, span.len + s));
        },
        else => {},
    }
}
