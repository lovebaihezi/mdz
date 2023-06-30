const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn urlBegin(state: *State, span: Span) Error!void {
    switch (state.state) {
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(span.len);
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{ .MaybeIndentedCodeContent = span };
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(span.len);
        },
        else => @panic(@tagName(state.state)),
    }
}
